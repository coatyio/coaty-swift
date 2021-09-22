//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Snapshot.swift
//  CoatySwift
//

import Foundation

/// Represents a snapshot in time of the state of any Coaty object.
open class Snapshot: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.Snapshot.objectType, with: self)
    }
    
    /// Coaty compatible timestamp when snapshot was issued/created.
    /// (see `CoatyTimestamp.nowMillis()` or `CoatyTimestamp.dateMillis()`)
    public var creationTimestamp: Double
    
    /// UUID of creator of this snapshot.
    public var creatorId: CoatyUUID
    
    /// The Coaty object captured by this snapshot.
    public var object: CoatyObject
    
    /// Tags associated with this snapshot (optional). They can be used on
    /// retrieval to identify different purposes of the snapshot.
    public var tags: [String]?
    
    /// Default initializer for a `Snapshot` object.
    public init(creationTimestamp: Double,
         creatorId: CoatyUUID,
         tags: [String]? = nil,
         object: CoatyObject,
         name: String = "SnapshotObject",
         objectType: String = Snapshot.objectType,
         objectId: CoatyUUID = .init()) {
        self.creationTimestamp = creationTimestamp
        self.creatorId = creatorId
        self.tags = tags
        self.object = object
        super.init(coreType: .Snapshot,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
    }
    
    enum SnapshotCodingKeys: String, CodingKey, CaseIterable {
        case creationTimestamp
        case creatorId
        case object
        case tags
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SnapshotCodingKeys.self)
        
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.creatorId = try container.decode(CoatyUUID.self, forKey: .creatorId)
        self.object = try container.decode(AnyCoatyObjectDecodable.self, forKey: .object).object
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: SnapshotCodingKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: SnapshotCodingKeys.self)
        try container.encode(creatorId.string, forKey: .creatorId)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(object, forKey: .object)
        try container.encodeIfPresent(tags, forKey: .tags)
    }
}

    
