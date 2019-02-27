//
//  Advertise.swift
//  CoatySwift
//
//

import Foundation

/// Advertise implements the common fields from a standard Coaty Advertise message as defined in
/// https://coatyio.github.io/coaty-js/man/communication-protocol/
class Advertise: CoatyObject {
    
    // MARK: - Required attributes.
    
    var coreType: CoreType
    var objectType: String
    var objectId: UUID
    var name: String
    
    // MARK: - Optional attributes.
    
    var externalId: String?
    var parentObjectId: UUID?
    var assigneeUserId: UUID?
    var locationId: UUID?
    var isDeactivated: Bool?
    
    // MARK: - Initializers.
    
    init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        self.coreType = coreType
        self.objectId = objectId
        self.objectType = objectType
        self.name = name
    }
    
    // MARK: - Codable methods.
    
    enum AdvertiseCodingKeys: String, CodingKey {
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
        let container = try decoder.container(keyedBy: AdvertiseCodingKeys.self)
        
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
        var container = encoder.container(keyedBy: AdvertiseCodingKeys.self)
        
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
