//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Configuration.swift
//  CoatySwift
//

import Foundation

/// Convenience class for building a configuration.
public class ConfigurationBuilder {
    
    /// Common options shared by container components (optional).
    public var common: CommonOptions?
    
    /// Options used for communication.
    public var communication: CommunicationOptions?
    
    /// Controller configuration options (optional).
    public var controllers: ControllerConfig?
    
    /// Options used to connect to databases (optional).
    public var databases: DatabaseOptions?
}


/// Configuration options for Coaty container components,
/// such as controllers, communication manager, and runtime.
///
/// - Warning: Configuration objects do not need to conform to JSON format as opposed
///            to the Coaty JS framework!!
public class Configuration {
    
    /// Common options shared by container components (optional).
    public var common: CommonOptions?
    
    /// Options used for communication.
    public var communication: CommunicationOptions
    
    /// Controller configuration options (optional).
    public var controllers: ControllerConfig?
    
    /// Options used to connect to databases (optional).
    public var databases: DatabaseOptions?
    
    /// Create a new configuration instance with the given options.
    public init(common: CommonOptions? = nil, communication: CommunicationOptions,
         controllers: ControllerConfig? = nil, databases: DatabaseOptions? = nil) {
        self.common = common
        self.communication = communication
        self.controllers = controllers
        self.databases = databases
    }
    
    // MARK: Builder method.
    
    /// Builds a new `Configuration` using the convenience closure syntax.
    ///
    /// - Parameter closure: the builder closure, preferably used as trailing closure.
    /// - Returns: Configuration configured using the builder.
    public static func build(_ closure: (ConfigurationBuilder) -> ()) throws -> Configuration {
        
        let builder = ConfigurationBuilder()
        closure(builder)
        
        guard let common = builder.common, let communication = builder.communication else {
            throw NSError()
        }
        
        return .init(common: common,
                     communication: communication,
                     controllers: builder.controllers,
                     databases: builder.databases)
    }
}

/// A convenience struct used to define an IoNode
public struct IoNodeDefinition {
    var ioSources: [IoSource]?
    var ioActors: [IoActor]?
    var characteristics: [String: Any]?
    
    public init(ioSources: [IoSource]?, ioActors: [IoActor]?, characteristics: [String: Any]?) {
        self.ioSources = ioSources
        self.ioActors = ioActors
        self.characteristics = characteristics
    }
}

/// Common options shared by container components.
public class CommonOptions {
    
    /// Specify IO nodes associated with IO contexts for IO routing (optional).
    ///
    /// Each IO node definition is hashed by the IO context name the node should
    /// be associated with. An IO node definition includes IO sources and/or IO
    /// actors, and node-specific characteristics to be used for IO routing.
    ///
    /// If neither IO sources nor IO actors are specified for an IO node, its
    /// node definition is ignored.
    public var ioContextNodes: [String: IoNodeDefinition]?
    
    /// Property-value pairs to be configured on the identity object of the agent
    /// container (optional). Usually, an expressive `name` of the identity is
    /// configured here.
    /// 
    /// - Note: `objectType` and `coreType` properties of an identity
    ///         object are ignored, i.e. cannot be overridden.
    public var agentIdentity: [String: Any]?
    
    /// Agent information generated and injected into the configuration
    /// when the agent project is build (optional).
    public var agentInfo: AgentInfo?
    
    /// Additional application-specific properties (optional).
    /// Useful to inject service instances to be shared among controllers.
    public var extra = [String: Any]()
    
    /// Determines the log level (default is .error) for logging CoatySwift internal
    /// errors, warnings, and informational messages.
    public var logLevel = CoatySwiftLogLevel.error
    
    /// Create a new CommonOptions instance.
    public init(ioContextNodes: [String: IoNodeDefinition]? = nil,
                agentIdentity: [String: Any]? = nil,
                agentInfo: AgentInfo? = nil,
                extra: [String: Any]? = nil,
                logLevel: CoatySwiftLogLevel? = nil) {
        self.ioContextNodes = ioContextNodes
        self.agentIdentity = agentIdentity
        self.agentInfo = agentInfo
        if let extra = extra {
            self.extra = extra
        }
        
        if let logLevel = logLevel {
            self.logLevel = logLevel
        }
    }
    
}

/// Options used for communication
public class CommunicationOptions {

    /// Namespace used to isolate different Coaty applications (optional).
    ///
    /// Communication events are only routed between agents within a common
    /// communication namespace.
    ///
    /// A namespace string must not contain the following characters: `NULL
    /// (U+0000)`, `# (U+0023)`, `+ (U+002B)`, `/ (U+002F)`.
    ///
    /// If not specified or empty, a default namespace named "-" is used.
    ///
    public var namespace: String?

    /// Determines whether to enable cross-namespace communication between agents
    /// in special use cases (optional). 
    ///
    /// If `true`, an agent receives communication events published by *any*
    /// agent in the same networking infrastructure, regardless of namespace.
    ///
    /// This option's value defaults to false.
    public var shouldEnableCrossNamespacing: Bool = false
    
    /// Options to connect with CocoaMQTT client to broker.
    public var mqttClientOptions: MQTTClientOptions?
    
    /// Determines whether the communication manager should start initially
    /// when the container has been resolved. Its value defaults
    /// to false.
    public var shouldAutoStart: Bool = false
    
