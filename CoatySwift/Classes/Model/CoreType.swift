//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoreType.swift
//  CoatySwift
//
//

import Foundation

/// All Coaty CoreTypes as defined in https://github.com/coatyio/coaty-js/blob/master/src/model/types.ts
public enum CoreType: String, Codable {
    
    // MARK: - Value definitions.
    
    case CoatyObject
    case User
    case Device
    case Annotation
    case Task
    case IoSource
    case IoActor
    case Component
    case Config
    case Log
    case Location
    case Snapshot
    
    // MARK: - Codable methods.
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        
        // Try to parse the raw value to the actual enum.
        guard let coreType = CoreType(rawValue: rawString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Attempted to decode invalid enum."))
        }
        
        self = coreType
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// TODO: Move to separate files.

/// Object model representing location information
/// including geolocation according to W3C Geolocation API Specification.
///
/// This interface can be extended to allow additional attributes
/// that provide other information about this position (e.g. street address,
/// shop floor number, etc.).
public class Location: CoatyObject {
    
    // MARK: - Attributes.
    
    public var geoLocation: GeoLocation;

    // MARK: - Initializer.

    /// Default initializer for a `Location` object.
    public init(geoLocation: GeoLocation,
                name: String = "LocationObject",
                objectType: String = "\(COATY_PREFIX)\(CoreType.Location)",
                objectId: CoatyUUID = .init()) {
        
        self.geoLocation = geoLocation
        super.init(coreType: .Location, objectType: objectType, objectId: objectId, name: name)
    }

    // MARK: - Codable methods.
    
    enum LocationKeys: String, CodingKey {
        case geoLocation
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LocationKeys.self)
        self.geoLocation = try container.decode(GeoLocation.self, forKey: .geoLocation)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: LocationKeys.self)
        try container.encode(geoLocation, forKey: .geoLocation)
    }
}

/// Represents geolocation information according to W3C Geolocation
/// API Specification.
///
/// This version of the specification allows one attribute of
/// type GeoCoordinates and a timestamp.
public class GeoLocation: Codable {
    
    // MARK: - Attributes.
    
    /// Contains a set of geographic coordinates together with their associated
    /// accuracy, as well as a set of other optional attributes such as altitude
    /// and speed.
    public var coords: GeoCoordinates;

    
    /// Represents the time when the GeoLocation object was acquired
    /// and is represented as a number of milliseconds, either as an absolute time
    /// (relative to some epoch) or as a relative amount of time.
    public var timestamp: Double;
    
    // MARK: - Initializers.

    public init(coords: GeoCoordinates, timestamp: Double = Date().timeIntervalSince1970) {
        self.coords = coords
        self.timestamp = timestamp
    }
    
    // MARK: - Codable methods.
    
    enum GeoLocationKeys: String, CodingKey {
        case coords
        case timestamp
    }

     public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: GeoLocationKeys.self)
        self.coords = try container.decode(GeoCoordinates.self, forKey: .coords)
        self.timestamp = try container.decode(Double.self, forKey: .timestamp)
     }

     public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GeoLocationKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(coords, forKey: .coords)
     }
    
}

/// Represent geographic coordinates. The reference system used by the properties
/// in this interface is the World Geodetic System (2d) [WGS84].
public class GeoCoordinates: Codable {
    
    // MARK: - Attributes.
    
    /// The latitude is a geographic coordinate specified in decimal degrees.
    public var latitude: Double

    /// The longitude is a geographic coordinates specified in decimal degrees.
    public var longitude: Double

    /// The altitude attribute (optional) denotes the height of the position, specified in meters
    /// above the [WGS84] ellipsoid. If the implementation cannot provide altitude
    /// information, the value of this attribute must be nil.
    public var altitude: Double?

    /// The accuracy attribute denotes the accuracy level of the latitude and longitude
    /// coordinates. It is specified in meters and must be supported by all implementations.
    /// The value of the accuracy attribute must be a non-negative real number.
    public var accuracy: Double

    /// The altitudeAccuracy attribute (optional) is specified in meters. If the implementation
    /// cannot provide altitude information, the value of this attribute must be undefined.
    /// Otherwise, the value of the altitudeAccuracy attribute must be a non-negative real number.
    public var altitudeAccuracy: Double?

