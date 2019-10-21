//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationManager.swift
//  CoatySwift
//
//

import CocoaMQTT
import Foundation
import RxSwift

/// Manages a set of predefined communication events and event patterns to query, distribute, and
/// share Coaty objects across decantralized application components using the publish-subscribe API
/// of a `CommunicationClient`.
/// - Note: Because overriding declarations in extensions is not supported yet, we have to have all
/// observe and publish methods inside this class.
public class CommunicationManager<Family: ObjectFamily> {
    // MARK: - Logger.

    internal let log = LogManager.log

    // MARK: - Variables.

    /// Dispose bag for all RxSwift subscriptions.
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    internal var associatedUser: User?
    internal var associatedDevice: Device?
    private var isDisposed = false
    private var runtime: Runtime
    private var communicationOptions: CommunicationOptions
    private var subscriptions = [String: Int]()

    /// Coaty identity object of the communication manager. Initialized through initializeIdentity().
    var identity: Component!

    /// The operating state of the communication manager.
    var operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)

    /// Convenience getter for the communication state of the underlying communication client.
    var communicationState: BehaviorSubject<CommunicationState> {
        return client.communicationState
    }

    /// Holds deferred subscriptions while the communication manager is offline.
    private var deferredSubscriptions = Set<String>()

    /// Holds deferred publications (topic, payload) while the communication manager is offline.
    private var deferredPublications = [(String, String)]()

    /// Ids of all advertised components that should be deadvertised when the client ends.
    internal var deadvertiseIds = [CoatyUUID]()

    /// A dispatchqueue that handles synchronisation issues when accessing
    /// deferred publications and subscriptions.
    private var queue = DispatchQueue(label: "com.coatyswift.comQueue")

    /// The communication client that offers the required publisher-subscriber API.
    internal var client: CommunicationClient!

    // MARK: - Initializers.

    public init(runtime: Runtime, communicationOptions: CommunicationOptions) {
        self.runtime = runtime
        self.communicationOptions = communicationOptions
        initOptions()

        initializeIdentity()

        let mqttClientOptions = communicationOptions.mqttClientOptions!
        initializeMQTTClientId(mqttClientOptions)

        client = CocoaMQTTClient(mqttClientOptions: mqttClientOptions)
        client.delegate = self

        setupOperatingStateLogging()
        setupCommunicationStateLogging()
        setupOnConnectHandler()
    }

    // MARK: - Setup methods.

    public func initializeIdentity() {
        identity = Component(name: "CommunicationManager")

        // Merge property values from CommunicationOptions.identity option.
        if self.communicationOptions.identity != nil {
            for (key, value) in self.communicationOptions.identity! {
                switch key {
                    case "name":
                        identity.name = value as! String
                    case "objectId":
                        identity.objectId = value as! CoatyUUID
                    case "objectType":
                        identity.objectType = value as! String
                    case "externalId":
                        identity.externalId = value as? String
                    case "parentObjectId":
                        identity.parentObjectId = value as? CoatyUUID
                    case "assigneeUserId":
                        identity.assigneeUserId = value as? CoatyUUID
                    case "locationId":
                        identity.locationId = value as? CoatyUUID
                    case "isDeactivated":
                        identity.isDeactivated = value as? Bool
                    default:
                        break
                }
            }
        }

        // Make sure the identity is added to the deadvertiseIds array in order to
        // send out a correct last will message.
        deadvertiseIds.append(identity.objectId)
    }

    private func initializeMQTTClientId(_ mqttClientOptions: MQTTClientOptions) {
        // Assign a valid client id according to MQTT Spec 3.1:
        // The Server MUST allow ClientIds which are between 1 and 23 UTF-8 encoded 
        // bytes in length, and that contain only the characters
        // "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".
        // The Server MAY allow ClientId’s that contain more than 23 encoded bytes.
        // The Server MAY allow ClientId’s that contain characters not included in the list given above. 
        let id = identity.objectId.string;
        if communicationOptions.useProtocolCompliantClientId == false {
            mqttClientOptions.clientId = "COATY\(id)"
            return
        }
        mqttClientOptions.clientId = "COATY" + String(id.replacingOccurrences(of: "-", with: "").prefix(19))
    }


    /// Setup for the handler method that is invoked when the communication state of the client changes to online.
    private func setupOnConnectHandler() {
        client.communicationState
            .filter { $0 == .online }
            .subscribe { _ in

                try? self.advertiseIdentityOrDevice()

                // Publish possible deferred subscriptions and publications.
                _ = self.queue.sync {
                    self.deferredSubscriptions.forEach { topic in
                        self.client.subscribe(topic)
                    }

                    self.deferredPublications.forEach { publication in
                        let topic = publication.0
                        let payload = publication.1
                        self.client.publish(topic, message: payload)
                    }

                    self.deferredPublications = []
                }

            }.disposed(by: disposeBag)
    }

    private func setupOperatingStateLogging() {
        operatingState.subscribe(onNext: { state in
            self.log.debug("Operating State: \(String(describing: state))")
        }).disposed(by: disposeBag)
    }

    private func setupCommunicationStateLogging() {
        client.communicationState.subscribe(onNext: { state in
            self.log.debug("Comm. State: \(String(describing: state))")
        }).disposed(by: disposeBag)
    }

    /// Sets last will for the communication manager in broker.
    /// - NOTE: the willMessage is only sent out at the beginning of the
    ///   connection and cannot be changed afterwards, unless you reconnect.
    func setLastWill() {
        guard let lastWillTopic = try? CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Deadvertise,
                                                                                 associatedUserId: associatedUser?.objectId.string,
                                                                                 sourceObject: identity,
                                                                                 messageToken: CoatyUUID().string) else {
            log.error("Could not create topic string for last will.")
            return
        }

        guard let deadvertiseEvent = try? DeadvertiseEvent<Family>.withObjectIds(eventSource: identity,
                                                                         objectIds: deadvertiseIds) else {
            log.error("Could not create DeadvertiseEvent.")
            return
        }

        client.setWill(lastWillTopic, message: deadvertiseEvent.json)
    }

    private func initOptions() {
        self.associatedUser = self.runtime.commonOptions?.associatedUser;
        self.associatedDevice = self.runtime.commonOptions?.associatedDevice;
    }

    // MARK: - Client lifecycle methods.

    public func start() {
        // Capture state of associated user and device in case it might change
        // while the communication manager is being started.
        initOptions()
        startClient()
    }

    /// Starts the client gracefully and connects to the broker.
    public func startClient() {
        updateOperatingState(.starting)

        // Listen to discover events.
        observeDiscoverDevice()
        observeDiscoverIdentity()

        setLastWill();
        client.connect()
        updateOperatingState(.started)
    }

    /// Unsubscribe and disconnect from the messaging broker.
    public func onDispose() {
        if isDisposed {
            return
        }

        isDisposed = true

        do {
            try endClient()
        } catch {
            log.error("Could not end client gracefully. \(error)")
        }
    }

    /// Gracefully ends the client.
    /// - NOTE: This triggers deadvertisements without using the last will.
    public func endClient() throws {
        updateOperatingState(.stopping)

        // Gracefully send deadvertise messages to others.
        // NOTE: This does not change or adjust the last will.
        try deadvertiseIdentityOrDevice()

        client.disconnect()
        deferredSubscriptions = Set<String>()
        deferredPublications = []
        deadvertiseIds = []
        subscriptions = [:]
        updateOperatingState(.stopped)
    }

    // MARK: - Coaty management methods.

    /// Advertises the identity and/or associated device of a
    /// CommunicationManager.
    private func advertiseIdentityOrDevice() throws {
         // Advertise associated device once if existing.
        // (cp. CommunicationManager.observeDiscoverDevice)
        if communicationOptions.shouldAdvertiseDevice != false &&
           associatedDevice != nil {
            let event = AdvertiseEvent<CoatyObjectFamily>.withObject(eventSource: identity,
                                                                     object: associatedDevice!)
            // TODO: Republish only once on failed reconnection attempts.
            try publishAdvertise(advertiseEvent: event)
        }

        // Advertise identity once if required.
        // (cp. CommunicationManager.observeDiscoverIdentity)
        if communicationOptions.shouldAdvertiseIdentity == false {
            return
        }
        
        let event = AdvertiseEvent<CoatyObjectFamily>.withObject(eventSource: identity,
                                                                 object: identity) 
        // TODO: Republish only once on failed reconnection attempts.
        try publishAdvertise(advertiseEvent: event)
    }

    /// Deadvertises all components that were registered with the communication
    /// manager, including its own identity.
    private func deadvertiseIdentityOrDevice() throws {
        let deadvertiseEvent = try DeadvertiseEvent<Family>.withObjectIds(eventSource: identity, objectIds: deadvertiseIds)

        try publishDeadvertise(deadvertiseEvent: deadvertiseEvent)
    }

    private func observeDiscoverDevice() {
        if communicationOptions.shouldAdvertiseDevice == false ||
           associatedDevice == nil {
            return
        }

        try? observeDiscover(eventTarget: identity)
            .filter { (event) -> Bool in
                (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Device)) ||
                (event.data.isDiscoveringObjectId() && event.data.objectId == self.associatedDevice?.objectId)
            }
            .subscribe(onNext: { event in
                guard let associatedDevice = self.associatedDevice else {
                    return
                }

                let factory = ResolveEventFactory<Family>(self.identity)
                let resolveEvent = factory.with(object: associatedDevice)
                event.resolve(resolveEvent: resolveEvent)
            }).disposed(by: disposeBag)
    }

    private func observeDiscoverIdentity() {
        if communicationOptions.shouldAdvertiseIdentity == false {
            return
        }

        try? observeDiscover(eventTarget: identity)
            .filter({ (event) -> Bool in
                (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Component)) ||
                (event.data.isDiscoveringObjectId() && event.data.objectId == self.identity.objectId)
            })
            .subscribe(onNext: { event in
                let factory = ResolveEventFactory<Family>(self.identity)
                let resolveEvent = factory.with(object: self.identity)

                event.resolve(resolveEvent: resolveEvent)
            }).disposed(by: disposeBag)
    }

    // MARK: - Communication methods.

    /// Subscribe defers subscriptions until the communication manager comes online.
    ///
    /// - Parameter topic: topic name.
    func subscribe(topic: String) {
        queue.sync {
            _ = getCommunicationState()
                .take(1)
                .subscribe(onNext: { state in

                    self.deferredSubscriptions.insert(topic)

                    // Subscribe if the client is online.
                    if state == .online {
                        // Do NOT clean up deferredSubscriptions since we may
                        // need them for reconnects. Update subscription count
                        // map. Do NOT subscribe the same topic filter multiple
                        // times to avoid receiving multiple events on this
                        // topic.
                        if let count = self.subscriptions[topic] {
                            self.subscriptions[topic] = count + 1
                        } else {
                            self.subscriptions[topic] = 1
                            self.client.subscribe(topic) 
                        }
                    }
                })
        }
    }

    func unsubscribe(topic: String) {
        _ = queue.sync {
            
            if let count = self.subscriptions[topic] {
                if count == 1 {
                    client.unsubscribe(topic)
                    self.subscriptions.removeValue(forKey: topic)
                    self.deferredSubscriptions.remove(topic)
                } else {
                    self.subscriptions[topic] = count - 1
                }
            }
        }
    }

    /// Publish defers publications until the communication manager comes online.
    ///
    /// - Parameters:
    ///   - topic: the publication topic.
    ///   - message: the payload message.
    func publish(topic: String, message: String) {
        _ = queue.sync {
            _ = getCommunicationState()
                .take(1)
                .filter { $0 == .offline }
                .subscribe(onNext: { _ in
                    self.deferredPublications.append((topic, message))
                })

            // Attempt to publish regardless of the connection status. If we are offline, this will
            // fail silently.
            client.publish(topic, message: message)
        }
    }

    /// Convenience setter for the operating state.
    func updateOperatingState(_ state: OperatingState) {
        operatingState.onNext(state)
    }
}

extension CommunicationManager: Startable {
    func didReceiveStart() {
        self.mDNSStart()
    }
    
    /// Starts the client after mDNS discovery.
    private func mDNSStart() {
        if (communicationOptions.mqttClientOptions!.shouldTryMDNSDiscovery) {
            
            updateOperatingState(.starting)
            
            // Listen to discover events.
            observeDiscoverDevice()
            observeDiscoverIdentity()
            
            updateOperatingState(.started)
        }
    }
}
