//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  Thing.swift
//  CoatySwift
//

import Foundation

/// With regard to the Internet of Things, a thing is an object
/// of the physical world (physical things) or the information
/// world (virtual things) that is capable of being identified
/// and integrated into communication networks.
open class Thing: CoatyObject {
    
    // MARK: - Class registration.
    open override class var objectType: String {
        return register(objectType: SensorThingsTypes.OBJECT_TYPE_THING,
                        with: self)
    }
    
    // MARK: - Attributes.
    /// This is a short description of the corresponding Thing.
    public var description: String
    
    /// An object hash containing application-annotated properties as key-value
    /// pairs. (optional)
    public var properties: [String: String]?
    
    // MARK: - Initializers.
    public init(description: String,
         properties: [String: String]? = nil,
         name: String,
         objectId: CoatyUUID = .init(),
         externalId: String? = nil,
         parentObjectId: CoatyUUID? = nil,
         locationId: CoatyUUID? = nil,
         objectType: String = Thing.objectType) {
        self.properties = properties
        self.description = description
        
        super.init(coreType: .CoatyObject,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
        super.locationId = locationId
        
        self.externalId = externalId
        self.parentObjectId = parentObjectId
    }
    
    // MARK: - Codable methods.
    enum CodingKeys: String, CodingKey {
        case description
        case properties
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.properties = try container.decode([String: String]?.self, forKey: .properties)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(properties, forKey: .properties)
        try container.encode(description, forKey: .description)
    }
}
