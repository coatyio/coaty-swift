//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoNode.swift
//  CoatySwift
//
//

import Foundation

/// Represents an IO node with IO sources and IO actors for IO routing.
///
/// The name of an IO node equals the name of the IO context it is associated
/// with. An IO node also contains node-specific characteristics used by IO
/// routers to manage routes.
open class IoNode: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.IoNode.objectType, with: self)
    }
    
    // MARK: - Attributes.
    
    /// - Note: This comment refers to the property `name` of superclass CoatyObject,
    /// since Swift does not support overridden comments
    ///
    /// The name of the IO context, that this IO node is associated with.
    
    /// The IO sources belonging to this IO node.
    public var ioSources: [IoSource]
    
    /// The IO actors belonging to this IO node.
    public var ioActors: [IoActor]
    
    /// Node-specific characteristics defined by application (optional).
    /// Can be used by IO routers to manage routes.
    public var characteristics: [String: Any]?
    
    // MARK: - Initializers.
    
    /// Default initializer for an `IoNode` object.
    init(coreType: CoreType,
         objectType: String,
         objectId: CoatyUUID,
         name: String,
         ioSources: [IoSource],
         ioActors: [IoActor],
         characteristics: [String: Any]? = nil) {

        self.ioSources = ioSources
        self.ioActors = ioActors
        self.characteristics = characteristics
        super.init(coreType: coreType,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
    }
    
    // MARK: - Codable methods.
    
    enum IoNodeKeys: String, CodingKey, CaseIterable {
        case ioSources
        case ioActors
        case characteristics
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoNodeKeys.self)
        self.ioSources = try container.decode([IoSource].self, forKey: .ioSources)
        self.ioActors = try container.decode([IoActor].self, forKey: .ioActors)
        self.characteristics = try container.decodeIfPresent([String: Any].self, forKey: .characteristics)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: IoNodeKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoNodeKeys.self)
        try container.encode(ioSources, forKey: .ioSources)
        try container.encode(ioActors, forKey: .ioActors)
        try container.encodeIfPresent(characteristics, forKey: .characteristics)
    }
}
