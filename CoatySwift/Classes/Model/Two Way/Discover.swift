//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Discover-Resolve.swift
//  CoatySwift
//
//

import Foundation

/// Discover implements the common fields from a standard Coaty Discover message as defined in
/// https://coatyio.github.io/coaty-js/man/communication-protocol/
public class Discover: Codable {
    
    // MARK: - Attributes.
    
    public var externalId: String?
    public var objectId: CoatyUUID?
    public var objectTypes: [String]?
    public var coreTypes: [CoreType]?
    
    // MARK: - Initializers.
    
    /// Create a Discover instance for the given IDs or types.
    ///
    /// The following combinations of parameters are valid (use undefined for unused parameters):
    /// - externalId can be used exclusively or in combination with objectId property.
    ///  Only if used exclusively it can be combined with objectTypes or coreTypes properties.
    /// - objectId can be used exclusively or in combination with externalId property.
    ///  Must not be used in combination with objectTypes or coreTypes properties.
    /// - objectTypes must not be used with objectId property.
    ///  Should not be used in combination with coreTypes.
    /// - coreTypes must not be used with objectId property.
    /// Should not be used in combination with objectTypes.
    ///
    /// - Parameters:
    ///     - externalId: The external ID of the object(s) to be discovered or undefined.
    ///     - objectId: The internal UUID of the object to be discovered or undefined.
    ///     - objectTypes: Restrict objects by object types (logical OR).
    ///     - coreTypes: Restrict objects by core types (logical OR).
    private init(externalId: String?, objectId: CoatyUUID?, objectTypes: [String]?, coreTypes: [CoreType]?) {
        self.externalId = externalId
        self.objectId = objectId
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
    }

    // MARK: - Convenience initializers that cover all permitted parameter combinations.
    
    required init(objectId: CoatyUUID) {
        self.objectId = objectId
    }
    
    required init(externalId: String, objectTypes: [String], coreTypes: [CoreType]) {
        self.externalId = externalId
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
    }
    
    required init(externalId: String, objectTypes: [String]) {
        self.externalId = externalId
        self.objectTypes = objectTypes
    }
    
    required init(externalId: String, coreTypes: [CoreType]) {
        self.externalId = externalId
        self.coreTypes = coreTypes
    }
    
    required init(externalId: String) {
        self.externalId = externalId
    }
    
    required init(objectId: CoatyUUID, externalId: String) {
        self.objectId = objectId
        self.externalId = externalId
    }
    
    required init(coreTypes: [CoreType], objectTypes: [String]) {
        self.coreTypes = coreTypes
        self.objectTypes = objectTypes
    }
    
    required init(coreTypes: [CoreType]) {
        self.coreTypes = coreTypes
    }
    
    required init(objectTypes: [String]) {
        self.objectTypes = objectTypes
    }
    
    required init(externalId: String, objectId: CoatyUUID) {
        self.externalId = externalId
        self.objectId = objectId
    }
    
    // MARK: - Codable methods.
    
    enum DiscoverKeys: String, CodingKey {
        case externalId
        case objectId
        case objectTypes
        case coreTypes
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscoverKeys.self)
        
        // Decode attributes.
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        objectId = try container.decodeIfPresent(CoatyUUID.self, forKey: .objectId)
        coreTypes = try container.decodeIfPresent([CoreType].self, forKey: .coreTypes)
        objectTypes = try container.decodeIfPresent([String].self, forKey: .objectTypes)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DiscoverKeys.self)
    
        // Encode attributes.
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(coreTypes, forKey: .coreTypes)
        try container.encodeIfPresent(objectTypes, forKey: .objectTypes)
    }
}
