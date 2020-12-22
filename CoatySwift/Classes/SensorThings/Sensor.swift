//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  Sensor.swift
//  CoatySwift
//

import Foundation

/// A Sensor is an instrument that observes a property or phenomenon with the
/// goal of producing an estimate of the value of the property. It groups a collection
/// of Observations measuring the same ObservedProperty.
open class Sensor: CoatyObject {
    
    // MARK: - Class registration.
    open override class var objectType: String {
        return register(objectType: SensorThingsTypes.OBJECT_TYPE_SENSOR,
                        with: self)
    }
    
    // MARK: - Attributes.
    /// The description of the Sensor.
    public var description: String
    
    /// The Sensor encodingType allows clients to know how to interpret metadata’s value.
    /// Currently the API defines two common Sensor metadata encodingTypes.
    /// Most sensor manufacturers provide their sensor datasheets in a PDF format.
    /// As a result, PDF is a Sensor encodingType supported by SensorThings API.
    /// The second Sensor encodingType is SensorML.
    ///
    /// Most common encoding types can be accessed using SensorEncodingTypes static properties.
    public var encodingType: String
    
    /// The detailed description of the Sensor or system.
    /// The metadata type is defined by encodingType.
    /// Must be JSON encodable/decodable.
    /// Specific parameters extraction should performed
    /// by the user who knows how this JSON is structured
    public var metadata: AnyCodable
    
    /// The unit of measurement of the datastream, matching UCUM convention.
    ///
    /// - NOTE: When a Datastream does not have a unit of measurement
    /// (e.g., a truth observation type), the corresponding unitOfMeasurement
    /// properties SHALL have nil values. The unitOfMeasurement itself,
    /// however, cannot be nil.
    public var unitOfMeasurement: UnitOfMeasurement
    
    /// The type of Observation (with unique result type), which is used by
    /// service to encode observations.
    public var observationType: ObservationType
    
    /// The spatial bounding box of the spatial extent of all FeaturesOfInterest that belong to the
    /// Observations associated with this Sensor. (optional)
    public var observedArea: Polygon?
    
    /// The temporal interval of the phenomenon times of all observations belonging to this
    /// Sensor. (optional)
    ///
    /// The ISO 8601 standard string can be created using the static function
    /// `toLocalTimeIntervalIsoString` in the CoatyTimeInterval class.
    public var phenomenonTime: CoatyTimeInterval?
    
    /// The temporal interval of the result times of all observations belonging to this
    /// Sensor. (optional)
    ///
    /// The ISO 8601 standard string can be created using the static function
    /// `toLocalTimeIntervalIsoString` in the CoatyTimeInterval class.
    public var resultTime: CoatyTimeInterval?
    
    /// The Observations of a Sensor SHALL observe the same ObservedProperty. The Observations
    /// of different Sensors MAY observe the same ObservedProperty.
    public var observedProperty: ObservedProperty
    
