//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Util.swift
//  CoatySwift_Example
//
//

import Foundation

internal enum Direction {
    case In
    case Out
}

/// Pretty printing for event flow.
///
/// - Parameters:
///   - message: the text that is displayed as description.
///   - eventName: typically the core type.
///   - eventDirection: either in or out.
internal func logConsole(message: String, eventName: String, eventDirection: Direction = .In) {
    let direction = eventDirection == .Out ? "<-" : "->"
    print("\(direction) \(eventName) \t| \(message)")
}
