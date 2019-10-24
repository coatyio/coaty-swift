//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Log.swift
//  CoatySwift
//
//

import Foundation

/// Represents a log object.
open class Log: CoatyObject {
    
    // MARK: - Attributes.

    /// The level of logging.
    public var logLevel: LogLevel

    /// The message to log.
    public var logMessage: String

    /// Timestamp string in ISO 8601 format (with or without timezone offset).
    public var logDate: String

    /// Represents a series of tags assigned to this Log object (optional).
    /// Tags are used to categorize or filter log output.
    /// Agents may introduce specific tags, such as "service" or "app".
    ///
    /// Log objects published by the framework itself always use the reserved
    /// tag named "coaty" as part of the `logTags` property. This tag should
    /// never be used by agent projects.
    public var logTags: [String]?

    /// Information about the host environment in which this log object is
    /// created (optional).
    ///
    /// Typically, this information is just send once as part of an initial
    /// advertised log event. Further log records need not specify this
    /// information because it can be correlated automatically by the event
    /// source ID.
    public var logHost: LogHost?
    
    // MARK: Initializers.
    
    public init(logLevel: LogLevel,
                logMessage: String,
                logDate: String,
                name: String = "LogObject",
                objectType: String = "\(COATY_OBJECT_TYPE_NAMESPACE_PREFIX)\(CoreType.Log)",
                objectId: CoatyUUID = .init(),
                logTags: [String]? = nil,
                logHost: LogHost? = nil) {
        self.logLevel = logLevel
        self.logMessage = logMessage
        self.logDate = logDate
        self.logTags = logTags
        self.logHost = logHost
        super.init(coreType: .Log, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.

    enum LogHostKeys: String, CodingKey {
        case logLevel
        case logMessage
        case logDate
        case logTags
        case logHost
    }
       
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LogHostKeys.self)
        self.logLevel = try container.decode(LogLevel.self, forKey: .logLevel)
        self.logMessage = try container.decode(String.self, forKey: .logMessage)
        self.logDate = try container.decode(String.self, forKey: .logDate)
        self.logTags = try container.decodeIfPresent([String].self, forKey: .logTags)
        self.logHost = try container.decodeIfPresent(LogHost.self, forKey: .logHost)
        try super.init(from: decoder)
    }
       
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: LogHostKeys.self)
        try container.encode(logLevel, forKey: .logLevel)
        try container.encode(logMessage, forKey: .logMessage)
        try container.encode(logDate, forKey: .logDate)
        try container.encodeIfPresent(logTags, forKey: .logTags)
        try container.encodeIfPresent(logHost, forKey: .logHost)
    }
    
}

/// Information about the host environment in which a Log object is created.
/// This information should only be logged once by each agent,
/// e.g. initially at startup.
public class LogHost: Codable {
    
    // MARK: - Attributes.

    /// Package and build information of the agent that logs.
    public var agentInfo: AgentInfo?

    /// Process ID of the application that generates a log record (optional).
    /// May be specified by Node.js applications.
    public var pid: Double?

    /// Hostname of the application that generates a log record (optional).
    /// May be specified by Node.js applications.
    public var hostname: String?

    /// Hostname of the application that generates a log record (optional).
    /// May be specified by browser or cordova applications.
    public var userAgent: String?
    
    // MARK: - Initializers.
    
    public init(agentInfo: AgentInfo? = nil, pid: Double? = nil, hostname: String? = nil, userAgent: String? = nil) {
        self.agentInfo = agentInfo
        self.pid = pid
        self.hostname = hostname
        self.userAgent = userAgent
    }

    // MARK: - Codable methods.

    enum LogHostKeys: String, CodingKey {
        case agentInfo
        case pid
        case hostname
        case userAgent
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LogHostKeys.self)
        self.agentInfo = try container.decodeIfPresent(AgentInfo.self, forKey: .agentInfo)
        self.pid = try container.decodeIfPresent(Double.self, forKey: .pid)
        self.hostname = try container.decodeIfPresent(String.self, forKey: .hostname)
        self.userAgent = try container.decodeIfPresent(String.self, forKey: .userAgent)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: LogHostKeys.self)
        try container.encodeIfPresent(agentInfo, forKey: .agentInfo)
        try container.encodeIfPresent(pid, forKey: .pid)
        try container.encodeIfPresent(hostname, forKey: .hostname)
        try container.encodeIfPresent(userAgent, forKey: .userAgent)
    }

}

/// Predefined logging levels ordered by a numeric value.
public enum LogLevel: Int, Codable {

    /// Fine-grained statements concerning program state, Typically only
    /// interesting for developers and used for debugging.
    case debug = 10

    /// Informational statements concerning program state, representing program
    /// events or behavior tracking. Typically interesting for support staff
    /// trying to figure out the context of a given error.
    case info = 20

    /// Statements that describe potentially harmful events or states in the
    /// program. Typically interesting for support staff trying to figure out
    /// potential causes of a given error.
    case warning = 30

    /// Statements that describe non-fatal errors in the application; this level
    /// is used quite often for logging handled exceptions.
    case error = 40

    /// Statements representing the most severe of error conditions, assumedly
    /// resulting in program termination. Typically used by unhandled exception
    /// handlers before terminating a program.
    case fatal = 50
}
