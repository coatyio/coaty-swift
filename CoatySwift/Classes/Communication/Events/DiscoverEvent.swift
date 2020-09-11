//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DiscoverEvent.swift
//  CoatySwift
//
//

import Foundation

/// DiscoverEvent provides a generic implementation for discovering CoatyObjects.
/// Note that this class should preferably be initialized by its withObject() method.
public class DiscoverEvent: CommunicationEvent<DiscoverEventData> {
    
    // MARK: - Internal attributes.
    
    /// Provides a resolve handler for reacting to Discover events.
    internal var resolveHandler: ((ResolveEvent) -> Void)?

    // MARK: - Static Factory Methods.

    /// Create a DiscoverEvent instance for discovering objects with the given
    /// external Id.
    ///
    /// - Parameters:
    ///     - externalId: the external ID to discover
    public static func with(externalId: String) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(externalId: externalId)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// external Id and core types.
    ///
    /// - Parameters:
    ///     - externalId: the external ID to discover
    ///     - coreTypes: an array of core types to discover
    public static func with(externalId: String, coreTypes: [CoreType]) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(externalId: externalId, coreTypes: coreTypes)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// external Id and object types.
    ///
    /// - Parameters:
    ///   - externalId: the external ID to discover.
    ///   - objectTypes: an array of object types to discover.
    public static func with(externalId: String, objectTypes: [String]) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectTypes: objectTypes)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// object Id.
    ///
    /// - Parameters:
    ///   - objectId: the object ID to discover
    public static func with(objectId: CoatyUUID) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(objectId: objectId)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// external Id and object Id.
    ///
    /// - Parameters:
    ///   - externalId: the external ID to discover
    ///   - objectId: the object ID to discover
    public static func with(externalId: String,
                     objectId: CoatyUUID) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectId: objectId)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// core types.
    ///
    /// - Parameters:
    ///   - coreTypes: coreTypes the core types to discover
    public static func with(coreTypes: [CoreType]) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(coreTypes: coreTypes)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given
    /// object types.
    ///
    /// - Parameters:
    ///   - objectTypes: the object types to discover
    public static func with(objectTypes: [String]) -> DiscoverEvent {
        let discoverEventData = DiscoverEventData(objectTypes: objectTypes)
        return .init(eventType: .Discover, eventData: discoverEventData)
    }

    /// Respond to a Discover event with the given Resolve event.
    ///
    /// - Parameter resolveEvent: a Resolve event.
    public func resolve(resolveEvent: ResolveEvent) {
        if let resolveHandler = resolveHandler {
            resolveHandler(resolveEvent)
        }
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: DiscoverEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
    
    /// Validates response parameters of Resolve event against the corresponding
    /// Discover event.
    /// - Parameter eventData: event data for Resolve response event
    /// - Returns: false and logs if the given Resolve event data does not
    ///   correspond to the event data of this Discover event.
    internal func ensureValidResponseParameters(eventData: ResolveEventData) -> Bool {
        if self.data.coreTypes != nil && eventData.object != nil {
            if !((self.data.coreTypes?.contains(eventData.object!.coreType))!) {
                LogManager.log.debug("resolved coreType not contained in Discover coreTypes")
                return false
            }
        }
        
        if self.data.objectTypes != nil && eventData.object != nil {
            if !((self.data.objectTypes?.contains(eventData.object!.objectType))!) {
                LogManager.log.debug("resolved objectType not contained in Discover objectTypes")
                return false
            }
        }
            
        if self.data.objectId != nil && eventData.object != nil {
            if self.data.objectId != eventData.object?.objectId {
                LogManager.log.debug("resolved object's UUID doesn't match Discover objectId")
                return false
            }
        }
        
        if self.data.externalId != nil && eventData.object != nil {
            if self.data.externalId != eventData.object!.externalId {
                LogManager.log.debug("resolved object's external ID doesn't match Discover externalId")
                return false
            }
        }
        
        return true
    }
    
}

/// DiscoverEventData provides the entire message payload data of a
/// `DiscoverEvent`.
public class DiscoverEventData: CommunicationEventData {
    
    // MARK: - Attributes.
    
