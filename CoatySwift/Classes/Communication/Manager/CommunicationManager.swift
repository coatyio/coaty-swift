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
public class CommunicationManager {
    
    // MARK: - Logger.
    internal let log = LogManager.log
    
    // MARK: - Variables.
    
    private var brokerClientId: String?
    /// Dispose bag for all RxSwift subscriptions.
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    internal var identity: Component!
    internal var mqtt: CocoaMQTT?
    private var associatedUser: User?
    private var associatedDevice: Device?
    private var isDisposed = false

    
    /// Ids of all advertised components that should be deadvertised when the client ends.
    internal var deadvertiseIds = [UUID]()
    
    // MARK: - Observables.
    
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)
    
    /// Observable emitting raw (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()
    
    // MARK: - Initializers.
    
    public init(host: String, port: Int) {
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
        deadvertiseIds.append(identity.objectId)
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
        guard let deadvertiseEvent = try? DeadvertiseEvent.withObject(eventSource: identity,
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
    
    /**
     * Unsubscribe and disconnect from the messaging broker.
     */
    public func onDispose() {
        if (self.isDisposed) {
            return;
        }
    
        self.isDisposed = true;
        try! endClient(); // TODO: Check force unwrwap.
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
        let deadvertiseEvent = DeadvertiseEvent(eventSource: identity, eventData: deadvertiseEventData)
        
        try publishDeadvertise(deadvertiseEvent: deadvertiseEvent)
    }
    
    // MARK: - Communication methods.
    
    func subscribe(topic: String) {
        mqtt?.subscribe(topic)
    }
    
    func unsubscribe(topic: String) {
        mqtt?.unsubscribe(topic)
    }
    
    func publish(topic: String, message: String) {
        mqtt?.publish(topic, withString: message)
    }
    
}
