//
//  AgentInfo.swift
//  CoatySwift
//

import Foundation

/**
 * Represents package, build and config information about a Coaty
 * agent which is running as a mobile/browser app or as a Node.js service.
 *
 * Agent information is generated when the agent project is build
 * and can be used at run time, e.g. for logging, display, or configuration.
 */
public class AgentInfo {
    
    public var packageInfo: AgentPackageInfo
    
    public var buildInfo: AgentBuildInfo
    
    public var configInfo: AgentConfigInfo
    
    public init(packageInfo: AgentPackageInfo, buildInfo: AgentBuildInfo, configInfo: AgentConfigInfo) {
        self.packageInfo = packageInfo
        self.buildInfo = buildInfo
        self.configInfo = configInfo
    }
}

/**
 * Represents information about the agent's package (usually npm).
 */
public class AgentPackageInfo {
    
    /**
     * The agent package name
     */
    public var name: String
    
    /**
     * The agent package version
     */
    public var version: String
    
    /**
     * Any other package-specific properties accessible by indexer
     */
    public var extra = [String: Any]()
    
    public init(name: String, version: String, extra : [String: Any]? = nil) {
        self.name = name
        self.version = version
        if let extra = extra {
            self.extra = extra
        }
    }
    
}

/**
 * Represents information about agent build.
 */
public class AgentBuildInfo {
    
    /**
     * The build date of the agent project.
     *
     * The value is in ISO 8601 format and parsable by `new Date(<isoString>)`
     * or `Date.parse(<isoString>)`.
     */
    public var buildDate: String
    
    /**
     * The build mode of the agent project. Determines whether the agent
     * is built for a production, development, staging, or any other custom
     * build environment.
     *
     * The value is acquired from environment variable setting `NODE_ENV`.
     */
    // public var buildMode: "production" | "development" | "staging" | "testing" | string;
    public var buildMode: String
    
    /**
     * Any other build-specific properties accessible by indexer
     */
    public var extra = [String: Any]()
    
    public init(buildDate: String, buildMode: String, extra : [String: Any]? = nil) {
        self.buildDate = buildDate
        self.buildMode = buildMode
        if let extra = extra {
            self.extra = extra
        }
    }
    
}

/**
 * Represents information about agent configuration.
 */
public class AgentConfigInfo {
    
    /**
     * The host name used for MQTT broker connections and REST based
     * services (optional).
     *
     * The value is acquired from the environment variable
     * `COATY_SERVICE_HOST`. If not set the value defaults to an empty string.
     */
    public var serviceHost: String
    
    /**
     * Any other config-specific properties accessible by indexer
     */
    public var extra = [String: Any]()
    
    public init(serviceHost: String, extra : [String: Any]? = nil) {
        self.serviceHost = serviceHost
        if let extra = extra {
            self.extra = extra
        }
    }
}