    /// The external ID of the object(s) to be discovered or nil.
    ///
    /// - NOTE: externalId can be used exclusively or in combination with objectId property.
    /// Only if used exclusively it can be combined with objectTypes or coreTypes properties.
    public var externalId: String?

    /// The object UUID of the object to be discovered or nil.
    ///
    /// - NOTE: objectId can be used exclusively or in combination with externalId property.
    ///  Must not be used in combination with objectTypes or coreTypes properties.
    public var objectId: CoatyUUID?

    /// Restrict objects by object types (logical OR).
    ///
    /// - NOTE: objectTypes must not be used with objectId property.
    /// Should not be used in combination with coreTypes.
    public var objectTypes: [String]?

    /// Restrict objects by core types (logical OR).
    ///
    /// - NOTE: coreTypes must not be used with objectId property.
    /// Should not be used in combination with objectTypes.
    public var coreTypes: [CoreType]?

    // MARK: - Initializers.
    
    private init(externalId: String?, objectId: CoatyUUID?, objectTypes: [String]?, coreTypes: [CoreType]?) {
        self.externalId = externalId
        self.objectId = objectId
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
        super.init()
    }
    
    // MARK: - Convenience initializers that cover all permitted parameter combinations.
    
    required init(objectId: CoatyUUID) {
        self.objectId = objectId
        super.init()
    }
    
    required init(externalId: String, objectTypes: [String], coreTypes: [CoreType]) {
        self.externalId = externalId
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
        super.init()
    }
    
    required init(externalId: String, objectTypes: [String]) {
        self.externalId = externalId
        self.objectTypes = objectTypes
        super.init()
    }
    
    required init(externalId: String, coreTypes: [CoreType]) {
        self.externalId = externalId
        self.coreTypes = coreTypes
        super.init()
    }
    
    required init(externalId: String) {
        self.externalId = externalId
        super.init()
    }
    
    required init(objectId: CoatyUUID, externalId: String) {
        self.objectId = objectId
        self.externalId = externalId
        super.init()
    }
    
    required init(coreTypes: [CoreType], objectTypes: [String]) {
        self.coreTypes = coreTypes
        self.objectTypes = objectTypes
        super.init()
    }
    
    required init(coreTypes: [CoreType]) {
        self.coreTypes = coreTypes
        super.init()
    }
    
    required init(objectTypes: [String]) {
        self.objectTypes = objectTypes
        super.init()
    }
    
    required init(externalId: String, objectId: CoatyUUID) {
        self.externalId = externalId
        self.objectId = objectId
        super.init()
    }
    
    /// Determines whether the given CoreType is compatible with this event data.
    /// - Parameters:
    ///     - coreType name of the core type to check
    /// - Returns: true, if the specified core type is contained in the coreTypes property;
    /// false otherwise.
    public func isCoreTypeCompatible(_ coreType: CoreType) -> Bool {
        return self.coreTypes?.contains(coreType) ?? false
    }
    
    /// Determines whether the given ObjectType is compatible with this event data.
    /// - Returns: true, if the specified type is contained in the objectTypes property;
    /// false otherwise.
    /// 
    /// - Parameter objectType: name of the object type to check
    public func isObjectTypeCompatible(objectType: String) -> Bool {
        return self.objectTypes != nil
            && (self.objectTypes!.first(where: { t -> Bool in t == objectType }) != nil)
    }
    
    ///  Determines whether this event data discovers an object based on an object ID.
    public func isDiscoveringObjectId() -> Bool {
        return externalId == nil && objectId != nil
    }

    /// Determines whether this event data discovers an object based on an external ID 
    /// but not an object ID.
    public func isDiscoveringExternalId() -> Bool {
        return self.externalId != nil && self.objectId == nil
    }
    
    /// Determines whether this event data discovers an object based on both
    /// external ID and object ID.
    public func isDiscoveringExternalAndObjectId() -> Bool {
        return self.externalId != nil && self.objectId != nil
    }
    
    /// Determines whether this event data discovers an object based
    /// on types only.
    public func isDiscoveringTypes() -> Bool {
        return self.externalId == nil && self.objectId == nil
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
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: DiscoverKeys.self)
        
        // Encode attributes.
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(coreTypes, forKey: .coreTypes)
        try container.encodeIfPresent(objectTypes, forKey: .objectTypes)
    }
    
}
