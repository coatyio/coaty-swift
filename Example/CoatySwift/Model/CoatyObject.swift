//
//  CoatyObject.swift
//  CoatySwift
//
//

import Foundation

/// The base type of all objects in the Coaty object model. Application-specific object types
/// extend either CoatyObject directly or any of its derived core types.
class CoatyObject: Codable {
    
    // MARK: - Required attributes.
    
    /// The framework core type of the object, i.e. the name of the interface that defines
    /// the object's shape.
    var coreType: CoreType
    
    /// The concrete type name of the object. The name should be in a canonical form following
    /// the naming convention for Java packages to avoid name collisions. All framework core
    ///  types use the form coaty.<InterfaceName>, e.g. coaty.CoatyObject.
    var objectType: String
    
    /// Unique ID of the object.
    var objectId: UUID
    
    /// The name/description of the object.
    var name: String
    
    // MARK: - Optional attributes.
    
    /// External ID associated with this object (optional).
    var externalId: String?
    
    /// Unique ID of parent/superordinate object (optional).
    var parentObjectId: UUID?
    
    /// Unique ID of user/worker whom this object has been assigned to (optional).
    var assigneeUserId: UUID?
    
    /// Unique ID of Location object that this object has been associated with (optional).
    var locationId: UUID?
    
    /// Marks an object that is no longer in use. The concrete definition meaning of this
    /// property is defined by the application. The property value is optional and should
    /// default to false.
    var isDeactivated: Bool?
    
    // MARK: - Initializers.
    
    required init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        self.coreType = coreType
        self.objectId = objectId
        self.objectType = objectType
        self.name = name
    }
    
    // MARK: - Codable methods.
    
    enum CoatyObjectKeys: String, CodingKey {
        case objectId
        case coreType
        case objectType
        case name
        case externalId
        case parentObjectId
        case assigneeUserId
        case locationId
        case isDeactivated
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CoatyObjectKeys.self)
        
        // Decode required attributes.
        objectId = try container.decode(UUID.self, forKey: .objectId)
        coreType = try container.decode(CoreType.self, forKey: .coreType)
        objectType = try container.decode(String.self, forKey: .objectType)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode optional attributes.
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        parentObjectId = try container.decodeIfPresent(UUID.self, forKey: .parentObjectId)
        assigneeUserId = try container.decodeIfPresent(UUID.self, forKey: .assigneeUserId)
        locationId = try container.decodeIfPresent(UUID.self, forKey: .locationId)
        isDeactivated = try container.decodeIfPresent(Bool.self, forKey: .isDeactivated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoatyObjectKeys.self)
        
        // Encode required attributes.
        try container.encode(objectId, forKey: .objectId)
        try container.encode(coreType, forKey: .coreType)
        try container.encode(objectType, forKey: .objectType)
        try container.encode(name, forKey: .name)
        
        // Encode optional attributes.
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(parentObjectId, forKey: .parentObjectId)
        try container.encodeIfPresent(assigneeUserId, forKey: .assigneeUserId)
        try container.encodeIfPresent(locationId, forKey: .locationId)
        try container.encodeIfPresent(isDeactivated, forKey: .isDeactivated)
    }
}

// MARK: - Extension enable easy access to JSON representation of Coaty object.
extension CoatyObject {
    var json: String {
        get {
            return PayloadCoder.encode(self)
        }
    }
}
