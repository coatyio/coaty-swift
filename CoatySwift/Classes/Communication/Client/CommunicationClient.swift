//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationClient.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// This protocol defines the networking API of a communication client, such as
/// the `CocoaMQTTClient` class.
///
/// Note: We expect our clients to use publish-subscribe communication.
protocol CommunicationClient {
    
    /// Observable emitting *raw* (topic, payload) MQTT messages.
    var rawMQTTMessages: PublishSubject<(String, [UInt8])> { get }
    
    /// Observable emitting IoValue messages with *raw* payload.
    var ioValueMessages: PublishSubject<(String, [UInt8])> { get }
    
    /// Observable emitting (parsed topic, payload) values.
    var messages: PublishSubject<(CommunicationTopic, String)> { get }
    
    /// Delegate necessary to start the communication manager
    /// when discovering the broker over mDNS.
    var delegate: Startable { get }
    
    /// MARK: - State management.
    
    /// Emits online or offline state depending on the connection
    /// status of the client.
    var communicationState: BehaviorSubject<CommunicationState> { get }
    
    /// MARK: - Connection methods.
    
    func connect(lastWillTopic: String, lastWillMessage: String)
    func disconnect()

    /// MARK: - Pub-Sub methods.

    func publish(_ topic: String, message: String)
    func publish(_ topic: String, message: [UInt8])
    func subscribe(_ topic: String)
    func unsubscribe(_ topic: String)
}
