//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Configuration.swift
//  CoatySwift
//

import Foundation

/// Convenience class for building a configuration.
public class ConfigurationBuilder {
    public var common: CommonOptions?
    public var communication: CommunicationOptions?
    public var controllers: ControllerConfig?
    public var databases: DatabaseOptions?
}


/// Configuration options for Coaty container components,
/// such as controllers, communication manager, and runtime.
///
/// - Warning: Configuration objects does not need to conform to JSON format as opposed
///            to the coaty-js version!
public class Configuration {
    
    /// Common options shared by container components.
    public var common: CommonOptions
    
    /// Options used for communication.
    public var communication: CommunicationOptions
    
    /// Controller configuration options (optional).
    public var controllers: ControllerConfig?
    
    /// Options used to connect to databases (optional).
    public var databases: DatabaseOptions?
    
    public init(common: CommonOptions, communication: CommunicationOptions,
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


/// Common options shared by all container components.
public class CommonOptions {
    
    /// User object that is associated with this runtime configuration
    /// (optional).
    /// Used for a Coaty container that runs on a user device.
    public var associatedUser: User?
    
    /// Device object that is associated with this runtime configuration
    /// (optional).
    /// Used for a Coaty container that runs on a user device.
    public var associatedDevice: Device?
    
    /// Agent information generated and injected into the configuration
    /// when the agent project is build (optional).
    public var agentInfo: AgentInfo?
    
    /// Any other custom properties accessible by indexer.
    public var extra = [String: Any]()
    
    /// Setting for the level of the CoatySwift Logger.
    public var logLevel = CoatySwiftLogLevel.error
    
    public init(associatedUser: User? = nil, associatedDevice: Device? = nil,
         agentInfo: AgentInfo? = nil, extra: [String: Any]? = nil,
         logLevel: CoatySwiftLogLevel? = nil) {
        self.associatedUser = associatedUser
        self.associatedDevice = associatedDevice
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
    
    /// Options to connect with CocoaMQTT client to broker.
    public var mqttClientOptions: MQTTClientOptions?
    
    /// Property-value pairs to be initialized on the identity object of the
    /// communication manager (optional). For example, the `name` of the
    /// identity object can be configured here.
    public var identity: [String: Any]?
    
    /// Determines whether the communication manager should start initially
    /// when the container has been resolved. Its value defaults
    /// to false.
    public var shouldAutoStart: Bool = false
    
    /// Determines whether the communication manager should advertise its
    /// identity automatically when started and deadvertise its identity when
    /// stopped or terminated abnormally (via last will). If not specified or
    /// undefined, de/advertisements will be done by default.
    /// The communication managers's identity is also discoverable (by publishing
    /// a Discover event with core type "Component" or with the object id of a
    /// component) if and only if the identity has also been advertised.
    public var shouldAdvertiseIdentity: Bool?
    
    /// Determines whether the communication manager should advertise the
    /// associated device (defined in Runtime.options.associatedDevice)
    /// automatically when started and deadvertise the device when stopped or
    /// terminated abnormally (via last will). If not specified or undefined,
    /// de/advertisements will be done by default.
    /// The associated device is also discoverable (by publishing a Discover
    /// event with core type "Device" or with the object id of a device) if and
    /// only if the device has also been advertised.
    public var shouldAdvertiseDevice: Bool?
    
    /// Determines whether the communication manager should publish readable
    /// messaging topics for optimized testing and debugging. Instead of using
    /// a UUID alone, a readable name can be part of the topic levels of
    /// Associated User ID, Source Object ID, and Message Tokens.
    ///
    /// If not specified, the value of this option defaults to false.
    public var useReadableTopics: Bool = false
    
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
    /// By default, non-compliant Client IDs of the form "COATY<uuid>" are used where
    /// <uuid> specifies the `objectId` of the communication manager's `identity` object.
    /// If you experience issues with a specific broker, specify this option as `true`.
    public var useProtocolCompliantClientId: Bool = false
    
    
    public init(mqttClientOptions: MQTTClientOptions? = nil,
                identity: [String: Any]? = nil,
                shouldAutoStart: Bool? = nil,
                shouldAdvertiseIdentity: Bool? = true,
                shouldAdvertiseDevice: Bool? = nil,
                useReadableTopics: Bool? = nil,
                useProtocolCompliantClientId: Bool? = nil) {
        self.mqttClientOptions = mqttClientOptions
        self.identity = identity
        if let shouldAutoStart = shouldAutoStart {
            self.shouldAutoStart = shouldAutoStart
        }
        self.shouldAdvertiseIdentity = shouldAdvertiseIdentity
        self.shouldAdvertiseDevice = shouldAdvertiseDevice
        if let useReadableTopics = useReadableTopics {
            self.useReadableTopics = useReadableTopics
        }
        if let useProtocolCompliantClientId = useProtocolCompliantClientId {
            self.useProtocolCompliantClientId = useProtocolCompliantClientId
        }
    }
}


/// Controller options mapped by controller class name.
public class ControllerConfig {
    public var controllerOptions: [String: ControllerOptions]
    
    public init(controllerOptions: [String: ControllerOptions]) {
        self.controllerOptions = controllerOptions
    }
}


/// Controller-specific options.
public class ControllerOptions {
    
    /// Property-value pairs to be initialized on the identity object of the
    /// controller (optional). For example, the `name` of the
    /// identity object can be configured here.
    public var identity: [String: Any]?
    
    /// Determines whether the controller should advertise its identity
    /// automatically when it is instantiated and deadvertise its identity when
    /// the communication manager is stopped or terminated abnormally (via last
    /// will). If not specified or undefined, the identity is
    /// advertised/deadvertised by default.
    ///
    /// The communication managers's identity is also discoverable (by publishing
    /// a Discover event with core type "Component" or with the object id of a
    /// component) if and only if the identity has also been advertised.
    public var shouldAdvertiseIdentity: Bool = true
    
    /// Any other application-specific properties accessible by indexer.
    public var extra = [String: Any]()
    
    public init(identity: [String: Any]? = nil,
         shouldAdvertiseIdentity: Bool? = nil,
         extra: [String: Any]? = nil) {
        self.identity = identity
        if let shouldAdvertiseIdentity = shouldAdvertiseIdentity {
            self.shouldAdvertiseIdentity = shouldAdvertiseIdentity
        }
        if let extra = extra {
            self.extra = extra
        }
    }
}


/// Database access options mapped by a unique database key.
public class DatabaseOptions {
    
    /// Database connection info indexed by a database key.
    public var databaseConnections: [String: DbConnectionInfo]
    
    public init(databaseConnections: [String: DbConnectionInfo]) {
        self.databaseConnections = databaseConnections
    }
}

/// MQTT client options based on the CocoaMQTT client.
public class MQTTClientOptions {
    public var host: String
    public var port: UInt16
    public var shouldTryMDNSDiscovery: Bool
    public var clientId: String
    public var username: String?
    public var password: String?
    public var cleanSession: Bool
    public var allowUntrustCACertificate: Bool
    public var autoReconnectTimeInterval: Int
    
    /// Do not set keepAlive under 10 seconds. Otherwise it might happen that you will reconnect
    /// unnecessarily because of latency issues, especially if you are using a public broker.
    public var keepAlive: UInt16
    public var enableSSL: Bool
    public var autoReconnect: Bool
    
    public init(host: String,
         port: UInt16,
         clientId: String,
         enableSSL: Bool,
         shouldTryMDNSDiscovery: Bool = false,
         username: String? = nil,
         password: String? = nil,
         cleanSession: Bool = true,
         keepAlive: UInt16 = 60,
         autoReconnect: Bool = true,
         allowUntrustCACertificate: Bool = false,
         autoReconnectTimeInterval: Int = 3) {
        self.host = host
        self.port = port
        self.enableSSL = enableSSL
        self.shouldTryMDNSDiscovery = shouldTryMDNSDiscovery
        self.clientId = clientId
        self.username = username
        self.password = password
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.autoReconnect = autoReconnect
        self.allowUntrustCACertificate = allowUntrustCACertificate
        self.autoReconnectTimeInterval = autoReconnectTimeInterval
    }
}


// - MISSING: function mergeConfigurations()
func mergeConfigurations() throws -> Never  {
    fatalError("Merging configurations not supported yet.")
}

