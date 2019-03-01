//
//  DiscoverEvent.swift
//  CoatySwift
//
//

import Foundation

/// DiscoverEvent provides a generic implementation for all DiscoverEvents.
/// Note that this class should preferably initialized via its withObject() method.
class DiscoverEvent<GenericDiscover: Discover>: CommunicationEvent<DiscoverEventData<GenericDiscover>> {
    
    // TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DiscoverEventData<GenericDiscover>) {
        super.init(eventSource: eventSource, eventData: eventData)
        eventType = .Discover
    }
    
    // MARK: - Accessible Initialiser for DiscoverEvent.
    
    
    /// Create a DiscoverEvent instance for discovering objects with the given external Id.
    ///
    /// - Parameters:
    ///     - eventSource: the event source component
    ///     - externalId: the external ID to discover
    static func withExternalId(eventSource: Component,
                               externalId: String) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(externalId: externalId)
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
    static func withExternalIdAndCoreTypes(eventSource: Component,
                                           externalId: String,
                                           coreTypes: [CoreType]) -> DiscoverEvent {
        let discover = GenericDiscover(externalId: externalId, coreTypes: coreTypes)
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
    static func withExternalIdAndObjectTypes(eventSource: Component,
                                             externalId: String,
                                             objectTypes: [String]) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(externalId: externalId, objectTypes: objectTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object Id.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectId: the object ID to discover
    static func withObjectId(eventSource: Component,
                             objectId: UUID) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(objectId: objectId)
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
    static func withExternalAndObjectId(eventSource: Component,
                                        externalId: String,
                                        objectId: UUID) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(objectId: objectId, externalId: externalId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given core types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - coreTypes: coreTypes the core types to discover
    static func withCoreTypes(eventSource: Component,
                              coreTypes: [CoreType]) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(coreTypes: coreTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    /// Create a DiscoverEvent instance for discovering objects with the given object types.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - objectTypes: the object types to discover
    static func withObjectTypes(eventSource: Component,
                                objectTypes: [String]) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(objectTypes: objectTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// DiscoverEventData provides a wrapper object that stores the entire message payload data
/// for a DiscoverEventData.
class DiscoverEventData<S: Discover>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: S
    
    // MARK: - Initializers.
    
    private init(object: S) {
        self.object = object
        super.init()
    }
    
    static func createFrom(eventData: S) -> DiscoverEventData {
        return DiscoverEventData(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.object = try container.decode(S.self)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.object)
    }
}
