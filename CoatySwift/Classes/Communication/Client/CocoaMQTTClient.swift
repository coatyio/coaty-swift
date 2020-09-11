//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CocoaMQTTClient.swift
//  CoatySwift
//
//

import Foundation
import CocoaMQTT
import RxSwift
import XCGLogger

/// Default MQTT client for networking.
internal class CocoaMQTTClient: CommunicationClient, CocoaMQTTDelegate {
    
   
    private let log = LogManager.log
    
    // MARK: - Protocol fields.
    
    var rawMQTTMessages = PublishSubject<(String, [UInt8])>()
    var ioValueMessages = PublishSubject<(String, [UInt8])>()
    var messages = PublishSubject<(CommunicationTopic, String)>()
    var communicationState = BehaviorSubject(value: CommunicationState.offline)
    var delegate: Startable
    var brokerCandidates = [String]()
    var brokerPort: UInt16 = 1883

    /// CocoaMQTT MQTT client.
    private var mqtt: CocoaMQTT!
    private var discovery: BonjourResolver?
    private var qos: CocoaMQTTQOS!
    
    // MARK: - Initializer.
    
    init(mqttClientOptions: MQTTClientOptions, delegate: Startable) {
        self.delegate = delegate
        configure(mqttClientOptions)

        if mqttClientOptions.shouldTryMDNSDiscovery {
            discovery = BonjourResolver()
            discovery?.delegate = self
            discovery?.startDiscovery()
        }
    }
    
    // MARK: - Helper methods.
    
    private func configure(_ mqttClientOptions: MQTTClientOptions) {
        // Configure mqtt client.
        mqtt = CocoaMQTT(clientID: mqttClientOptions.clientId!,
                         host: mqttClientOptions.host,
                         port: UInt16(mqttClientOptions.port))
        mqtt.delegate = self
        mqtt.keepAlive = mqttClientOptions.keepAlive
        mqtt.allowUntrustCACertificate = mqttClientOptions.allowUntrustCACertificate
        mqtt.enableSSL = mqttClientOptions.enableSSL
        mqtt.autoReconnect = mqttClientOptions.autoReconnect
        mqtt.autoReconnectTimeInterval = UInt16(mqttClientOptions.autoReconnectTimeInterval)
        
        // Determines whether to keep session information and subscriptions
        // while client is not connected and resubscribe them after reconnection.
        // Since we manage deferred subscriptions in the communication manager,
        // the value must always be `true`.
        mqtt.cleanSession = true
        mqtt.username =  mqttClientOptions.username
        mqtt.password = mqttClientOptions.password
        mqtt.logLevel = mqttClientOptions.shouldLog ? .debug : .off
        // delegate queue for dispatching (default is DispatchQueue.main)
        // mqtt.dispatchQueue = DispatchQueue.global(qos: .userInitiated)

        switch mqttClientOptions.qos {
            case 1: self.qos = .qos1
            case 2: self.qos = .qos2
            default: self.qos = .qos0
        }
    }
    
    // MARK: - Communication methods.
    
    func connect(lastWillTopic: String, lastWillMessage: String) {
        let willMessage = CocoaMQTTWill(topic: lastWillTopic, message: lastWillMessage)
        willMessage.qos = self.qos
        mqtt.willMessage = willMessage
        
        if mqtt.connState != .connected && mqtt.connState != .connecting {
            log.debug("Connecting to broker host \(mqtt.host) on port \(mqtt.port)")
            _ = mqtt.connect()
        }
    }
    
    private func connectNext() {
        if mqtt.connState != .connected && mqtt.connState != .connecting {
            log.debug("Connecting to next broker host \(mqtt.host) on port \(mqtt.port)")
            _ = mqtt.connect()
        }
    }
    
    func disconnect() {
        mqtt.disconnect()
    }
    
    func publish(_ topic: String, message: String) {
        mqtt.publish(topic, withString: message, qos: self.qos)
    }
    
    func publish(_ topic: String, message: [UInt8]) {
        let message = CocoaMQTTMessage(topic: topic, payload: message, qos: .qos0, retained: false, dup: false)
        mqtt.publish(message)
    }
    
    func subscribe(_ topic: String) {
        mqtt.subscribe(topic, qos: self.qos)
    }
    
    func unsubscribe(_ topic: String) {
        mqtt.unsubscribe(topic)
    }
    
    // MARK: - State management methods.
    
    func updateCommunicationState(_ state: CommunicationState) {
        communicationState.onNext(state)
    }
    
    // MARK: - CocoaMQTT Delegate methods.
    // see https://github.com/emqx/CocoaMQTT/blob/1.2.5/Source/CocoaMQTT.swift
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            updateCommunicationState(.online)
        } else {
            // Any other CocoaMQTTConnAck value signals an error.
            log.debug("Connection error: \(ack)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if CommunicationTopic.isRawTopic(topic: message.topic) {
            rawMQTTMessages.onNext((message.topic, message.payload))
            return
        }
        
        do {
            let topic = try CommunicationTopic(message.topic)
            if topic.eventType == .IoValue {
                ioValueMessages.onNext((message.topic, message.payload))
            } else if let payloadString = message.string {
                messages.onNext((topic, payloadString))
            }
        } catch {
            log.debug("Ignoring incoming event on \(message.topic): \(error)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        log.debug("Subscribed to topics \(topics).")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        log.debug("Unsubscribed from topic \(topic).")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        updateCommunicationState(.offline)
        
        if err != nil {
            log.debug("Did disconnect with error: \(err!.localizedDescription).")
        } else {
            log.debug("Did disconnect.")
        }
        
        if !brokerCandidates.isEmpty {
            mqtt.host = brokerCandidates.removeFirst()
            mqtt.port = brokerPort
            self.connectNext()
        }
    }
}

extension CocoaMQTTClient: BonjourResolverDelegate {
    
    func didReceiveService(addresses: [String], port: Int) {
        discovery?.stopDiscovery()

        brokerCandidates.append(contentsOf: addresses)
        brokerPort = UInt16(port)

        mqtt.host = brokerCandidates.removeFirst()
        mqtt.port = brokerPort

        delegate.didReceiveStart()
    }
}
