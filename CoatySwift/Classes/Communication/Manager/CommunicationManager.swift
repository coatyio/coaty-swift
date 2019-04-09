//
//  CommunicationManager.swift
//  CoatySwift
//
//

import Foundation
import CocoaMQTT
import RxSwift

/// This class only holds dummy implementations in order to leverage type erasure because of
/// ObjectFamily Generics dependencies to make the application programmer's life easier.
public class AnyCommunicationManager {
    
    // MARK: - Observables and important methods.
    
    // These are non-dummy values and had to be pulled out from the CommunicationManager
    // class to this one, because of their dependency in the Controller class.
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)
    internal var identity: Component?
    
    public func getCommunicationState() -> Observable<CommunicationState> {
        return communicationState.asObserver()
    }
    
    public func getOperatingState() -> Observable<OperatingState> {
        return operatingState.asObserver()
    }
    
    // MARK: - Dummy methods.
    
    public func publishAdvertise<S: CoatyObject,T: AdvertiseEvent<S>>(advertiseEvent: T,
                                                                      eventTarget: Component) throws {}
    
    func onDispose() {}
    
}


/// Manages a set of predefined communication events and event patterns to query, distribute, and
/// share Coaty objects across decantralized application components using publish-subscribe on top
/// of MQTT messaging.
/// - Note: Because overriding declarations in extensions is not supported yet, we have to have all
/// observe and publish methods inside this class.
public class CommunicationManager<Family: ObjectFamily>: AnyCommunicationManager, CocoaMQTTDelegate {
    
    // MARK: - Logger.
    internal let log = LogManager.log
    
    // MARK: - Variables.
    
    private var brokerClientId: String?
    /// Dispose bag for all RxSwift subscriptions.
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    internal var mqtt: CocoaMQTT?
    private var associatedUser: User?
    private var associatedDevice: Device?
    private var isDisposed = false
    
    /// Holds deferred subscriptions while the communication manager is offline.
    private var deferredSubscriptions = [String]()
    
    /// Holds deferred publications (topic, payload) while the communication manager is offline.
    private var deferredPublications = [(String, String)]()

    /// Ids of all advertised components that should be deadvertised when the client ends.
    internal var deadvertiseIds = [UUID]()
    
    /// Observable emitting raw (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()
    
    /// A dispatchqueue that handles synchronisation issues when accessing
    /// deferred publications and subscriptions.
    private var queue = DispatchQueue(label: "com.siemens.coatyswift.comQueue")
    
    // MARK: - Initializers.
    
