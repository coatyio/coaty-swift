//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  Observation.swift
//  CoatySwift
//

import Foundation

/// An Observation is the act of measuring or otherwise determining the value
/// of a property.
open class Observation: CoatyObject {
    
    // MARK: - Class registration.
    open override class var objectType: String {
        return register(objectType: SensorThingsTypes.OBJECT_TYPE_OBSERVATION,
                        with: self)
    }
    
    // MARK: - Attributes.
    /// The time instant or period of when the Observation happens.
    public var phenomenonTime: Double
    
    /// The estimated value of an ObservedProperty from the Observation.
    /// Depends on the observationType defined in the associated Datastream.
    public var result: AnyCodable
    
    /// The time of the Observation's result was generated.
    public var resultTime: Double
    
    /// Describes the quality of the result.
    ///
    /// Should of type DQ_Element:
    /// https://geo-ide.noaa.gov/wiki/index.php?title=DQ_Element
    /// However, it is considered as a string even by the test suite:
    /// https://github.com/opengeospatial/ets-sta10/search?q=resultquality
    public var resultQuality: [String]?
    
    /// The time period during which the result may be used.
    public var validTime: CoatyTimeInterval?
    
    /// Key-value pairs showing the environmental conditions during measurement.
    public var parameters: [String: String]?
    
    /// Each Observation of the Sensor observes on one-and-only-one FeatureOfInterest (optional).
    /// It should refer to the objectId of either a FeatureOfInterest or a Location object. When the
    /// FeatureOfInterest changes, a snaphot of the Sensor should be created to display the change.
    public var featureOfInterest: CoatyUUID?
    
    // MARK: - Initializers.
    public init(phenomenonTime: Double,
         result: AnyCodable,
         resultTime: Double,
         resultQuality: [String]? = nil,
         validTime: CoatyTimeInterval? = nil,
         parameters: [String: String]? = nil,
         featureOfInterest: CoatyUUID? = nil,
         name: String,
         objectId: CoatyUUID = .init(),
         externalId: String? = nil,
         parentObjectId: CoatyUUID? = nil,
         objectType: String = Observation.objectType) {
        self.phenomenonTime = phenomenonTime
        self.result = result
        self.resultTime = resultTime
        self.resultQuality = resultQuality
        self.validTime = validTime
        self.parameters = parameters
        self.featureOfInterest = featureOfInterest
        
        super.init(coreType: .CoatyObject,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
        
        self.externalId = externalId
        self.parentObjectId = parentObjectId
    }
    
    // MARK: - Codable methods.
    enum CodingKeys: String, CodingKey {
        case phenomenonTime
        case result
        case resultTime
        case resultQuality
        case validTime
        case parameters
        case featureOfInterest
        case name
        case objectId
        case externalId
        case parentObjectId
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phenomenonTime = try container.decode(Double.self, forKey: .phenomenonTime)
        self.result = try container.decode(AnyCodable.self, forKey: .result)
        self.resultTime = try container.decode(Double.self, forKey: .resultTime)
        self.resultQuality = try container.decodeIfPresent([String].self, forKey: .resultQuality)
        self.validTime = try container.decodeIfPresent(CoatyTimeInterval.self, forKey: .validTime)
        self.parameters = try container.decodeIfPresent([String: String].self, forKey: .parameters)
        self.featureOfInterest = try container.decodeIfPresent(CoatyUUID.self, forKey: .featureOfInterest)
        
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phenomenonTime, forKey: .phenomenonTime)
        try container.encode(result, forKey: .result)
        try container.encode(resultTime, forKey: .resultTime)
        try container.encode(resultQuality, forKey: .resultQuality)
        try container.encodeIfPresent(validTime, forKey: .validTime)
        try container.encodeIfPresent(parameters, forKey: .parameters)
        try container.encodeIfPresent(featureOfInterest, forKey: .featureOfInterest)
    }
}
