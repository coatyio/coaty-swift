//
//  CommunicationManager.swift
//  CoatySwift
//
//

import Foundation
import CocoaMQTT
import RxSwift




/// Manages a set of predefined communication events and event patterns to query, distribute, and
/// share Coaty objects across decantralized application components using publish-subscribe on top
/// of MQTT messaging.
/// - Note: Because overriding declarations in extensions is not supported yet, we have to have all
/// observe and publish methods inside this class.
public class CommunicationManager<Family: ObjectFamily>: CocoaMQTTDelegate {
    
    // MARK: - Logger.
    
    internal let log = LogManager.log
    
    // MARK: - Variables.
    
    internal var mqtt: CocoaMQTT?
    private var brokerClientId: String?
    /// Dispose bag for all RxSwift subscriptions.
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    private var associatedUser: User?
    private var associatedDevice: Device?
    internal var identity: Component?
    private var isDisposed = false
    
    // MARK: - State management observables.
    
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)

    /// Holds deferred subscriptions while the communication manager is offline.
    private var deferredSubscriptions = Set<String>()
    
    /// Holds deferred publications (topic, payload) while the communication manager is offline.
    private var deferredPublications = [(String, String)]()

    /// Ids of all advertised components that should be deadvertised when the client ends.
    internal var deadvertiseIds = [CoatyUUID]()
    
    /// Observable emitting (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()
    
    /// Observable emitting *raw* (topic, payload) mqtt messages.
    let rawMQTTMessages: PublishSubject<(String, [UInt8])> = PublishSubject<(String, [UInt8])>()
    
    /// A dispatchqueue that handles synchronisation issues when accessing
    /// deferred publications and subscriptions.
    private var queue = DispatchQueue(label: "com.siemens.coatyswift.comQueue")
    
    // MARK: - Initializers.
    
    public init(mqttClientOptions: MQTTClientOptions) {
        initIdentity()
        
        // Setup client Id.
        let brokerClientId = generateClientId(mqttClientOptions.clientId)
        self.brokerClientId = brokerClientId
        
        // Configure mqtt client.
        mqtt = CocoaMQTT(clientID: brokerClientId,
                         host: mqttClientOptions.host,
                         port: UInt16(mqttClientOptions.port))
        mqtt?.keepAlive = mqttClientOptions.keepAlive
        
        // TODO: Make this configurable.
        mqtt?.allowUntrustCACertificate = true
        mqtt?.enableSSL = mqttClientOptions.enableSSL
        mqtt?.autoReconnect = mqttClientOptions.autoReconnect
        
        // TODO: Make this configurable.
        mqtt?.autoReconnectTimeInterval = 3 // seconds.
        mqtt?.delegate = self
        
        operatingState.subscribe(onNext: { (state) in
            self.log.debug("Operating State: \(String(describing: state))")
        }).disposed(by: disposeBag)
        
        communicationState.subscribe(onNext: { (state) in
            self.log.debug("Comm. State: \(String(describing: state))")
        }).disposed(by: disposeBag)
        
        
        // TODO: opt-out: shouldAdvertiseIdentity from configuration.
        communicationState
            .filter { $0 == .online }
            .subscribe { (event) in
                
                // FIXME: Remove force unwrap.
                try? self.advertiseIdentityOrDevice(eventTarget: self.identity!)
                
                // Publish possible deferred subscriptions and publications.
                _ = self.queue.sync {
                    self.deferredSubscriptions.forEach { (topic) in
                        self.mqtt?.subscribe(topic)
                    }
                    
                    // FIXME: This MAY be a race condition between the subscriptions and the publications.
                    self.deferredPublications.forEach { (publication) in
                        let topic = publication.0
                        let payload = publication.1
                        self.mqtt?.publish(topic, withString: payload)
                    }
                    
                    self.deferredPublications = []
                }
                
            }.disposed(by: disposeBag)
    }
    
    /// - TODO: This should most likely return a Component object in the future.
    public func initIdentity() {
        let objectType = COATY_PREFIX + CoreType.Component.rawValue
        identity = Component(coreType: .Component,
                             objectType: objectType,
                             objectId: .init(), name: "CommunicationManager")
        
        // Make sure the identity is added to the deadvertiseIds array in order to
        // send out a correct last will message.
        deadvertiseIds.append(identity!.objectId)
    }
    
    // MARK: - Setup methods.
    
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
        guard let deadvertiseEvent = try? DeadvertiseEvent.withObject(eventSource: identity!,
                                                                      object: deadvertise) else {
            log.error("Could not create DeadvertiseEvent.")
            return
        }
        
        mqtt?.willMessage = CocoaMQTTWill(topic: lastWillTopic, message: deadvertiseEvent.json)
    }
    
    /// Generates Coaty client Id.
    /// - TODO: Adjust to MQTT specification (maximum length is currently ignored).
    func generateClientId(_ clientId: String) -> String {
        return "COATY-\(clientId)"
    }
    
    // MARK: - Broker methods.
    
    private func connect() {
        mqtt?.connect()
    }
    
    private func disconnect() {
        mqtt?.disconnect()
    }
    
    // MARK: - State management methods.
    
    func updateOperatingState(_ state: OperatingState) {
        operatingState.onNext(state)
    }
    
    func updateCommunicationState(_ state: CommunicationState) {
        communicationState.onNext(state)
    }
    
    // MARK: - Client lifecycle methods.
    
    private func initOptions(options: CommunicationOptions) {
        
        // Capture state of associated user and device in case it might change
        // while the communication manager is being online.
        
        // TODO: Missing implementation!
        
        /*
        this._associatedUser = CoreTypes.clone<User>(this.runtime.options.associatedUser);
        this._associatedDevice = CoreTypes.clone<Device>(this.runtime.options.associatedDevice);
        this._useReadableTopics = !!this.options.useReadableTopics;
        */
    }
    
    public func start() {
        // TODO: Missing dependency with initOptions.
        // initOptions(options: )
        startClient()
    }
    
    /// Starts the client gracefully and connects to the broker.
    public func startClient() {
        updateOperatingState(.starting)
        connect()
        updateOperatingState(.started)
    }
    
    /// Unsubscribe and disconnect from the messaging broker.
    public func onDispose() {
        if (self.isDisposed) {
            return;
        }
    
        self.isDisposed = true;
        self.deferredSubscriptions = Set<String>()
        try! endClient() // TODO: Check force unwrwap.
    }
    
    /// Gracefully ends the client.
    /// - NOTE: This triggers deadvertisements without using the last will.
    public func endClient() throws {
        updateOperatingState(.stopping)
        
        // Gracefully send deadvertise messages to others.
        // NOTE: This does not change or adjust the last will.
        try deadvertiseIdentityOrDevice()
        
        disconnect()
        self.deferredSubscriptions = Set<String>()
        updateOperatingState(.stopped)
    }
    
    /// Deadvertises all identities that were registered over the communication manager, including
    /// its own identity.
    private func deadvertiseIdentityOrDevice() throws {
        let deadvertise = Deadvertise(objectIds: deadvertiseIds)
        let deadvertiseEventData = DeadvertiseEventData.createFrom(eventData: deadvertise)
        let deadvertiseEvent = DeadvertiseEvent(eventSource: identity!, eventData: deadvertiseEventData)
        
        try publishDeadvertise(deadvertiseEvent: deadvertiseEvent)
    }
    
    // MARK: - Communication methods.
    
    /// Subscribe defers subscriptions until the communication manager comes online.
    ///
    /// - Parameter topic: topic name.
    func subscribe(topic: String) {
        queue.sync {
            
            _ = getCommunicationState()
                .take(1)
                .subscribe(onNext: { (state) in
                
                self.deferredSubscriptions.insert(topic)
                
                // Subscribe if the client is online.
                if state == .online {
                    self.mqtt?.subscribe(topic)
                    // Do NOT delete deferredSubscriptions since we may need them for reconnects.
                }
            })
        }
    }
    
    /// - TODO: We currently do not handle unsubscribe events with respect to removing topics from
    ///   the deferredSubscriptions. Coaty-js handles this via its hashtable structure.
    func unsubscribe(topic: String) {
        _ = queue.sync {
            self.mqtt?.unsubscribe(topic)
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
                .filter { $0 == .offline}
                .subscribe(onNext: { state in
                    self.deferredPublications.append((topic, message))
            })
            
            // Attempt to publish regardless of the connection status. If we are offline, this will
            // fail silently.
            self.mqtt?.publish(topic, withString: message)
        }
    }
    
    // MARK: - CocoaMQTTDelegate methods.
    // These had to be moved here because of some objc incompatibility with extensions and
    // generics.
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        updateCommunicationState(.online)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        rawMQTTMessages.onNext((message.topic, message.payload))
        
        if let payloadString = message.string {
            rawMessages.onNext((message.topic, payloadString))
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        log.debug("Subscribed to topic \(topic).")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        log.debug("Unsubscribed from topic \(topic).")
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        log.error("Did disconnect with error. \(err?.localizedDescription ?? "")")
        updateCommunicationState(.offline)
    }
    
}