    public init(host: String, port: Int) {
        super.init()
        initIdentity()
        brokerClientId = generateClientId()
        mqtt = CocoaMQTT(clientID: getBrokerClientId(), host: host, port: UInt16(port))
        configureBroker()
        
        // FIXME: Remove debugging statements at later point in development.
        operatingState.subscribe { (event) in
            self.log.info("Operating State: \(String(describing: event.element!))")
            // print("Operating State: \(String(describing: event.element!))")
            }.disposed(by: disposeBag)
        
        communicationState.subscribe { (event) in
            self.log.info("Comm. State: \(String(describing: event.element!))")
            // print("Comm. State: \(String(describing: event.element!))")
            }.disposed(by: disposeBag)
        
        
        // TODO: opt-out: shouldAdvertiseIdentity from configuration.
        communicationState
            .filter { $0 == .online }
            .subscribe { (event) in
                // FIXME: Remove force unwrap.
                try? self.advertiseIdentityOrDevice(eventTarget: self.identity!)
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
                                                                                 messageToken: UUID.init().uuidString) else {
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
    func generateClientId() -> String {
        return "COATY-\(UUID.init())"
    }
    
    /// - NOTE: In case there was no brokerClientId before, it is set.
    func getBrokerClientId() -> String {
        if let brokerClientId = brokerClientId {
            return brokerClientId
        }
        brokerClientId = generateClientId()
        return brokerClientId!
    }
    
    // MARK: - Broker methods.
    
    private func configureBroker() {
        mqtt?.keepAlive = 60
        mqtt?.allowUntrustCACertificate = true
        mqtt?.delegate = self
        setLastWill()
    }
    
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
    public override func onDispose() {
        if (self.isDisposed) {
            return;
        }
    
        self.isDisposed = true;
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
        
            _ = getCommunicationState().subscribe {
                guard let state = $0.element else {
                    return
                }
                
                self.deferredSubscriptions.append(topic)
                
                // Subscribe if the client is online.
                
                if state == .online {
                    self.deferredSubscriptions.forEach({ (topic) in
                        self.mqtt?.subscribe(topic)
                    })
                    
                    self.deferredSubscriptions = []
                }
            }
        }
    }
    
    func unsubscribe(topic: String) {
        // TODO: Implement properly.
        _ = queue.sync {
            mqtt?.unsubscribe(topic)
        }

    }
    
    /// Publish defers publications until the communication manager comes online.
    ///
    /// - Parameters:
    ///   - topic: the publication topic.
    ///   - message: the payload message.
    func publish(topic: String, message: String) {
        queue.sync {
            _ = getCommunicationState().subscribe {
                guard let state = $0.element else {
                    return
                }
                
                self.deferredPublications.append((topic, message))
                
                // Publish if the client is online.
                
                if state == .online {
                    self.deferredPublications.forEach({ (publication) in
                        let topic = publication.0
                        let payload = publication.1
                        self.mqtt?.publish(topic, withString: payload)
                    })
                    
                    self.deferredPublications = []
                }
            }
        }
    }
    
    // MARK: - CocoaMQTTDelegate methods.
    // These had to be moved hear because of some objc incompatibility with extensions and
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
        if let payloadString = message.string {
            rawMessages.onNext((message.topic, payloadString))
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        log.info("Subscribed to topic \(topic).")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        log.info("Unsubscribed from topic \(topic).")
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        log.error("Did disconnect with error.")
        updateCommunicationState(.offline)
    }
    
    
    // MARK: - Publish Methods needed for type erasure fix (could not be moved to extensions).
    
    /// Publishes a given advertise event.
    ///
    /// - Parameters:
    ///     - advertiseEvent: The event that should be advertised.
    public override func publishAdvertise<S: CoatyObject,T: AdvertiseEvent<S>>(advertiseEvent: T,
                                                                               eventTarget: Component) throws {
        
        let topicForObjectType = try Topic
            .createTopicStringByLevelsForPublish( eventType: .Advertise,
                                                  eventTypeFilter:advertiseEvent.eventData.object.objectType,
                                                  associatedUserId: "-",
                                                  sourceObject: advertiseEvent.eventSource,
                                                  messageToken: UUID.init().uuidString)
        
        let topicForCoreType = try Topic
            .createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                 eventTypeFilter: advertiseEvent.eventData.object.coreType.rawValue,
                                                 associatedUserId: "-",
                                                 sourceObject: advertiseEvent.eventSource,
                                                 messageToken: UUID.init().uuidString)
        
        // Save advertises for Components or Devices.
        if advertiseEvent.eventData.object.coreType == .Component ||
            advertiseEvent.eventData.object.coreType == .Device {
            
            // Add if not existing already in deadvertiseIds.
            if !deadvertiseIds.contains(advertiseEvent.eventData.object.objectId) {
                deadvertiseIds.append(advertiseEvent.eventData.object.objectId)
            }
        }
        
        // Publish the advertise for core AND object type.
        publish(topic: topicForCoreType, message: advertiseEvent.json)
        publish(topic: topicForObjectType, message: advertiseEvent.json)
    }
    
    // MARK: - CommunicationManager+Util methods (Again, had to be moved here because of the
    // AnyCommunicationManager Type erasure).
    
    public override func getCommunicationState() -> Observable<CommunicationState> {
        return communicationState.asObserver()
    }
    
    public override func getOperatingState() -> Observable<OperatingState> {
        return operatingState.asObserver()
    }
    
}
