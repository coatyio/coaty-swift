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
    
    // MARK: - Variables.
    
    private var brokerClientId: String?
    /// Dispose bag for all RxSwift subscriptions.
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    private var identity: Component!
    private var mqtt: CocoaMQTT?
    
    /// Ids of all advertised components that should be deadvertised when the client ends.
    private var deadvertiseIds = [UUID]()
    
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
            print("Operating State: \(String(describing: event.element!))")
            }.disposed(by: disposeBag)
        
        communicationState.subscribe { (event) in
            print("Comm. State: \(String(describing: event.element!))")
            }.disposed(by: disposeBag)
        
        startClient()
        
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
            // TODO: Handle error.
            return
        }
        
        let deadvertise = Deadvertise(objectIds: deadvertiseIds)
        guard let deadvertiseEvent = try? DeadvertiseEvent.withObject(eventSource: identity,
                                                                      object: deadvertise) else {
            // TODO: Handle error.
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
    
    func startClient() {
        updateOperatingState(.starting)
        connect()
        updateOperatingState(.started)
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

// MARK: - Publish methods.

extension CommunicationManager {
    
    /// Publishes a given advertise event.
    ///
    /// - Parameters:
    ///     - advertiseEvent: The event that should be advertised.
    public func publishAdvertise<S: CoatyObject,T: AdvertiseEvent<S>>(advertiseEvent: T,
                                                               eventTarget: Component) throws {
        
        let topicForObjectType = try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                        eventTypeFilter: advertiseEvent.eventData.object.objectType,
                                        associatedUserId: "-",
                                        sourceObject: advertiseEvent.eventSource,
                                        messageToken: UUID.init().uuidString)
        let topicForCoreType = try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
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
    
    /// Advertises the identity of a CommunicationManager.
    ///
    /// - TODO: Re-use the implementation of publishAdvertise. Currently not possible because of
    /// missing topic creations.
    public func advertiseIdentityOrDevice(eventTarget: Component) throws {
        guard let identity = self.identity else {
            // TODO: Handle error.
            return
        }
        
        let advertiseIdentityEvent = AdvertiseEvent.withObject(eventSource: identity,
                                                               object: identity,
                                                               privateData: nil)
        
        try publishAdvertise(advertiseEvent: advertiseIdentityEvent, eventTarget: identity)
    }
    
    /// Find discoverable objects and receive Resolve events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Discover event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishDiscover<S: Discover,
                                T: DiscoverEvent<S>,
                                U: CoatyObject,
                                V: ResolveEvent<U>>(event: T) throws -> Observable<ResolveEvent<U>> {
        let discoverMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Discover,
                                                              eventTypeFilter: nil,
                                                              associatedUserId: nil,
                                                              sourceObject: event.eventSource,
                                                              messageToken: discoverMessageToken)
        publish(topic: topic, message: event.json)
        
        // FIXME: Subscribe to resolve topic.
        let resolveTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Resolve,
                                                                    eventTypeFilter: nil,
                                                                    associatedUserId: nil,
                                                                    sourceObject: nil,
                                                                    messageToken: discoverMessageToken)
        subscribe(topic: resolveTopic)
        
        return rawMessages.map(convertToTupleFormat)
            .filter(isResolve)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == discoverMessageToken
            })
            .map({ (message) -> V in
                let (_, payload) = message
                // FIXME: Remove force unwrap.

                return PayloadCoder.decode(payload)!
            })
    }
    
    /// Notify subscribers that an advertised object has been deadvertised.
    ///
    /// - Parameter deadvertiseEvent: the Deadvertise event to be published
    public func publishDeadvertise<S: Deadvertise,T: DeadvertiseEvent<S>>(deadvertiseEvent: T) throws {
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Deadvertise,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: deadvertiseEvent.eventUserId
                                                                    ?? EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: deadvertiseEvent.eventSource,
                                                                  messageToken: UUID().uuidString)

        self.publish(topic: topic, message: deadvertiseEvent.json)
    }
}

// MARK: - Observe methods.

extension CommunicationManager {
    
