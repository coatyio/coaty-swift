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
        let discover = Discover(externalId: externalId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
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
        let discover = Discover(externalId: externalId, coreTypes: coreTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
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
        let discover = Discover(externalId: externalId, objectTypes: objectTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object Id.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectId: the object ID to discover
    public static func withObjectId(eventSource: Component,
                                    objectId: UUID) -> DiscoverEvent<Family> {
        let discover = Discover(objectId: objectId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
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
                                               objectId: UUID) -> DiscoverEvent<Family> {
        let discover = Discover(objectId: objectId, externalId: externalId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given core types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - coreTypes: coreTypes the core types to discover
    public static func withCoreTypes(eventSource: Component,
                                     coreTypes: [CoreType]) -> DiscoverEvent<Family> {
        let discover = Discover(coreTypes: coreTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectTypes: the object types to discover
    public static func withObjectTypes(eventSource: Component,
                                       objectTypes: [String]) -> DiscoverEvent<Family> {
        let discover = Discover(objectTypes: objectTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
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
    
    // MARK: - Public attributes.
    
    public var object: Discover
    
    // MARK: - Initializers.
    
    private init(object: Discover) {
        self.object = object
        super.init()
    }
    
    static func createFrom(eventData: Discover) -> DiscoverEventData {
        return DiscoverEventData(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.object = try container.decode(Discover.self)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.object)
    }
}
