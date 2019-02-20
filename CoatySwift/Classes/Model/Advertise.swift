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
    // TODO: Those are currently ignored.
    var externalId: String?
    var parentObjectId: UUID?
    var assigneeUserId: UUID?
    var locationId: UUID?
    var isDeactivated: Bool?
    
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
    }
    
    required init(from decoder: Decoder) throws {
        // Unpack "object" key from container.
        let container = try decoder.container(keyedBy: ContainerCodingKeys.self)
        let object = try container.nestedContainer(keyedBy: AdvertiseCodingKeys.self, forKey: .object)
        
        // Decode attributes.
        objectId = try object.decode(UUID.self, forKey: .objectId)
        coreType = try object.decode(CoreType.self, forKey: .coreType)
        objectType = try object.decode(String.self, forKey: .objectType)
        name = try object.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        // Use "object" key for container.
        var container = encoder.container(keyedBy: ContainerCodingKeys.self)
        var object = container.nestedContainer(keyedBy: AdvertiseCodingKeys.self, forKey: .object)
        
        // Encode attributes.
        try object.encode(objectId, forKey: .objectId)
        try object.encode(coreType, forKey: .coreType)
        try object.encode(objectType, forKey: .objectType)
        try object.encode(name, forKey: .name)
    }
}
