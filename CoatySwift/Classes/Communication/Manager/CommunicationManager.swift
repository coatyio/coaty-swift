//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationManager.swift
//  CoatySwift
//
//

import CocoaMQTT
import Foundation
import RxSwift

/// Provides a set of predefined communication events to transfer Coaty objects
/// between distributed Coaty agents based on the publish-subscribe API of a
/// `CommunicationClient`.
public class CommunicationManager {
    internal enum MessagePayload {
        case stringPayload(String)
        case bytesArrayPayload([UInt8])
    }
    
    // MARK: - Logger.

    internal let log = LogManager.log

    // MARK: - Properties.

    /// Dispose bag for observable subscriptions to be disposed when client ends.
    private var disposeBag = DisposeBag()
    private var isDisposed = false

    /// Gets the namespace for communication as specified in the configuration
    /// options. Returns the default namespace used, if no namespace has been
    /// specified in configuration options.
    private (set) public var namespace: String

    internal var communicationOptions: CommunicationOptions
    private var subscriptions = [String: Int]()
    
    // Container identity for public and internal use.
    public var identity: Identity

    /// The operating state of the communication manager.
    internal var operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .stopped)

    /// Convenience getter for the communication state of the underlying communication client.
    internal var communicationState: BehaviorSubject<CommunicationState> {
        return client.communicationState
    }

    /// Holds deferred subscriptions while the communication manager is offline.
    private var deferredSubscriptions = Set<String>()

    /// Holds deferred publications (topic, payload) while the communication manager is offline.
    private var deferredPublications = [(String, MessagePayload)]()

    /// Ids of all advertised components that should be deadvertised on disconnection.
    internal var deadvertiseIds = [CoatyUUID]()

    /// A dispatchqueue that handles synchronisation issues when accessing
    /// deferred publications and subscriptions.
    private var queue = DispatchQueue(label: "com.coatyswift.comQueue")

    /// The communication client that offers the required publisher-subscriber API.
    internal var client: CommunicationClient!

    // MARK: - Initializers.

    public init(identity: Identity, communicationOptions: CommunicationOptions) {
        self.identity = identity
        self.communicationOptions = communicationOptions
        self.namespace = communicationOptions.namespace ?? DEFAULT_NAMESPACE
        try! initializeNamespace()
        
        let mqttClientOptions = self.communicationOptions.mqttClientOptions!
        initializeMQTTClientId(mqttClientOptions)

        client = CocoaMQTTClient(mqttClientOptions: mqttClientOptions, delegate: self)
        
        setupOperatingStateLogging()
        setupCommunicationStateLogging()
        setupOnConnectHandler()
        
        if self.communicationOptions.shouldAutoStart && !mqttClientOptions.shouldTryMDNSDiscovery {
            self.didReceiveStart()
        }
    }

    // MARK: - Manager lifecycle methods.

    /// Starts this communication manager with the communication options
    /// specified in the configuration. This is a noop if the communication
    /// manager has already been started.
    public func start() {
        guard try! self.operatingState.value() != OperatingState.started else {
            return
        }
        startClient()
    }

    /// Stops dispatching and emitting communication events and disconnects from
    /// the communication infrastructure.
    ///
    /// To continue processing with this communication manager sometime later,
    /// invoke `start()`.
    public func stop() {
        endClient()
    }

    /// Unsubscribe and disconnect from the communication binding.
    public func onDispose() {
        if isDisposed {
            return
        }

        isDisposed = true

        endClient()
    }

    /// Starts the client gracefully and tries to connect to the broker.
    private func startClient() {
        // Reinitialize potentially changed options in case of a restart.
        let mqttClientOptions = self.communicationOptions.mqttClientOptions!
        initializeMQTTClientId(mqttClientOptions)
        try! initializeNamespace()
        initializeDeadvertisements()
        
        // Listen to Discover events for Identity.
        observeDiscoverIdentity()

        let lastWill = self.getLastWill()
        self.client.connect(lastWillTopic: lastWill.topic, lastWillMessage: lastWill.msg)
        updateOperatingState(.started)
    }

    /// Gracefully ends the client.
    /// - NOTE: This triggers explicit identity deadvertisements.
    private func endClient() {
        // Gracefully send deadvertise messages to others.
        // NOTE: This does not change or adjust the last will.
        deadvertiseIdentity()

        self.disposeBag = DisposeBag()
        self.client.disconnect()
        self.deferredSubscriptions = Set<String>()
        self.deferredPublications = []
        self.deadvertiseIds = []
        self.subscriptions = [:]
        updateOperatingState(.stopped)
    }

    // MARK: - Setup methods.

    private func initializeMQTTClientId(_ mqttClientOptions: MQTTClientOptions) {
        // Assign a valid client id according to MQTT Spec 3.1:
        // The Server MUST allow ClientIds which are between 1 and 23 UTF-8 encoded 
        // bytes in length, and that contain only the characters
        // "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".
        // The Server MAY allow ClientId’s that contain more than 23 encoded bytes.
        // The Server MAY allow ClientId’s that contain characters not included in the list given above. 
        let id = self.identity.objectId.string;
        if self.communicationOptions.useProtocolCompliantClientId == false {
            mqttClientOptions.clientId = "Coaty\(id)"
            return
        }
        mqttClientOptions.clientId = "Coaty" + String(id.replacingOccurrences(of: "-", with: "").prefix(18))
    }

    private func initializeNamespace() throws {
        var ns = self.communicationOptions.namespace
        
        if ns == "" || ns == nil {
            ns = DEFAULT_NAMESPACE
        }
        
        guard CommunicationTopic.isValidEventTypeFilter(filter: ns!) else {
            throw CoatySwiftError.InvalidConfiguration("CommunicationOptions.namespace contains invalid characters")
        }
        
        self.namespace = ns!
    }

    private func initializeDeadvertisements() {
        // Make sure the identity is added to the deadvertiseIds array in order to
        // send out a correct last will message.
        deadvertiseIds.append(self.identity.objectId)
    }

    /// Setup for the handler method that is invoked when the communication state of the client changes to online.
    private func setupOnConnectHandler() {
        _  = self.communicationState
            .filter { $0 == .online }
            .subscribe { _ in

                self.advertiseIdentity()

                // Publish possible deferred subscriptions and publications.
                _ = self.queue.sync {
                    self.deferredSubscriptions.forEach { topic in
                        self.client.subscribe(topic)
                    }

                    self.deferredPublications.forEach { publication in
                        let topic = publication.0
                        let payload = publication.1
                        switch payload {
                        case .bytesArrayPayload(let bytesArray):
                            self.client.publish(topic, message: bytesArray)
                        case .stringPayload(let string):
                            self.client.publish(topic, message: string)
                        }
                    }

                    self.deferredPublications = []
                }

            }
    }

    private func setupOperatingStateLogging() {
        _ = self.operatingState.subscribe(onNext: { state in
            self.log.debug("Operating State: \(String(describing: state))")
        })
    }

    private func setupCommunicationStateLogging() {
        _ = self.communicationState.subscribe(onNext: { state in
            self.log.info("Communication State: \(String(describing: state))")
        })
    }

    /// Gets last will message to be published when the connection terminates
    /// abnormally.
    private func getLastWill() -> (topic: String, msg: String) {
        let lastWillTopic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                                   sourceId: self.identity.objectId,
                                                                                   eventType: .Deadvertise)
        let deadvertiseEvent = DeadvertiseEvent.with(objectIds: deadvertiseIds)

        deadvertiseEvent.sourceId = self.identity.objectId

        return (lastWillTopic,  deadvertiseEvent.json)
    }

    // MARK: - Identity lifecycle management.

    private func advertiseIdentity() {
        // Advertise identity once.
        // (cp. CommunicationManager.observeDiscoverIdentity)
        try! publishAdvertise(AdvertiseEvent.with(object: self.identity))
    }

    private func deadvertiseIdentity() {
        publishDeadvertise(DeadvertiseEvent.with(objectIds: deadvertiseIds))
    }

    private func observeDiscoverIdentity() {
        observeDiscover()
            .filter({ (event) -> Bool in
                (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Identity)) ||
                (event.data.isDiscoveringObjectId() && event.data.objectId == self.identity.objectId)
            })
            .subscribe(onNext: { event in
                let resolveEvent = ResolveEvent.with(object: self.identity)
                event.resolve(resolveEvent: resolveEvent)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Communication methods.

    /// Subscribe defers subscriptions until the communication manager comes online.
    ///
    /// - Parameter topic: topic name.
    internal func subscribe(topic: String) {
        _ = queue.sync {
            self.deferredSubscriptions.insert(topic)

            // Subscribe if the client is online.
            if try! self.communicationState.value() == .online {
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
        }
    }

    internal func unsubscribe(topic: String) {
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
    ///   - message: the payload message as String.
    internal func publish(topic: String, message: String) {
        _ = queue.sync {
            if try! self.communicationState.value() == .offline {
                self.deferredPublications.append((topic, MessagePayload.stringPayload(message)))
            } else {
                // Attempt to publish. If we are disconnecting, this will fail silently.
                client.publish(topic, message: message)
            }
        }
    }
    
    /// Publish defers publications until the communication manager comes online.
    ///
    /// - Parameters:
    ///   - topic: the publication topic.
    ///   - message: the payload message as Bytes array.
    internal func publish(topic: String, message: [UInt8]) {
        _ = queue.sync {
            if try! self.communicationState.value() == .offline {
                self.deferredPublications.append((topic, MessagePayload.bytesArrayPayload(message)))
            } else {
                // Attempt to publish. If we are disconnecting, this will fail silently.
                client.publish(topic, message: message)
            }
        }
    }

    /// Convenience setter for the operating state.
    private func updateOperatingState(_ state: OperatingState) {
        self.operatingState.onNext(state)
    }
}

extension CommunicationManager: Startable {

    /// Auto start communication manager (caused by shouldAutoStart option or
    /// bonjour discovery).
    func didReceiveStart() {
        self.start();
    }

}
