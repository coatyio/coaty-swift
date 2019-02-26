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
    var mqtt: CocoaMQTT?
    
    
    // MARK: - RXSwift Disposebag.
    
    let disposeBack = DisposeBag()
    
    // MARK: - Observables.
    
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)
    
    /// Observable emitting raw (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()
    
    /// Map holding topics and corresponding observables listening to these topics.
    var observableMap = [String: Observable<CoatyObject>]()
    
    // MARK: - Convenience methods for accessing observable map.
    
    /// Creates an observable listening to a specific type of event, e.g. Advertise.
    private func createObservable<T: CoatyObject>() -> Observable<T> {
        
        return rawMessages.map {(rawMessage) -> T? in
            let (_, rawMessagePayload) = rawMessage
            if let eventType: T = PayloadCoder.decode(rawMessagePayload) {
                return eventType
            }
            return nil
            
            }.flatMap { Observable.from(optional: $0) }.asObservable()
        
    }
    
    /// Saves an observable and the corresponding topic to the observable map.
    private func setObservable<T: CoatyObject>(topic: String, observable: Observable<T>) {
        observableMap[topic] = observable.map({ (coatyObject) -> CoatyObject in
            return coatyObject as CoatyObject
        })
    }
    
    /// Gets the observable based on the given topic.
    private func getObservable<T: CoatyObject>(topic: String) -> Observable<T>? {
        if let observable = observableMap[topic] {
            return observable.map { (genericObject) -> T? in
                return genericObject as? T
            }.flatMap { Observable.from(optional: $0) }.asObservable()
        }
        return nil
    }
    
    // MARK: - Observe methods.
    
    /// TODO: Checking of eventTarget fields.
    /// TODO: Topic should use the convenience methods of Topic.swift rather than String.
    /// This method should not be called directly, use observeAdvertiseWithCoreType method
    /// or observeAdvertiseWithObjectType method instead.
    private func observeAdvertise<T: Advertise>(topic: String,
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
        
        var returnedObservable: Observable<T>
            // Check whether there is an already existing Observable for the topic.
            if let observable: Observable<T> = getObservable(topic: topic) {
                returnedObservable = observable
            } else {
                // Create new one.
                let advertiseObservable: Observable<T> = createObservable()
                setObservable(topic: topic, observable: advertiseObservable)
                returnedObservable = advertiseObservable
            }
        
        // Perform filtering.
        return returnedObservable.filter { $0.objectType == objectType || $0.coreType == coreType}

    }
    
    func observeAdvertiseWithCoreType<T: Advertise>(eventTarget: CoatyObject,
                                      coreType: CoreType) throws -> Observable<T> {
        // TODO: Create correct topic structure, similar to CommunicationTopic.createByLevels()
        let topic = "/coaty/+/Advertise:\(coreType.rawValue)/+/+/+/"
        
        return try observeAdvertise(topic: topic, eventTarget: eventTarget,
                                    coreType: coreType, objectType: nil)
    }
    
    func observeAdvertiseWithObjectType<T: Advertise>(eventTarget: CoatyObject,
                                                      objectType: String) throws -> Observable<T> {
             // TODO: Create correct topic structure, similar to CommunicationTopic.createByLevels()
            let topic = "/coaty/+/Advertise::\(objectType)/+/+/+/"
        
            return try observeAdvertise(topic: topic, eventTarget: eventTarget,
                                        coreType: nil, objectType: objectType)
    }
    
    // TODO: Implement me.
    func observeChannel(eventTarget: CoatyObject, channelId: String) {
        
    }
    
    // MARK: - Publish methods.
    
    /// Advertises an object.
    func publishAdvertise(eventTarget: CoatyObject, objectType: String) throws {
        
        // TODO: Topic creation factory missing.
        let topic = try Topic.init(protocolVersion: protocolVersion, event: "Advertise::\(objectType)",
                                   associatedUserId: "-",
                                   sourceObjectId: "\(eventTarget.objectId)",
                                   messageToken: "-")
        
        let advertiseMessage = Advertise(coreType: .Component, objectType: objectType,
                                         objectId: .init(), name: eventTarget.name)
        let message = CocoaMQTTMessage(topic: topic.string, string: advertiseMessage.json)
        mqtt?.publish(message)
    }

    /// Advertises the identity.
    func publishAdvertiseIdentity(eventTarget: CoatyObject) throws {
        
        // TODO: Topic creation factory missing.
        let topic = try Topic.init(protocolVersion: protocolVersion, event: "Advertise:Component",
                                   associatedUserId: "-",
                                   sourceObjectId: "\(eventTarget.objectId)",
                                   messageToken: "-")
        
        let objectType = COATY_PREFIX + CoreType.Component.rawValue
        let advertiseIdentityMessage = Advertise(coreType: .Component,
                                                 objectType: objectType,
                                                 objectId: .init(), name: "CommunicationManager")
        let message = CocoaMQTTMessage(topic: topic.string, string: advertiseIdentityMessage.json)
        mqtt?.publish(message)
        
    }
    
    // MARK: - Init.
    
    public init(host: String, port: Int) {
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
    

