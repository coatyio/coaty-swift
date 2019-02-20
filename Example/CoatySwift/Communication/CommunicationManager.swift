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
    var mqtt: CocoaMQTT?
    
    // MARK: - RXSwift Disposebag.
    
    let disposeBack = DisposeBag()
    
    // MARK: - Observables.
    
    let operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .initial)
    let communicationState: BehaviorSubject<CommunicationState> = BehaviorSubject(value: .offline)
    
    /// Observable emitting raw (topic, payload) values.
    let rawMessages: PublishSubject<(String, String)> = PublishSubject<(String, String)>()
    
    /// Map holding topics and corresponding observables.
    /// FIXME: Currently it's only one observable per topic but technically there can be
    /// multiple ones.
    var observableMap = [String: Observable<CoatyObject>]()
    
    // MARK: - Convenience methods for accessing observable map.
    
    private func setObservable<T: CoatyObject>(topic: String, observable: Observable<T>) {
        observableMap[topic] = observable.map({ (coatyObject) -> CoatyObject in
            return coatyObject as CoatyObject
        })
    }
    
    private func getObservable<T: CoatyObject>(topic: String) -> Observable<T>? {
        if let observable = observableMap[topic] {
            return observable.map { (genericObject) -> T? in
                return genericObject as? T
            }.flatMap { Observable.from(optional: $0) }.asObservable()
        }
        return nil
    }
    
    private func createObservable<T: CoatyObject>() -> Observable<T> {
        return rawMessages.map {(rawMessage) -> T? in
            let (_, payload) = rawMessage
            
            // FIXME: Move to topic based matching. For debugging purposes, matching
            // types of messages for the moment.
            if let eventType: T = PayloadCoder.decode(payload) {
                return eventType
            }
            return nil
            
        }.flatMap { Observable.from(optional: $0) }.asObservable()
        
    }
    
    // MARK: - Observe methods.
    
    func observeAdvertise(topic: String) -> Observable<Advertise> {
        
        // TODO: Subscribe only if not already subscribed.
        mqtt!.subscribe(topic)
        
        // Check whether there is an already existing Observable for the topic.
        if let observable: Observable<Advertise> = getObservable(topic: topic) {
            return observable
        } else {
            // Create new one.
            let advertiseObservable: Observable<Advertise> = createObservable()
            setObservable(topic: topic, observable: advertiseObservable)
            
            return advertiseObservable
        }
    }
    
    // MARK: - Publish methods.
    
    /// Simplistic Advertise for debugging purposes.
    func publishAdvertise(topic: String, objectType: String, name: String) {
        let advertiseMessage = Advertise(coreType: .Component, objectType: objectType,
                                         objectId: .init(), name: name)
        let message = CocoaMQTTMessage(topic: topic, string: advertiseMessage.json)
        mqtt?.publish(message)
    }

    /// Simplistic AdvertiseIdentity for debugging purposes.
    func publishAdvertiseIdentity(topic: String) {
        let objectType = COATY_PREFIX + CoreType.Component.rawValue
        let advertiseIdentityMessage = Advertise(coreType: .Component,
                                                     objectType: objectType,
                                                 objectId: .init(), name: "CommunicationManager")
        let message = CocoaMQTTMessage(topic: topic, string: advertiseIdentityMessage.json)
        mqtt?.publish(message)
    }
    
    // MARK: - Init.
    
    public init() {
        brokerClientId = generateClientId()
        mqtt = CocoaMQTT(clientID: getBrokerClientId(), host: getHost(), port: getPort())
        configureBroker()
        
        
        // TODO: Find subscribers for operatingState and communicationState...
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
    
    /// FIXME: Hardcoded value.
    func getHost() -> String {
        return "192.168.1.120"
    }
    
    /// FIXME: Hardcoded value.
    func getPort() -> UInt16 {
        return UInt16(1883)
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
        print("Subscribed to topic \(topic).")
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
    

