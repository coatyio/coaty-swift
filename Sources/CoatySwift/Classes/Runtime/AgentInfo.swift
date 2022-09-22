//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  AgentInfo.swift
//  CoatySwift
//

import Foundation

/// Represents package, build and release information about a Coaty agent.
///
/// Agent information is generated when the agent project is build and can be
/// used at run time, e.g. for logging, display, or configuration.
public class AgentInfo: Codable {
    
    // MARK: - Attributes.
    
    /// Represents information about the agent's package.
    public var packageInfo: AgentPackageInfo
    
    /// Represents information about agent build.
    public var buildInfo: AgentBuildInfo
    
    /// Represents information about agent configuration.
    public var configInfo: AgentConfigInfo
    
    // MARK: - Initializers.
    
    /// Create a new instance of AgentInfo.
    public init(packageInfo: AgentPackageInfo, buildInfo: AgentBuildInfo, configInfo: AgentConfigInfo) {
        self.packageInfo = packageInfo
        self.buildInfo = buildInfo
        self.configInfo = configInfo
    }
    
    // MARK: Codable methods.
    
    enum AgentInfoKeys: String, CodingKey {
        case packageInfo
        case buildInfo
        case configInfo
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AgentInfoKeys.self)
        self.packageInfo = try container.decode(AgentPackageInfo.self, forKey: .packageInfo)
        self.buildInfo = try container.decode(AgentBuildInfo.self, forKey: .buildInfo)
        self.configInfo = try container.decode(AgentConfigInfo.self, forKey: .configInfo)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AgentInfoKeys.self)
        try container.encode(packageInfo, forKey: .packageInfo)
        try container.encode(buildInfo, forKey: .buildInfo)
        try container.encode(configInfo, forKey: .configInfo)
    }
}

/// Represents information about the agent's package, such as Swift package format or Cocoapods.
public class AgentPackageInfo: Codable {
    
    // MARK: - Attributes.
    
    /// The agent package name
    public var name: String
    
    /// The agent package version
    public var version: String
    
    /// Any other package-specific properties accessible by indexer
    public var extra = [String: Any]()
    
    // MARK: - Initializers.
    
    /// Create a new instance of AgentPackageInfo.
    public init(name: String, version: String, extra : [String: Any]? = nil) {
        self.name = name
        self.version = version
        if let extra = extra {
            self.extra = extra
        }
    }
    
    // MARK: - Codable methods.
    
    enum AgentPackageInfoKeys: String, CodingKey {
        case name
        case version
        case extra
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AgentPackageInfoKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.version = try container.decode(String.self, forKey: .version)
        self.extra = try container.decode([String: Any].self, forKey: .extra)
    }
       
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AgentPackageInfoKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(version, forKey: .version)
        try container.encode(extra, forKey: .extra)
    }
    
}

/// Represents information about agent build.
public class AgentBuildInfo: Codable {
    
    // MARK: - Attributes.
    
    /// The build date of the agent project.
    ///
    /// The value should be formatted according to ISO 8601.
    public var buildDate: String
    
    /// The build mode of the agent project. Determines whether the agent is
    /// built for a production, development, staging, testing, or any other
    /// custom build environment.
    public var buildMode: String
    
    /// Any other build-specific properties accessible by indexer
    public var extra = [String: Any]()
    
    // MARK: - Initializers.
    
    /// Create a new instance of AgentBuildInfo.
    public init(buildDate: String, buildMode: String, extra : [String: Any]? = nil) {
        self.buildDate = buildDate
        self.buildMode = buildMode
        if let extra = extra {
            self.extra = extra
        }
    }
    
    // MARK: - Codable methods.
    
    enum AgentBuildInfoKeys: String, CodingKey {
        case buildDate
        case buildMode
        case extra
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AgentBuildInfoKeys.self)
        self.buildMode = try container.decode(String.self, forKey: .buildMode)
        self.buildDate = try container.decode(String.self, forKey: .buildDate)
        self.extra = try container.decode([String: Any].self, forKey: .extra)
    }
       
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AgentBuildInfoKeys.self)
        try container.encode(buildMode, forKey: .buildMode)
        try container.encode(buildDate, forKey: .buildDate)
        try container.encode(extra, forKey: .extra)
    }
}

/// Represents information about agent configuration.
public class AgentConfigInfo: Codable {
    
    // MARK: - Attributes,
    
    /// The host name used for MQTT broker connections and REST based
    /// services (optional).
    ///
    /// If not set the value defaults to an empty string.
    public var serviceHost: String
    
    /// Any other config-specific properties accessible by indexer
    public var extra = [String: Any]()
    
    // MARK: - Initializers.
    
    /// Create a new instance of AgentConfigInfo.
    public init(serviceHost: String, extra : [String: Any]? = nil) {
        self.serviceHost = serviceHost
        if let extra = extra {
            self.extra = extra
        }
    }
    
    // MARK: - Codable methods.
    
    enum AgentConfigInfoKeys: String, CodingKey {
        case serviceHost
        case extra
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AgentConfigInfoKeys.self)
        self.serviceHost = try container.decode(String.self, forKey: .serviceHost)
        self.extra = try container.decode([String: Any].self, forKey: .extra)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AgentConfigInfoKeys.self)
        try container.encode(serviceHost, forKey: .serviceHost)
        try container.encode(extra, forKey: .extra)
    }
}
