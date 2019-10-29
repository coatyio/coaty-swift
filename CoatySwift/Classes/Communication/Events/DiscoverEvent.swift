//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DiscoverEvent.swift
//  CoatySwift
//
//

import Foundation

/// A Factory that creates DiscoverEvents.
public class DiscoverEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id.
    ///
    /// - Parameters:
    ///     - externalId: the external ID to discover
    public func with(externalId: String) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// core types.
    ///
    /// - Parameters:
    ///     - externalId: the external ID to discover
    ///     - coreTypes: an array of core types to discover
    public func with(externalId: String, coreTypes: [CoreType]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, coreTypes: coreTypes)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// object types.
    ///
    /// - Parameters:
    ///   - externalId: the external ID to discover.
    ///   - objectTypes: an array of object types to discover.
    public func with(externalId: String, objectTypes: [String]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectTypes: objectTypes)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object Id.
    ///
    /// - Parameters:
    ///   - objectId: the object ID to discover
    public func with(objectId: CoatyUUID) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(objectId: objectId)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// object Id.
    ///
    /// - Parameters:
    ///   - externalId: the external ID to discover
    ///   - objectId: the object ID to discover
    public func with(externalId: String,
                     objectId: CoatyUUID) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectId: objectId)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given core types.
    ///
    /// - Parameters:
    ///   - coreTypes: coreTypes the core types to discover
    public func with(coreTypes: [CoreType]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(coreTypes: coreTypes)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object types.
    ///
    /// - Parameters:
    ///   - objectTypes: the object types to discover
    public func with(objectTypes: [String]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(objectTypes: objectTypes)
        return DiscoverEvent(eventSource: self.identity, eventData: discoverEventData)
    }
}

/// DiscoverEvent provides a generic implementation for discovering CoatyObjects.
/// Note that this class should preferably be initialized via its withObject() method.
/// - NOTE: DiscoverEvents also need an object family. This is because Discover-Resolve
/// includes both sending a discover and receiving a family of resolves, as well as
/// reacting to a family of discovers and sending out particular resolves.
public class DiscoverEvent<Family: ObjectFamily>: CommunicationEvent<DiscoverEventData> {
    
    // MARK: - Internal attributes.
    
    /// Provides a resolve handler for reacting to discover events.
    internal var resolveHandler: ((ResolveEvent<Family>) -> Void)?
    
    
    /// Respond to an observed Discover event by returning the given event.
    ///
    /// - Parameter resolveEvent: a Resolve event.
    public func resolve(resolveEvent: ResolveEvent<Family>) {
        if let resolveHandler = resolveHandler {
            resolveHandler(resolveEvent)
        }
    }

    override init(eventSource: Identity, eventData: DiscoverEventData) {
        super.init(eventSource: eventSource, eventData: eventData)
        type = .Discover
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
    
    /// Validates response parameters of Resolve event against the corresponding
    /// discover event.
    /// - Parameter eventData: event data for Resolve response event
    /// - Returns: false and logs if the given Resolve event data does not
    ///   correspond to the event data of this Discover event.
    internal func ensureValidResponseParameters(eventData: ResolveEventData<Family>) -> Bool {
        if self.data.coreTypes != nil && eventData.object != nil {
            if !((self.data.coreTypes?.contains(eventData.object!.coreType))!) {
                LogManager.log.warning("resolved coreType not contained in Discover coreTypes")
                return false
            }
        }
        
        if self.data.objectTypes != nil && eventData.object != nil {
            if !((self.data.objectTypes?.contains(eventData.object!.objectType))!) {
                LogManager.log.warning("resolved objectType not contained in Discover objectTypes")
                return false
            }
        }
            
        if self.data.objectId != nil && eventData.object != nil {
            if self.data.objectId != eventData.object?.objectId {
                LogManager.log.warning("resolved object's UUID doesn't match Discover objectId")
                return false
            }
        }
        
        if self.data.externalId != nil && eventData.object != nil {
            if self.data.externalId != eventData.object!.externalId {
                LogManager.log.warning("resolved object's external ID doesn't match Discover externalId")
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
