//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
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
    
    private let log = LogManager.log
    
    // MARK: - Protocol fields.
    
    var rawMQTTMessages = PublishSubject<(String, [UInt8])>()
    var messages = PublishSubject<(String, String)>()
    var communicationState = BehaviorSubject(value: CommunicationState.offline)
    var delegate: Startable?
    var brokerCandidates = [String]()
    var brokerPort: UInt16 = 1883

    /// CocoaMQTT MQTT client.
    private var mqtt: CocoaMQTT!
    private var discovery: BonjourResolver?
    
    // MARK: - Initializer.
    
    init(communicationOptions: CommunicationOptions) {
        let mqttClientOptions = communicationOptions.mqttClientOptions!
        if mqttClientOptions.shouldTryMDNSDiscovery {
            discovery = BonjourResolver()
            discovery?.delegate = self
            discovery?.startDiscovery()
        }
        
        configure(mqttClientOptions)
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
        mqtt.allowUntrustCACertificate = mqttClientOptions.allowUntrustCACertificate
        mqtt.enableSSL = mqttClientOptions.enableSSL
        mqtt.autoReconnect = mqttClientOptions.autoReconnect
        mqtt.autoReconnectTimeInterval = UInt16(mqttClientOptions.autoReconnectTimeInterval)
        mqtt.delegate = self
    }
    
    // MARK: - Communication client methods.
    
    func connect() {
        if (mqtt.connState != .connected && mqtt.connState != .connecting ) {
            mqtt.connect()
        }
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
        discovery?.stopDiscovery()
        delegate?.didReceiveStart()
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
        
        if !brokerCandidates.isEmpty {
            
            mqtt.host = brokerCandidates.removeFirst()
            mqtt.port = brokerPort
            
            connect()
        }
    }
}

extension CocoaMQTTClient: BonjourResolverDelegate {
    
    func didReceiveService(addresses: [String], port: Int) {
        brokerCandidates.append(contentsOf: addresses)
        brokerPort = UInt16(port)
        
        mqtt.host = brokerCandidates.removeFirst()
        mqtt.port = brokerPort
        
        connect()
    }
}
