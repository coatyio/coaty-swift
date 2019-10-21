//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationClient.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// This protocol defines the networking methods all of our clients have to
/// implement, such as the `CocoaMQTTClient` class.
///
/// Note: We expect our clients to work in a MQTT-like fashion.
protocol CommunicationClient {
    
    /// Observable emitting *raw* (topic, payload) mqtt messages.
    var rawMQTTMessages: PublishSubject<(String, [UInt8])> { get }
    
    /// Observable emitting (topic, payload) values.
    var messages: PublishSubject<(String, String)> { get }
    
    /// Delegate necessary to start the communication manager
    /// when discovering the broker over mDNS.
    var delegate: Startable? { get set }
    
    /// MARK: - State management.
    
    /// Emits the online or offline state depending on the connection
    /// status of the client.
    var communicationState: BehaviorSubject<CommunicationState> { get }
    
    /// MARK: - Pubsub methods.
    
    func connect()
    func disconnect()
    func publish(_ topic: String, message: String)
    func subscribe(_ topic: String)
    func unsubscribe(_ topic: String)
    func setWill(_ topic: String, message: String)
}