    /// The heading attribute denotes the direction of travel of the hosting device and is
    /// specified in degrees, where 0 <= heading < 360, counting clockwise relative to the
    /// true north. If the implementation cannot provide heading information, the value of
    /// this attribute must be undefined. If the hosting device is stationary (i.e. the value
    /// of the speed attribute is 0), then the value of the heading attribute must be nil.
    public var heading: Double?

    /// The speed attribute denotes the magnitude of the horizontal component of the hosting
    /// device's current velocity and is specified in meters per second. If the implementation
    /// cannot provide speed information, the value of this attribute must be nil. Otherwise,
    /// the value of the speed attribute must be a non-negative real number.
    public var speed: Double?
    
    // MARK: - Initializers.
    
    public init(latitude: Double,
                longitude: Double,
                accuracy: Double,
                altitude: Double? = nil,
                altitudeAccuracy: Double? = nil,
                heading: Double? = nil,
                speed: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.altitude = altitude
        self.altitudeAccuracy = altitudeAccuracy
        self.heading = heading
        self.speed = speed
    }
    
    // MARK: - Codable methods.
    
    enum GeoCoordinateKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case accuracy
        case altitudeAccuracy
        case heading
        case speed
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: GeoCoordinateKeys.self)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.accuracy = try container.decode(Double.self, forKey: .accuracy)
        self.altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        self.altitudeAccuracy = try container.decodeIfPresent(Double.self, forKey: .altitudeAccuracy)
        self.heading = try container.decodeIfPresent(Double.self, forKey: .heading)
        self.speed = try container.decodeIfPresent(Double.self, forKey: .speed)
    }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: GeoCoordinateKeys.self)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
            try container.encode(accuracy, forKey: .accuracy)
            try container.encodeIfPresent(altitude, forKey: .altitude)
            try container.encodeIfPresent(altitudeAccuracy, forKey: .altitudeAccuracy)
            try container.encodeIfPresent(heading, forKey: .heading)
            try container.encodeIfPresent(speed, forKey: .speed)
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

/// Represents a log object.
public class Log: CoatyObject {
    
    // MARK: - Attributes.

    /// The level of logging.
    public var logLevel: LogLevel

    /// The message to log.
    public var logMessage: String

    /// Timestamp in ISO 8601 format (with or without timezone offset), as from
    /// `coaty/util/toLocalIsoString` or `Date.toISOString`.
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
                objectType: String = "\(COATY_PREFIX)\(CoreType.Log)",
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
       
