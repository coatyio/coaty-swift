//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  FeatureOfInterest.swift
//  CoatySwift
//

import Foundation

/// An Observation results in a value being assigned to a phenomenon. The phenomenon
/// is a property of a feature, the latter being the FeatureOfInterest of the Observation.
/// In the context of the Internet of Things, many Observations’ FeatureOfInterest can be
/// the Location of the Thing. For example, the FeatureOfInterest of a wifi-connect thermostat
/// can be the Location of the thermostat (i.e., the living room where the thermostat is located
/// in). In the case of remote sensing, the FeatureOfInterest can be the geographical area or
/// volume that is being sensed.
open class FeatureOfInterest: CoatyObject {
    
    // MARK: - Class registration.
    open override class var objectType: String {
        return register(objectType: SensorThingsTypes.OBJECT_TYPE_FEATURE_OF_INTEREST,
                        with: self)
    }
    
    // MARK: - Attributes.
    /// The description about the FeatureOfInterest.
    public var description: String
    
    /// The encoding type of the feature property.
    /// Most common encoding types can be accessed using EncodingTypes static properties.
    public var encodingType: String
    
    /// The detailed description of the feature. The data type is defined by encodingType.
    public var metadata: AnyCodable
    
    // MARK: - Initializers.
    public init(description: String,
         encodingType: String,
         metadata: AnyCodable,
         name: String,
         objectId: CoatyUUID = .init(),
         externalId: String? = nil,
         parentObjectId: CoatyUUID? = nil,
         objectType: String = FeatureOfInterest.objectType) {
        self.description = description
        self.encodingType = encodingType
        self.metadata = metadata
        
        super.init(coreType: .CoatyObject,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
        
        self.externalId = externalId
        self.parentObjectId = parentObjectId
    }
    
    // MARK: - Codable methods.
    enum CodingKeys: String, CodingKey {
        case description
        case encodingType
        case metadata
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.encodingType = try container.decode(String.self, forKey: .encodingType)
        self.metadata = try container.decode(AnyCodable.self, forKey: .metadata)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(encodingType, forKey: .encodingType)
        try container.encode(metadata, forKey: .metadata)
    }
}
