//
//  DiscoverEvent.swift
//  CoatySwift
//
//

import Foundation

/// A Factory that creates DiscoverEvents.
public class DisoverEventFactory<Family: ObjectFamily> {
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id.
    ///
    /// - Parameters:
    ///     - eventSource: the event source component
    ///     - externalId: the external ID to discover
    public static func withExternalId(eventSource: Component,
                                      externalId: String) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// core types.
    ///
    /// - Parameters:
    ///     - eventSource: the event source component
    ///     - externalId: the external ID to discover
    ///     - coreTypes: an array of core types to discover
    public static func withExternalIdAndCoreTypes(eventSource: Component,
                                                  externalId: String,
                                                  coreTypes: [CoreType]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, coreTypes: coreTypes)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// object types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component.
    ///   - externalId: the external ID to discover.
    ///   - objectTypes: an array of object types to discover.
    public static func withExternalIdAndObjectTypes(eventSource: Component,
                                                    externalId: String,
                                                    objectTypes: [String]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectTypes: objectTypes)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object Id.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectId: the object ID to discover
    public static func withObjectId(eventSource: Component,
                                    objectId: CoatyUUID) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(objectId: objectId)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id and
    /// object Id.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - externalId: the external ID to discover
    ///   - objectId: the object ID to discover
    public static func withExternalAndObjectId(eventSource: Component,
                                               externalId: String,
                                               objectId: CoatyUUID) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(externalId: externalId, objectId: objectId)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given core types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - coreTypes: coreTypes the core types to discover
    public static func withCoreTypes(eventSource: Component,
                                     coreTypes: [CoreType]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(coreTypes: coreTypes)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectTypes: the object types to discover
    public static func withObjectTypes(eventSource: Component,
                                       objectTypes: [String]) -> DiscoverEvent<Family> {
        let discoverEventData = DiscoverEventData(objectTypes: objectTypes)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
}

/// DiscoverEvent provides a generic implementation for all DiscoverEvents.
/// Note that this class should preferably initialized via its withObject() method.
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
    
    // TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DiscoverEventData) {
        super.init(eventSource: eventSource, eventData: eventData)
        eventType = .Discover
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// DiscoverEventData provides a wrapper object that stores the entire message payload data
/// for a DiscoverEventData.
public class DiscoverEventData: CommunicationEventData {
    
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