    public override func encode(to encoder: Encoder) throws {
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


public enum AnnotationStatus: Int, Codable {

    /// Set when annotation media has only been stored on the creator's local device
    case storedLocally

    /// Set when Advertise event for publishing annotation media is being sent
    case storageRequest

    /// Set when annotation media was stored by a service component subscribing for annotations
    case published

    /// Set when annotation media is outdated, i.e. should no longer be in use by application
    case outdated
}

/// Represents an annotation
public class Annotation: CoatyObject {
    
    // MARK: Attributes.
    
    /// Specific type of this annotation object
    public var type: AnnotationType

    /// UUID of User who created the annotation
    public var creatorId: CoatyUUID

    /// Timestamp when annotation was issued/created.
    /// Value represents the number of milliseconds since the epoc in UTC.
    /// (see Date.getTime(), Date.now())
    public var creationTimestamp: Double

    /// Status of storage
    public var status: AnnotationStatus

    /// Array of annotation media variants (optional). A variant is an object
    /// with a description key and a download url
    public var variants: [AnnotationVariant]?
    
    // MARK: Initializers.
    
    public init(type: AnnotationType,
                creatorId: CoatyUUID,
                creationTimestamp: Double,
                status: AnnotationStatus,
                name: String = "AnnotationObject",
                objectType: String = "\(COATY_PREFIX)\(CoreType.Annotation)",
                objectId: CoatyUUID = .init(),
                variants: [AnnotationVariant]? = nil) {
        self.type = type
        self.creatorId = creatorId
        self.creationTimestamp = creationTimestamp
        self.status = status
        self.variants = variants
        super.init(coreType: .Annotation, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: Codable methods.
    
    enum AnnotationKeys: String, CodingKey {
        case type
        case creatorId
        case creationTimestamp
        case status
        case variants
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnnotationKeys.self)
        self.type = try container.decode(AnnotationType.self, forKey: .type)
        self.creatorId = try container.decode(CoatyUUID.self, forKey: .creatorId)
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.status = try container.decode(AnnotationStatus.self, forKey: .status)
        self.variants = try container.decodeIfPresent([AnnotationVariant].self, forKey: .variants)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: AnnotationKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(variants, forKey: .variants)
    }

}

/// Variant object composed of a description key and a download url
public class AnnotationVariant: Codable {

    // MARK: Attributes.
    
    /// Description key of  annotation variant
    public var variant: String

    /// Dowload url for annotation variant
    public var downloadUrl: String
    
    // MARK: Initializers.
    
    public init(variant: String, downloadUrl: String) {
        self.variant = variant
        self.downloadUrl = downloadUrl
    }
    
    // MARK: Codable methods.
    
    enum AnnotationVariantKeys: String, CodingKey {
        case variant
        case downloadUrl
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnnotationVariantKeys.self)
        self.variant = try container.decode(String.self, forKey: .variant)
        self.downloadUrl = try container.decode(String.self, forKey: .downloadUrl)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnnotationVariantKeys.self)
        try container.encode(variant, forKey: .variant)
        try container.encode(downloadUrl, forKey: .downloadUrl)
    }
}

/// Defines all annotation types
public enum AnnotationType: Int, Codable {
    case text
    case image
    case audio
    case video
    case object3D
    case pdf
    case webDocumentUrl
    case liveDataUrl
}

/// Defines strategies for coping with IO sources that produce IO values more
/// rapidly than specified in their currently recommended update rate.
public enum IoSourceBackpressureStrategy: Int, Codable {

    /// Use a default strategy for publishing values: If no recommended
    /// update rate is assigned to the IO source, use the `None` strategy;
    /// otherwise use the `Sample` strategy.
    case Default

    /// Publish all values immediately. Note that this strategy ignores
    /// the recommended update rate assigned to the IO source.
    case None

    /// Publish the most recent values within periodic time intervals
    /// according to the recommended update rate assigned to the IO source.
    /// If no update rate is given, fall back to the `None` strategy.
    case Sample

    /// Only publish a value if a particular timespan has
    /// passed without it publishing another value. The timespan is
    /// determined by the recommended update rate assigned to the IO source.
    /// If no update rate is given, fall back to the `None` strategy.
    case Throttle
}

 /// Defines meta information of an IO point.
 ///
 /// This base object has no associated framework base object type.
 /// For instantiation use one of the concrete subtypes `IoSource` or `IoActor`.
 public class IoPoint: CoatyObject {

    /// The update rate (in milliseconds) for publishing IoValue events:
    /// - desired rate for IO actors
    /// - maximum possible drain rate for IO sources
    /// The IO router specifies the recommended update rate in Associate event data.
    /// If undefined, there is no limit on the rate of published events.
    public var updateRate: Double?

    /// A communication topic used for routing values from external sources to
    /// internal IO actors or from internal IO sources to external sinks (optional).
    /// Used only for predefined external topics that are not generated by the IO router
    /// dynamically, but defined by an external (i.e. non-Coaty) component instead.
    public var externalTopic: String?
    
    // MARK: - Initializers.
    
    fileprivate init(coreType: CoreType,
                     objectType: String,
                     objectId: CoatyUUID,
                     name: String,
                     updateRate: Double? = nil,
                     externalTopic: String? = nil) {
        self.updateRate = updateRate
        self.externalTopic = externalTopic
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.

    enum IoPointKeys: String, CodingKey {
        case updateRate
        case externalTopic
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoPointKeys.self)
        self.updateRate = try container.decodeIfPresent(Double.self, forKey: .updateRate)
        self.externalTopic = try container.decodeIfPresent(String.self, forKey: .externalTopic)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoPointKeys.self)
        try container.encodeIfPresent(updateRate, forKey: .updateRate)
        try container.encodeIfPresent(externalTopic, forKey: .externalTopic)
    }
}