    // MARK: - Initializers
    public init(description: String,
         encodingType: String,
         metadata: AnyCodable,
         unitOfMeasurement: UnitOfMeasurement,
         observationType: ObservationType,
         observedArea: Polygon? = nil,
         phenomenonTime: CoatyTimeInterval? = nil,
         resultTime: CoatyTimeInterval? = nil,
         observedProperty: ObservedProperty,
         name: String,
         objectId: CoatyUUID = .init(),
         externalId: String? = nil,
         parentObjectId: CoatyUUID? = nil,
         objectType: String = Sensor.objectType) {
        
        self.description = description
        self.encodingType = encodingType
        self.metadata = metadata
        self.unitOfMeasurement = unitOfMeasurement
        self.observationType = observationType
        self.observedArea = observedArea
        self.phenomenonTime = phenomenonTime
        self.resultTime = resultTime
        self.observedProperty = observedProperty
        
        super.init(coreType: .CoatyObject,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
        
        self.externalId = externalId
        self.parentObjectId = parentObjectId
    }
    
    // MARK: - Codable methods
    enum CodingKeys: String, CodingKey {
        case description
        case encodingType
        case metadata
        case unitOfMeasurement
        case observationType
        case observedArea
        case phenomenonType
        case resultTime
        case observedProperty
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.description = try container.decode(String.self, forKey: .description)
        self.encodingType = try container.decode(String.self, forKey: .encodingType)
        self.metadata = try container.decode(AnyCodable.self, forKey: .metadata)
        self.unitOfMeasurement = try container.decode(UnitOfMeasurement.self, forKey: .unitOfMeasurement)
        self.observationType = try container.decode(ObservationType.self, forKey: .observationType)
        self.observedArea = try container.decodeIfPresent(Polygon.self, forKey: .observedArea)
        self.phenomenonTime = try container.decodeIfPresent(CoatyTimeInterval.self, forKey: .phenomenonType)
        self.resultTime = try container.decodeIfPresent(CoatyTimeInterval.self, forKey: .resultTime)
        self.observedProperty = try container.decode(ObservedProperty.self, forKey: .observedProperty)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(encodingType, forKey: .encodingType)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(unitOfMeasurement, forKey: .unitOfMeasurement)
        try container.encode(observationType, forKey: .observationType)
        try container.encodeIfPresent(observedArea, forKey: .observedArea)
        try container.encodeIfPresent(phenomenonTime, forKey: .phenomenonType)
        try container.encodeIfPresent(resultTime, forKey: .resultTime)
        try container.encode(observedProperty, forKey: .observedProperty)
    }
}

// MARK: - Types.

// NOTE: Following *Types classes are used at different places throughout the
//       SensorThings API implementation in CoatySwift.

// MARK: - SensorEncodingTypes.
/// Some common sensor encoding types.
///
/// http://docs.opengeospatial.org/is/15-078r6/15-078r6.html#table_15
open class SensorEncodingTypes {
    /// An undefined encoding type. Returns empty string.
    public static let UNDEFINED = ""
    public static let PDF = "application/pdf"
    public static let SENSOR_ML = "http://www.opengis.net/doc/IS/SensorML/2.0"
}

// MARK: - EncodingTypes.
/// Some common encoding types.
///
/// - http://docs.opengeospatial.org/is/15-078r6/15-078r6.html#table_7
/// - http://docs.opengeospatial.org/is/15-078r6/15-078r6.html#table_15
open class EncodingTypes: SensorEncodingTypes {
    public static let GEO_JSON = "application/vnd.geo+json"
}

// MARK: - ObservationTypes.
/// Some common observations types
///
/// http://docs.opengeospatial.org/is/15-078r6/15-078r6.html#table_12
public class ObservationTypes {
    /// Expects results in format of URLs.
    public static let CATEGORY = ObservationType.category_observation
    /// Expects results in format of integers.
    public static let COUNT = ObservationType.count_observation
    /// Expects results in format of doubles.
    public static let MEASUREMENT = ObservationType.measurement
    /// Expects results of any type of JSON format.
    public static let ANY = ObservationType.observation
    /// Expects results in format of booleans.
    public static let TRUTH = ObservationType.truth_observation
}

/// Observation types. For common types see `ObservationTypes`.
public enum ObservationType: String, Codable {
    case category_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Category_Observation"
    case count_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_CountObservation"
    case measurement = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement"
    case observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Observation"
    case truth_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_TruthObservation"
}

// MARK: - SensorThingsTypes.
public enum SensorThingsTypes {
    public static let OBJECT_TYPE_FEATURE_OF_INTEREST = "coaty.sensorThings.FeatureOfInterest";
    public static let OBJECT_TYPE_OBSERVATION = "coaty.sensorThings.Observation";
    public static let OBJECT_TYPE_SENSOR = "coaty.sensorThings.Sensor";
    public static let OBJECT_TYPE_THING = "coaty.sensorThings.Thing";
}
