//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  LogManager.swift
//  CoatySwift
//
//

import Foundation
import XCGLogger

/// Provides a global logger for the CoatySwift framework.
class LogManager {
    
    internal static var logLevel = XCGLogger.Level.error
    
    internal static let log: XCGLogger = {
        let log = XCGLogger(identifier: "CoatySwift",
                               includeDefaultDestinations: false)
        
        let systemDestination = AppleSystemLogDestination(identifier: "CoatySwift.systemDestination")
        systemDestination.outputLevel = LogManager.logLevel
        systemDestination.showLogIdentifier = true
        systemDestination.showFunctionName = false
        systemDestination.showThreadName = false
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = true
        
        log.add(destination: systemDestination)
        log.logAppDetails()
        
        return log
    }()
    
    static internal func getLogLevel(logLevel: CoatySwiftLogLevel) -> XCGLogger.Level {
        switch logLevel {
        case .debug:
            return XCGLogger.Level.debug
        case .error:
            return XCGLogger.Level.error
        case .info:
            return XCGLogger.Level.info
        case .warning:
            return XCGLogger.Level.warning
        }
    }
}

/// The `CoatySwiftLogLevel` enum defines the verbositiy of the internal CoatySwift logger.
public enum CoatySwiftLogLevel {
    
    /// Logs information about underlying MQTT topic subscriptions (e.g. subscribe() and unsubscribe() operations).
    case debug
    
    /// Logs events such as onCommunicationManagerStarting() or onContainerResolved().
    case info
    
    /// Logs warnings that indicate partial failures which may indicate larger issues.
    case warning
    
    /// Logs fatal errors such as decoding failures.
    case error
}