/// Defines meta information of an IO source.
public class IoSource: IoPoint {
    
    // MARK: - Attributes.

    /// The semantic, application-specific data type of values to be represented
    /// by the IO source, such as Temperature, Notification, Task, etc.
    /// In order to be associated with an IO actor their value types must match.
    ///
    /// The property value must be a non-empty string. You should choose
    /// canonical names for value types to avoid naming collisions. For example,
    /// by following the naming convention for Java packages, such as
    /// `com.mydomain.myapp.Temperature`.
    ///
    /// Note that this value type is different from the underlying data format
    /// used by the IO source to publish IO data values. For example, an IO source
    /// for a temperature sensor could emit values as numbers or as a Value1D
    /// object with specific properties.
    public var valueType: String

    /// The backpressure strategy for publishing IO values (optional).
    public var updateStrategy: IoSourceBackpressureStrategy?
    
    // MARK: - Initializers.
    
    init(valueType: String,
         updateStrategy: IoSourceBackpressureStrategy? = nil,
         updateRate: Double? = nil,
         externalTopic: String? = nil,
         name: String = "IoSourceObject",
         objectType: String = "\(COATY_PREFIX)\(CoreType.IoSource)",
            objectId: CoatyUUID = .init()) {
        self.valueType = valueType
        self.updateStrategy = updateStrategy
        super.init(coreType: .IoSource,
                   objectType: objectType,
                   objectId: objectId,
                   name: name,
                   updateRate: updateRate,
                   externalTopic: externalTopic)
    }
    
    // MARK: - Codable methods.

    enum IoSourceKeys: String, CodingKey {
        case valueType
        case updateStrategy
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoSourceKeys.self)
        self.valueType = try container.decode(String.self, forKey: .valueType)
        self.updateStrategy = try container.decodeIfPresent(IoSourceBackpressureStrategy.self, forKey: .updateStrategy)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoSourceKeys.self)
        try container.encode(valueType, forKey: .valueType)
        try container.encodeIfPresent(updateStrategy, forKey: .updateStrategy)
    }
}

/// Defines meta information of an IO actor.
public class IoActor: IoPoint {
    
    // MARK: - Attributes.

    /// The semantic, application-specific data type of values to be consumed
    /// by the IO actor, such as Temperature, Notification, Task, etc.
    /// In order to be associated with an IO source their value types must match.
    ///
    /// The property value must be a non-empty string. You should choose
    /// canonical names for value types to avoid naming collisions. For example,
    /// by following the naming convention for Java packages, such as
    /// `com.mydomain.myapp.Temperature`.
    ///
    /// Note that this value type is different from the underlying data format
    /// used by the IO source to publish IO data values. For example, an IO source
    /// for a temperature sensor could emit values as numbers or as a Value1D
    /// object with specific properties.
    public var valueType: String

    /// Determines whether IO values (generated by external sources)
    /// should be treated as raw strings that are non encoded/decoded as JSON objects.
    /// The value of this property defaults to false.
    public var useRawIoValues: Bool?
    
    // MARK: - Initializers.
    
    init(valueType: String,
         useRawIoValues: Bool? = false,
         updateRate: Double? = nil,
         externalTopic: String? = nil,
         name: String = "IoActorObject",
         objectType: String = "\(COATY_PREFIX)\(CoreType.IoActor)",
         objectId: CoatyUUID = .init()) {
        self.valueType = valueType
        self.useRawIoValues = useRawIoValues
        super.init(coreType: .IoActor,
                   objectType: objectType,
                   objectId: objectId,
                   name: name,
                   updateRate: updateRate,
                   externalTopic: externalTopic)
    }
    
    // MARK: Codable methods.
    
    enum IoActorKeys: String, CodingKey {
        case valueType
        case useRawIoValues
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoActorKeys.self)
        self.valueType = try container.decode(String.self, forKey: .valueType)
        self.useRawIoValues = try container.decodeIfPresent(Bool.self, forKey: .useRawIoValues) ?? false
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoActorKeys.self)
        try container.encode(valueType, forKey: .valueType)
        try container.encodeIfPresent(useRawIoValues, forKey: .useRawIoValues)
    }
}
