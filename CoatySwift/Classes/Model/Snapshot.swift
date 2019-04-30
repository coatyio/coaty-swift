//
//  Snapshot.swift
//  CoatySwift
//

import Foundation

/// Represents a snapshot in time of the state of any Coaty object.
open class Snapshot<Family: ObjectFamily>: CoatyObject {
    
    /// Timestamp when snapshot was issued/created.
    /// Value represents the number of milliseconds since the epoc in UTC
    /// Date()).
    public var creationTimestamp: Double
    
    /// UUID of controller which created this snapshot.
    public var creatorId: CoatyUUID
    
    /// Deep copy of the object and its state stored in this snapshot.
    public var object: CoatyObject
    
    /// Tags associated with this snapshot (optional). They can be used on
    /// retrieval to identify different purposes of the snapshot.
    public var tags: [String]?
    
    
    public init(creationTimestamp: Double,
         creatorId: CoatyUUID,
         tags: [String]? = nil,
         object: CoatyObject,
         objectId: CoatyUUID = .init(),
         name: String) {
        self.creationTimestamp = creationTimestamp
        self.creatorId = creatorId
        self.tags = tags
        self.object = object
        super.init(coreType: .Snapshot,
                   objectType: CoatyObjectFamily.snapshot.rawValue,
                   objectId: objectId,
                   name: name)
    }
    
    public required init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    enum CodingKeys: String, CodingKey {
        case creationTimestamp
        case creatorId
        case object
        case tags
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.creatorId = try container.decode(CoatyUUID.self, forKey: .creatorId)
        
        guard let object = try container.decode(ClassWrapper<Family, CoatyObject>.self,
                                                forKey: .object).object else {
            throw CoatySwiftError.DecodingFailure("Object field in Snapshot not set.")
        }
        
        self.object = object
        
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(creatorId.string, forKey: .creatorId)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(object, forKey: .object)
        try container.encodeIfPresent(tags, forKey: .tags)
    }
}

    
