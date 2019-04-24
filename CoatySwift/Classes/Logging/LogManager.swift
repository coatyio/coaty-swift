//
//  LogManager.swift
//  CoatySwift
//
//

import Foundation
import XCGLogger

/// Provides a global logger for the CoatySwift framework.
class LogManager {
    
    internal static let log: XCGLogger = {
        let log = XCGLogger(identifier: "CoatySwift",
                               includeDefaultDestinations: false)
        
        let systemDestination = AppleSystemLogDestination(identifier: "CoatySwift.systemDestination")
        systemDestination.outputLevel = .info
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
}

