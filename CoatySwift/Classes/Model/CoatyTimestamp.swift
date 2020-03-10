//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyDate.swift
//  CoatySwift
//

import Foundation

/// Utility functions to cope with the Coaty compatible timestamp format. In
/// Coaty, a timestamp defines the number of milliseconds elapsed since January
/// 1, 1970, 00:00:00 UTC. In Swift, a Coaty timestamp should be represented as
/// a `Double` value.
public struct CoatyTimestamp {

    /// Gets the Coaty compatible timestamp for the current date.
    ///
    /// - Returns: a Coaty timestamp representing number of milliseconds elapsed
    ///   since January 1, 1970, 00:00:00 UTC, as a Double value.
    public static func nowMillis() -> Double {
        return Date().timeIntervalSince1970 * 1000
    }

    /// Gets the Coaty compatible timestamp for the given `Date`.
    ///
    /// - Returns: a Coaty timestamp representing number of milliseconds elapsed
    ///   since January 1, 1970, 00:00:00 UTC for the given `Date`, as a Double
    ///   value.
    public static func dateMillis(from: Date)-> Double {
        return from.timeIntervalSince1970 * 1000
    }

    /// Gets the `Date` for the given Coaty compatible timestamp.
    ///
    /// - Returns: a `Date` that represents the given Coaty timestamp
    ///   representing number of milliseconds elapsed since January 1, 1970,
    ///   00:00:00 UTC, as a Double value.
    public static func date(from: Double) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(from) / 1000)
    }
}