    /// Determines whether the communication manager should provide a protocol
    /// compliant client ID when connecting to the broker/router.
    ///
    /// If not specified, the value of this option defaults to false.
    ///
    /// For example, MQTT Spec 3.1 states that the broker MUST allow Client IDs
    /// which are between 1 and 23 UTF-8 encoded bytes in length, and that contain only
    /// the characters "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".
    /// However, broker implementations are free to allow non-compliant Client IDs.
    ///
    /// By default, non-compliant Client IDs of the form "Coaty<uuid>" are used where
    /// <uuid> specifies the `objectId` of the communication manager's `identity` object.
    /// If you experience issues with a specific broker, specify this option as `true`.
    @available(*, deprecated)
    public var useProtocolCompliantClientId: Bool = false
    
    /// Create a new CommunicationOptions instance.
    public init(namespace: String? = nil,
                shouldEnableCrossNamespacing: Bool? = nil,
                mqttClientOptions: MQTTClientOptions? = nil,
                shouldAutoStart: Bool? = nil,
                useProtocolCompliantClientId: Bool? = nil) {
        self.namespace = namespace
        if let shouldEnableCrossNamespacing = shouldEnableCrossNamespacing {
            self.shouldEnableCrossNamespacing = shouldEnableCrossNamespacing
        }
        self.mqttClientOptions = mqttClientOptions
        if let shouldAutoStart = shouldAutoStart {
            self.shouldAutoStart = shouldAutoStart
        }
        if let useProtocolCompliantClientId = useProtocolCompliantClientId {
            self.useProtocolCompliantClientId = useProtocolCompliantClientId
        }
    }
}


/// Controller options mapped by controller class name.
public class ControllerConfig {
    
    /// Controller-specific options.
    public var controllerOptions: [String: ControllerOptions]
    
    /// Create a new ControllerConfig instance.
    public init(controllerOptions: [String: ControllerOptions]) {
        self.controllerOptions = controllerOptions
    }
}


/// Controller-specific options.
public class ControllerOptions {
    
    /// Any application-specific properties accessible by indexer.
    public var extra = [String: Any]()
    
    /// Create a new ControllerOptions instance.
    public init(extra: [String: Any]? = nil) {
        if let extra = extra {
            self.extra = extra
        }
    }
}


/// Database access options mapped by a unique database key.
public class DatabaseOptions {
    
    /// Database connection info indexed by a database key.
    public var databaseConnections: [String: DbConnectionInfo]
    
    /// Create a new DatabaseOptions instance.
    public init(databaseConnections: [String: DbConnectionInfo]) {
        self.databaseConnections = databaseConnections
    }
}

/// MQTT client options for the CocoaMQTT client.
public class MQTTClientOptions {

    /// Broker host name or IP address (default "localhost").
    public var host: String

    /// Broker port (default is 1883).
    public var port: UInt16

    /// MQTT client ID set by communication manager.
    internal var clientId: String?

    /// Determines whether to try to discover a broker host/port 
    /// by mDNS/Bonjour service (default is false).
    public var shouldTryMDNSDiscovery: Bool

    /// Username for secure connection (optional).
    public var username: String?
    
    /// Password for secure connection (optional).
    public var password: String?
    
    /// Whether to allow untrusted certificate roots or not.
    public var allowUntrustCACertificate: Bool
    
    /// Interval in which keep alive messages are sent (in seconds).
    ///
    /// - NOTE: Do not set keepAlive under 10 seconds. Otherwise it might happen
    ///   that you will reconnect unnecessarily because of latency issues,
    ///   especially if you are using a public broker.
    public var keepAlive: UInt16

    /// Whether to enable secure SSL connection.
    public var enableSSL: Bool

    /// Determines whether client should reconnect automatically
    /// if connection is closed abnormally.
    public var autoReconnect: Bool
    
    /// Auto reconnect time interval In seconds.
    public var autoReconnectTimeInterval: Int

    /// MQTT Quality of Service level (1, 2, 3) for publications, subscriptions,
    /// and last will messages (defaults to 0).
    public var qos: Int
    
    /// Determines whether to log MQTT protocol messages (defaults to false).
    /// Turn on for debugging only because output is rather abundant.
    public var shouldLog: Bool
    
    /// Create a new instance of MQTTClientOptions.
    public init(host: String = "localhost",
         port: UInt16 = 1883,
         enableSSL: Bool = false,
         shouldTryMDNSDiscovery: Bool = false,
         username: String? = nil,
         password: String? = nil,
         keepAlive: UInt16 = 60,
         autoReconnect: Bool = true,
         allowUntrustCACertificate: Bool = false,
         autoReconnectTimeInterval: Int = 1,
         qos: Int = 0,
         shouldLog: Bool = false) {
        self.host = host
        self.port = port
        self.clientId = nil
        self.enableSSL = enableSSL
        self.shouldTryMDNSDiscovery = shouldTryMDNSDiscovery
        self.username = username
        self.password = password
        self.keepAlive = keepAlive
        self.autoReconnect = autoReconnect
        self.allowUntrustCACertificate = allowUntrustCACertificate
        self.autoReconnectTimeInterval = autoReconnectTimeInterval
        self.qos = qos
        self.shouldLog = shouldLog
    }
}

