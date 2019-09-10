// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CocoaMQTTClient.swift
//  CoatySwift
//
//

import Foundation
import CocoaMQTT
import RxSwift

/// Default MQTT client for networking.
internal class CocoaMQTTClient: CommunicationClient, CocoaMQTTDelegate {
    
    // MARK: - Logger.
    
    internal let log = LogManager.log
    
    // MARK: - Protocol fields.
    
    var rawMQTTMessages = PublishSubject<(String, [UInt8])>()
    var messages = PublishSubject<(String, String)>()
    var communicationState = BehaviorSubject(value: CommunicationState.offline)

    /// CocoaMQTT MQTT client.
    internal var mqtt: CocoaMQTT!
    
    // MARK: - Initializer.
    
    init(communicationOptions: CommunicationOptions) {
        let mqttClientOptions = communicationOptions.mqttClientOptions!
        configure(mqttClientOptions)
        
        // TODO: Missing mDNS discovery.
    }
    
    // MARK: - Helper methods.
    
    private func configure(_ mqttClientOptions: MQTTClientOptions) {
        // Setup client Id.
        let clientId = "COATY-\(mqttClientOptions.clientId)"
        
        // Configure mqtt client.
        mqtt = CocoaMQTT(clientID: clientId,
                         host: mqttClientOptions.host,
                         port: UInt16(mqttClientOptions.port))
        
        mqtt.keepAlive = mqttClientOptions.keepAlive
        
        // TODO: Make this configurable.
        mqtt.allowUntrustCACertificate = true
        mqtt.enableSSL = mqttClientOptions.enableSSL
        mqtt.autoReconnect = mqttClientOptions.autoReconnect
        
        // TODO: Make this configurable.
        mqtt.autoReconnectTimeInterval = 3 // seconds.
        mqtt.delegate = self
    }
    
    // MARK: - Communication client methods.
    
    func connect() {
        mqtt.connect()
    }
    
    func disconnect() {
        mqtt.disconnect()
    }
    
    
    func publish(_ topic: String, message: String) {
        mqtt.publish(topic, withString: message)
    }
    
    func subscribe(_ topic: String) {
        mqtt.subscribe(topic)
    }
    
    func unsubscribe(_ topic: String) {
        mqtt.unsubscribe(topic)
    }
    
    func setWill(_ topic: String, message: String) {
        mqtt.willMessage = CocoaMQTTWill(topic: topic, message: message)
    }
    
    // MARK: - State management methods.
    
    func updateCommunicationState(_ state: CommunicationState) {
        communicationState.onNext(state)
    }
    
    // MARK: - CocoaMQTT Delegate methods.
    
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
            messages.onNext((message.topic, payloadString))
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
