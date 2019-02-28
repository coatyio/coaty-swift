//
//  DiscoverEvent.swift
//  CoatySwift
//
//

import Foundation

/// AdvertiseEvent provides a generic implementation for all AdvertiseEvents.
/// Note that this class should preferably initialized via its withObject() method.
class DiscoverEvent<GenericDiscover: Discover>: CommunicationEvent<DiscoverEventData<GenericDiscover>> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DiscoverEventData<GenericDiscover>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of and AdvertiseEvent with
    /// an object and privateData. Note that the event source should be the controller that
    /// creates the AdvertiseEvent.
    /// FIXME: Replace CoatyObject with Component object.
    /* static func withObject(eventSource: CoatyObject,
                           object: GenericDiscover,
                           privateData: [String: Any]? = nil) throws -> DiscoverEvent {
        
        let advertiseEventData = AdvertiseEventData(object: object, privateData: privateData)
        return try .init(eventSource: eventSource, eventData: advertiseEventData)
    }*/
    
    static func withExternalId(eventSource: Component, externalId: String) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(externalId: externalId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withExternalIdAndCoreTypes(eventSource: Component, externalId: String, coreTypes: [CoreType]) -> DiscoverEvent {
        let discover = GenericDiscover(externalId: externalId, coreTypes: coreTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withExternalIdAndObjectTypes(eventSource: Component, externalId: String, objectTypes: [String]) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(externalId: externalId, objectTypes: objectTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withObjectId(eventSource: Component, objectId: UUID) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(objectId: objectId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withExternalAndObjectId(eventSource: Component, externalId: String, objectId: UUID) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(objectId: objectId, externalId: externalId)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withCoreTypes(eventSource: Component, coreTypes: [CoreType]) -> DiscoverEvent<GenericDiscover> {
        let discover = GenericDiscover(coreTypes: coreTypes)
        let discoverEventData = DiscoverEventData.createFrom(eventData: discover)
        return DiscoverEvent(eventSource: eventSource, eventData: discoverEventData)
    }
    
    static func withObjectTypes(eventSource: Component, objectTypes: [String]) -> DiscoverEvent<GenericDiscover> {
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


/// AdvertiseEventData provides a wrapper object that stores the entire message payload data
/// for an AdvertiseEvent including the object itself as well as the associated private data.
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
