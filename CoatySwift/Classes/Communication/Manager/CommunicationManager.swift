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
    private var associatedUser: User?
    private var associatedDevice: Device?
    private var isDisposed = false
    private var communicationOptions: CommunicationOptions

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
    internal var client: CommunicationClient

    // MARK: - Initializers.

    public init(communicationOptions: CommunicationOptions) {
        self.communicationOptions = communicationOptions
        
        client = CocoaMQTTClient(communicationOptions: communicationOptions)
        client.delegate = self

        initializeIdentity()

        setupOperatingStateLogging()
        setupCommunicationStateLogging()
        setupOnConnectHandler()
    }

    // MARK: - Setup methods.

    public func initializeIdentity() {
        let objectType = COATY_PREFIX + CoreType.Component.rawValue
        identity = Component(coreType: .Component,
                             objectType: objectType,
                             objectId: .init(), name: "CommunicationManager")

        // Make sure the identity is added to the deadvertiseIds array in order to
        // send out a correct last will message.
        deadvertiseIds.append(identity!.objectId)
    }

    /// Setup for the handler method that is invoked when the communication state of the client changes to online.
    private func setupOnConnectHandler() {
        client.communicationState
            .filter { $0 == .online }
            .subscribe { _ in

                try? self.advertiseIdentityOrDevice(eventTarget: self.identity)

                // Publish possible deferred subscriptions and publications.
                _ = self.queue.sync {
                    self.deferredSubscriptions.forEach { topic in
                        self.client.subscribe(topic)
                    }

                    // FIXME: This MAY be a race condition between the subscriptions and the publications.
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
    /// - NOTE: the willMessage is only sent out at the beginning of the connection and cannot
    /// be changed afterwards, unless you reconnect.
    func setLastWill() {
        guard let lastWillTopic = try? Topic.createTopicStringByLevelsForPublish(eventType: .Deadvertise,
                                                                                 eventTypeFilter: nil,
                                                                                 associatedUserId: nil,
                                                                                 sourceObject: identity,
                                                                                 messageToken: CoatyUUID().string) else {
            log.error("Could not create topic string for last will.")
            return
        }

        let deadvertise = Deadvertise(objectIds: deadvertiseIds)
        guard let deadvertiseEvent = try? DeadvertiseEvent.withObject(eventSource: identity,
                                                                      object: deadvertise) else {
            log.error("Could not create DeadvertiseEvent.")
            return
        }

        client.setWill(lastWillTopic, message: deadvertiseEvent.json)
    }

    private func initOptions(options _: CommunicationOptions) {
        // Capture state of associated user and device in case it might change
        // while the communication manager is being online.

        // TODO: Missing implementation!

        /*
         this._associatedUser = CoreTypes.clone<User>(this.runtime.options.associatedUser);
         this._associatedDevice = CoreTypes.clone<Device>(this.runtime.options.associatedDevice);
         this._useReadableTopics = !!this.options.useReadableTopics;
         */
    }

    // MARK: - Client lifecycle methods.

    /// - TODO: Missing dependency with initOptions.
    public func start() {
        // initOptions(options: )
        startClient()
    }

    /// Starts the client gracefully and connects to the broker.
    public func startClient() {
        updateOperatingState(.starting)

        // Listen to discover events.
        observeDiscoverDevice()
        observeDiscoverIdentity()

        client.connect()
        updateOperatingState(.started)
    }

    /// Unsubscribe and disconnect from the messaging broker.
    public func onDispose() {
        if isDisposed {
            return
        }

        isDisposed = true
        deferredSubscriptions = Set<String>()

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
        updateOperatingState(.stopped)
    }

    // MARK: - Coaty management methods.

    /// Deadvertises all identities that were registered over the communication manager, including
    /// its own identity.
    private func deadvertiseIdentityOrDevice() throws {
        let deadvertise = Deadvertise(objectIds: deadvertiseIds)
        let deadvertiseEventData = DeadvertiseEventData.createFrom(eventData: deadvertise)
        let deadvertiseEvent = DeadvertiseEvent(eventSource: identity!, eventData: deadvertiseEventData)

        try publishDeadvertise(deadvertiseEvent: deadvertiseEvent)
    }

    private func observeDiscoverDevice() {
        if communicationOptions.shouldAdvertiseDevice == false || associatedDevice == nil {
            return
        }

        try? observeDiscover(eventTarget: identity!)
            .filter { (event) -> Bool in
                event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Device)
                    || (event.data.isDiscoveringObjectId() && event.data.objectId == self.associatedDevice?.objectId)
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

        try? observeDiscover(eventTarget: identity!)
            .filter({ (event) -> Bool in
                (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Component))
                    || (event.data.isDiscoveringObjectId() && event.data.objectId == self.identity?.objectId)
            })
            .subscribe(onNext: { event in
                let factory = ResolveEventFactory<Family>(self.identity!)
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
                        self.client.subscribe(topic)
                        // Do NOT delete deferredSubscriptions since we may need them for reconnects.
                    }
                })
        }
    }

    /// - TODO: We currently do not handle unsubscribe events with respect to removing topics from
    ///   the deferredSubscriptions. Coaty-js handles this via its hashtable structure.
    func unsubscribe(topic: String) {
        _ = queue.sync {
            client.unsubscribe(topic)
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
        updateOperatingState(.starting)
        
        // Listen to discover events.
        observeDiscoverDevice()
        observeDiscoverIdentity()
        
        updateOperatingState(.started)
    }
}