    /// This method should not be called directly, use observeAdvertiseWithCoreType method
    /// or observeAdvertiseWithObjectType method instead.
    ///
    /// - Parameters:
    ///     - topic: topic string in coaty format.
    ///     - eventTarget: Usually, your identity.
    ///     - coreType: observed coreType.
    ///     - objectType: observed objectType.
    private func observeAdvertise<S: CoatyObject, T: AdvertiseEvent<S>>(topic: String,
                                                                        eventTarget: Component,
                                                                        coreType: CoreType?,
                                                                        objectType: String?) throws -> Observable<T> {
        
        if coreType != nil && objectType != nil {
            throw CoatySwiftError.InvalidArgument(
                "Either coreType or objectType must be specified, but not both"
            )
        }
        
        if coreType == nil && objectType == nil {
            throw CoatySwiftError.InvalidArgument("Either coreType or objectType must be specified")
        }
        
        // TODO: Subscribe only if not already subscribed.
        mqtt!.subscribe(topic)
        
        return rawMessages.map(convertToTupleFormat)
            .filter(isAdvertise)
            .filter({ (rawMessageWithTopic) -> Bool in
                
                // Filter messages according to coreType or objectType.
                let (topic, _) = rawMessageWithTopic
                if (objectType != nil) {
                    return objectType == topic.objectType
                }
                
                if (coreType != nil) {
                    return coreType == topic.coreType
                }
                
                return false
            })
            .map({ (message) -> T in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
    }
    
    /// Observes advertises with a particular coreType.
    ///
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - coreType: coreType core type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted coreType.
    public func observeAdvertiseWithCoreType<S: CoatyObject,
                                             T: AdvertiseEvent<S>>(eventTarget: Component,
                                                                   coreType: CoreType) throws -> Observable<T> {
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                eventTypeFilter: coreType.rawValue)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                                             eventTarget: eventTarget,
                                                             coreType: coreType,
                                                             objectType: nil)
        return observable
    }
    
    /// Observes advertises with a particular objectType.
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - objectType: objectType object type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted objectType.
    public func observeAdvertiseWithObjectType<S: CoatyObject,
                                               T: AdvertiseEvent<S>>(eventTarget: Component,
                                                                     objectType: String) throws -> Observable<T> {
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: objectType)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                                             eventTarget: eventTarget,
                                                             coreType: nil,
                                                             objectType: objectType)
        return observable
    }
    
   
    /// Observe Channel events for the given target and the given
    /// channel identifier emitted by the hot observable returned.
    ///
    /// - TODO: The channel identifier must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - TODO: Channel events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    //// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///   - eventTarget: target for which Channel events should be emitted
    ///   - channelId: a channel identifier
    /// - Returns: a hot observable emitting incoming Channel events.
    public func observeChannel<Family: ClassFamily, T: ChannelEvent<Family>>(eventTarget: Component,
                                                                   channelId: String) throws -> Observable<T> {
        // TODO: Unsure about associatedUserId parameters. Is it really assigneeUserId?
        let channelTopic = try Topic.createTopicStringByLevelsForChannel(channelId: channelId,
                                                                         associatedUserId: eventTarget.assigneeUserId?.uuidString,
                                                                         sourceObject: nil,
                                                                         messageToken: nil)
        
        mqtt?.subscribe(channelTopic)
        
        return rawMessages.map(convertToTupleFormat)
            .filter({ (rawMessageTopic) -> Bool in
                let (topic, _) = rawMessageTopic
                return topic.channelId != nil
            })
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to channelId.
                let (topic, _) = rawMessageWithTopic
                return topic.channelId == channelId
            })
            .map({ (message) -> T in
                let (_, payload) = message
                
                // FIXME: Remove force unwrap.
                
                return PayloadCoder.decode(payload)!
            })
    }
    
    /// Observe Deadvertise events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Deadvertise events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///     - eventTarget: target for which Deadvertise events should be emitted
    /// - Returns:  a hot observable emitting incoming Deadvertise events
    public func observeDeadvertise(eventTarget: Component) throws -> Observable<DeadvertiseEvent<Deadvertise>> {
        let channelTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Deadvertise)
        
        mqtt?.subscribe(channelTopic)
        
        return rawMessages.map(convertToTupleFormat)
            .filter({ (rawMessageTopic) -> Bool in
                let (topic, _) = rawMessageTopic
                return topic.eventType == .Deadvertise
            })
            .map({ (message) -> DeadvertiseEvent<Deadvertise> in
                let (_, payload) = message
                
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
    }
    
}

// MARK: - CocoaMQTTDelegate methods.

/// TODO: Move extension to new file at some later point.
extension CommunicationManager: CocoaMQTTDelegate {
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnect : \(ack)")
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
        print("Subscribed to topic \(topic)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        /// FIXME: Not implemented yet.
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("Did disconnect with error.")
        updateCommunicationState(.offline)
    }
}


