//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  CoatyTimeInterval.swift
//  CoatySwift
//

import Foundation

/// Defines a time interval using the number of milliseconds since the epoc in UTC
/// instead of ISO 8601 standard time intervals. This is used for consistency within
/// the system.
///
/// A valid interval can have four formats:
/// - start and end timestamps
/// - start timestamp and duration
/// - duration and end timestamp
/// - duration only
///
/// Four different initializers, one for each format case ensure that this object always has a correct format.
///
/// The ISO 8601 standard string can be created using the function `toLocalTimeIntervalIsoString`
/// which is a part of this class.
public class CoatyTimeInterval: Codable {
    
    // MARK: - Attributes.
    /// Start timestamp of the interval.
    /// Value represents the number of milliseconds since the epoc in UTC.
    ///
    /// This can be either used with end timestamp or a duration but not both.
    private let _start: Int?

    /// End timestamp of the interval.
    /// Value represents the number of milliseconds since the epoc in UTC.
    ///
    /// This can be either used with start timestamp or a duration but not both.
    private let _end: Int?

    /// Duration of the interval. Value represents the number of milliseconds.
    ///
    /// This can be either used with start or end timestamp but not both.
    private let _duration: Int?
    
    // MARK: - Initializers.
    /// 1. format case: start and end given
    public init(start: Int, end: Int) {
        self._start = start
        self._end = end
        
        self._duration = nil
    }
    
    /// 2. format case: start and duration
    public init(start: Int, duration: Int) {
        self._start = start
        self._duration = duration
        
        self._end = nil
    }
    
    /// 3. format case: duration and end
    public init(duration: Int, end: Int) {
        self._duration = duration
        self._end = end
        
        self._start = nil
    }
    
    /// 4. format case: duration
    public init(duration: Int) {
        self._duration = duration
        
        self._start = nil
        self._end = nil
    }
    
    // MARK: - Getters.
    var start: Int? {
        get {
            return self._start
        }
    }
    
    var end: Int? {
        get {
            return self._end
        }
    }
    
    var duration: Int? {
        get {
            return self._duration
        }
    }
    
    // MARK: - Public functions.
    /// Returns a string in ISO 8601 format for a time interval including timezone offset information.
    ///  - Parameters:
    ///     - interval: a TimeInterval object
    ///     - includeMillis: whether to include milliseconds in the string (defaults to false)
    public func toLocalIntervalIsoString(includeMillis: Bool? = false) -> String {
        if let duration = self._duration {
            var durationString: String
            do {
                durationString = try CoatyTimeInterval.toDurationIsoString(duration: duration)
            } catch _ {
                fatalError("duration cannot be a negative number")
            }
            if let start = self._start {
                return CoatyTimeInterval.toLocalIsoString(date: Date(timeIntervalSince1970: Double(start) / 1000.0), includeMilis: includeMillis) + "/" + durationString
            } else if let end = self._end {
                let date = Date(timeIntervalSince1970: Double(end))
                return durationString + "/" + CoatyTimeInterval.toLocalIsoString(date: date, includeMilis: includeMillis)
            } else {
                fatalError("Either start or end must be specified")
            }
        } else {
            let firstComponent = CoatyTimeInterval.toLocalIsoString(date: Date(timeIntervalSince1970: Double(self._start!)),
                                                                    includeMilis: includeMillis)
            let secondComponent = CoatyTimeInterval.toLocalIsoString(date: Date(timeIntervalSince1970: Double(self._end!)),
                                                                     includeMilis: includeMillis)
            return firstComponent + "/" + secondComponent
        }
    }
    
    /// Returns a string in ISO 8601 format for a duration.
    /// - Parameter duration: a duration given in milliseconds
    public static func toDurationIsoString(duration: Int) throws -> String {
        if duration < 0 {
            throw CoatySwiftError.RuntimeError("Duration cannot be negative.")
        }
        
        // Just return the duration in form of seconds.
        let inSeconds: Int = duration / 1000
        return "PT\(inSeconds)S"
    }
    
    /// Returns a string in ISO 8601 format including timezone offset information.
    /// - Parameters:
    ///     - date: a Date object
    ///     - includeMillis: whether to include milliseconds in the string (defaults to false)
    /// NOTE: This code has not been verified to always yield the correct representation of the date. Use with caution.
    public static func toLocalIsoString(date: Date, includeMilis: Bool? = false) -> String {
        if #available(iOS 11.0, *) {
            if includeMilis != nil, includeMilis! {
                let dateString = date.iso8601withFractionalSeconds
                return dateString
            } else {
                let dateString = date.iso8601withoutFractionalSeconds
                return dateString
            }
        } else {
            return "Unavailable"
        }
    }
}

// MARK: - Extensions needed by this class. Only available for certain iOS versions.
@available(iOS 10.0, *)
extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

@available(iOS 11.0, *)
extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
    static let iso8601withoutFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime])
}

@available(iOS 11.0, *)
extension Date {
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }
    var iso8601withoutFractionalSeconds: String { return Formatter.iso8601withoutFractionalSeconds.string(from: self) }
}

@available(iOS 11.0, *)
extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
    var iso8601withoutFractionalSeconds: Date? { return Formatter.iso8601withoutFractionalSeconds.date(from: self) }
}
