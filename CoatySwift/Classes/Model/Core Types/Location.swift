//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Location.swift
//  CoatySwift
//
//

import Foundation

/// Object model representing location information
/// including geolocation according to W3C Geolocation API Specification.
///
/// This interface can be extended to allow additional attributes
/// that provide other information about this position (e.g. street address,
/// shop floor number, etc.).
open class Location: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.Location.objectType, with: self)
    }
    
    // MARK: - Attributes.
    
    public var geoLocation: GeoLocation;

    // MARK: - Initializer.

    /// Default initializer for a `Location` object.
    public init(geoLocation: GeoLocation,
                name: String = "LocationObject",
                objectType: String = Location.objectType,
                objectId: CoatyUUID = .init()) {
        
        self.geoLocation = geoLocation
        super.init(coreType: .Location, objectType: objectType, objectId: objectId, name: name)
    }

    // MARK: - Codable methods.
    
    enum LocationKeys: String, CodingKey, CaseIterable {
        case geoLocation
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LocationKeys.self)
        self.geoLocation = try container.decode(GeoLocation.self, forKey: .geoLocation)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: LocationKeys.self)
        try super.init(from: decoder)
    }

    open override func encode(to encoder: Encoder) throws {
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

    public init(coords: GeoCoordinates, timestamp: Double = CoatyTimestamp.nowMillis()) {
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
