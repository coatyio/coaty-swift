// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationClient.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

protocol CommunicationClient {
    /// Observable emitting *raw* (topic, payload) mqtt messages.
    var rawMQTTMessages: PublishSubject<(String, [UInt8])> { get }
    
    /// Observable emitting (topic, payload) values.
    var messages: PublishSubject<(String, String)> { get }
    
    /// MARK: - State management.
    var communicationState: BehaviorSubject<CommunicationState> { get }
    
    /// MARK: - pubsub methods.
    func connect()
    func disconnect()
    func unsubscribe(_ topic: String)
    func publish(_ topic: String, message: String)
    func subscribe(_ topic: String)
    func setWill(_ topic: String, message: String)
}
