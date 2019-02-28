//
//  Discover-Resolve.swift
//  CoatySwift
//
//

import Foundation

/// Discover implements the common fields from a standard Coaty Discover message as defined in
/// https://coatyio.github.io/coaty-js/man/communication-protocol/
class Discover: Codable {
    
    // MARK: - Required attributes.
    
    var externalId: String?
    var objectId: UUID?
    var objectTypes: [String]?
    var coreTypes: [CoreType]?
    
    // MARK: - Initializers.
    
    /// Create a DiscoverEventData instance for the given IDs or types.
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
    init(externalId: String?, objectId: UUID?, objectTypes: [String]?, coreTypes: [CoreType]?) {
        self.externalId = externalId
        self.objectId = objectId
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
    }

    // MARK: - First condition in valid parameters.
    
    required init(objectId: UUID) {
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
    
    required init(objectId: UUID, externalId: String) {
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
    
    required init(externalId: String, objectId: UUID) {
        self.externalId = externalId
        self.objectId = objectId
    }
    
    enum DiscoverKeys: String, CodingKey {
        case externalId
        case objectId
        case objectTypes
        case coreTypes
    }
    
    private func hasValidParameters() -> Bool {
        return (
            (objectId != nil && externalId == nil && objectTypes == nil && coreTypes == nil)
        || (externalId != nil && objectId == nil && (objectTypes == nil || objectTypes != nil)  && (coreTypes == nil || coreTypes != nil))
        || (objectId != nil && externalId != nil && objectTypes == nil && coreTypes == nil)
        || (objectId == nil && externalId == nil && ((objectTypes == nil && coreTypes != nil) || (coreTypes == nil && objectTypes != nil)))
        )
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscoverKeys.self)
        
        // Decode attributes.
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        objectId = try container.decodeIfPresent(UUID.self, forKey: .objectId)
        coreTypes = try container.decodeIfPresent([CoreType].self, forKey: .coreTypes)
        objectTypes = try container.decodeIfPresent([String].self, forKey: .objectTypes)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DiscoverKeys.self)
    
        // Encode attributes.
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(coreTypes, forKey: .coreTypes)
        try container.encodeIfPresent(objectTypes, forKey: .objectTypes)
    }
}
