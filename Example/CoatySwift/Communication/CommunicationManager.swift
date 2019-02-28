//
//  CommunicationManager.swift
//  CoatySwift
//
//

import Foundation
import CocoaMQTT
import RxSwift

class CommunicationManager {
    
    // MARK: - Variables.
    
    private var brokerClientId: String?
    private var disposeBag = DisposeBag()
    private let protocolVersion = 1
    private var identity: CoatyObject? // TODO: This should probably be of type Component.
    var mqtt: CocoaMQTT?
    
    // MARK: - RXSwift Disposebag.
    
    let disposeBack = DisposeBag()
    
    // MARK: - Observables.
    
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)
    
    /// Observable emitting raw (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()

    // MARK: - Observe methods.
    
    /// TODO: Checking of eventTarget fields.
    /// This method should not be called directly, use observeAdvertiseWithCoreType method
    /// or observeAdvertiseWithObjectType method instead.
    /// - Parameters:
    ///     - topic: TODO: Meaningful description?
    ///     - eventTarget: Usually, your identity.
    ///     - coreType: observed coreType.
    ///     - objectType: observed objectType.
    private func observeAdvertise<S: CoatyObject, T: AdvertiseEvent<S>>(topic: String,
                                  eventTarget: CoatyObject,
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
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - coreType: coreType core type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted coreType.
    func observeAdvertiseWithCoreType<S: CoatyObject, T: AdvertiseEvent<S>>(eventTarget: CoatyObject,
                                                                          coreType: CoreType) throws -> Observable<T> {
       
        let topic = Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: coreType.rawValue)
        let observable: Observable<T> = try observeAdvertise(topic: topic, eventTarget: eventTarget,
                                                             coreType: coreType, objectType: nil)
        return observable
    }
    
    /// Observes advertises with a particular objectType.
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - objectType: objectType object type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted objectType.
    func observeAdvertiseWithObjectType<S: CoatyObject, T: AdvertiseEvent<S>>(eventTarget: CoatyObject,
                                                                            objectType: String) throws -> Observable<T> {

        let topic = Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: objectType)
        let observable: Observable<T> = try observeAdvertise(topic: topic, eventTarget: eventTarget,
                                                             coreType: nil, objectType: objectType)
        return observable
    }
    
    // TODO: Implement me.
    func observeChannel(eventTarget: CoatyObject, channelId: String) {
        
    }
    
    // MARK: - Publish methods.
    
    /// Publishes a given advertise event.
    /// TODO: eventTarget is NOT part of the original coat implementation, remove it ASAP.
    /// - Parameters:
    ///     - advertiseEvent: The event that should be advertised.
    ///     - eventTarget: (OBSOLETE!) Identity object,
    func publishAdvertise<S: CoatyObject,T: AdvertiseEvent<S>> (advertiseEvent: T,
                                                                  eventTarget: CoatyObject) throws {
        
        let topicForObjectType = Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                    eventTypeFilter: advertiseEvent.eventData.object.objectType,
                                                    associatedUserId: "-",
                                                    sourceObject: eventTarget,
                                                    messageToken: UUID.init().uuidString
                                                    )
        let topicForCoreType = Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                        eventTypeFilter: advertiseEvent.eventData.object.coreType.rawValue,
                                        associatedUserId: "-",
                                        sourceObject: eventTarget,
                                        messageToken: UUID.init().uuidString
                                        )

        // Publish the advertise for core AND object type.
        publish(topic: topicForCoreType, message: advertiseEvent.json)
        publish(topic: topicForObjectType, message: advertiseEvent.json)
    }

    /// Advertises the identity of a CommunicationManager.
    /// TODO: Re-use the implementation of publishAdvertise. Currently not possible because of
    /// missing topic creations.
    func publishAdvertiseIdentity(eventTarget: CoatyObject) throws {
        guard let identity = self.identity else {
            // TODO: Handle error.
            return
        }
        
        let advertiseIdentityEvent = try AdvertiseEvent.withObject(eventSource: identity,
                                                                   object: identity,
                                                                   privateData: nil)
      
        try publishAdvertise(advertiseEvent: advertiseIdentityEvent, eventTarget: identity)
    }
    
    
    // MARK: - Init.
    
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
                try? self.publishAdvertiseIdentity(eventTarget: self.identity!)
            }.disposed(by: disposeBag)
    }
    
    // TODO: This should most likely return a Component object in the future.
    public func initIdentity() {
        let objectType = COATY_PREFIX + CoreType.Component.rawValue
        identity = CoatyObject(coreType: .Component,
                                  objectType: objectType,
                                  objectId: .init(), name: "CommunicationManager")
    }
    
    // MARK: - Broker methods.
    
    private func configureBroker() {
        mqtt?.keepAlive = 60
        mqtt?.allowUntrustCACertificate = true
        mqtt?.delegate = self
        
        // FIXME: Correct will format.
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
    
    func endClient() {
        updateOperatingState(.stopping)
        disconnect()
        updateOperatingState(.stopped)
    }
    
    // MARK: - Setup methods.
    
    // FIXME: Copy will implementation from Coaty.
    func setLastWill() {
        mqtt?.willMessage = CocoaMQTTWill(topic: "TEST", message: "TEST")
        
    }
    
    /// Generates COATY Client ID.
    /// TODO: Validation missing. Adjust to specified format.
    func generateClientId() -> String {
        return "COATY-\(UUID.init())"
    }
    
    /// Note: In case there was no brokerClientId before, it is set.
    func getBrokerClientId() -> String {
        if let brokerClientId = brokerClientId {
            return brokerClientId
        }
        brokerClientId = generateClientId()
        return brokerClientId!
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

// MARK: CocoaMQTTDelegate methods.
// TODO: Move extension to new file at some later point.

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
    

