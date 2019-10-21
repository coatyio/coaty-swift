//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ResolveEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates ResolveEvents.
public class ResolveEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Create a ResolveEvent instance for resolving the given object.
    ///
    /// - Parameters:
    ///   - object: the object to be resolved
    ///   - privateData: private data object (optional)
    /// - Returns: a resolve event that emits CoatyObjects.
    public func with(object: CoatyObject, privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(object: object, privateData: privateData)
        return .init(eventSource: self.identity, eventData: resolveEventData)
    }
    
    /// Create a ResolveEvent instance for resolving the given object.
    ///
    /// - Parameters:
    ///   - relatedObjects: related objects to be resolved (optional)
    ///   - privateData: private data object (optional)
    /// - Returns: a resolve event that emits CoatyObjects.
    public func with(relatedObjects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(relatedObjects: relatedObjects, privateData: privateData)
        return .init(eventSource: self.identity, eventData: resolveEventData)
    }
    
    public func with(object: CoatyObject, relatedObjects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(object: object,
                                                        relatedObjects: relatedObjects,
                                                        privateData: privateData)
        return .init(eventSource: self.identity, eventData: resolveEventData)
    }
}

/// ResolveEvent provides a generic implementation for all ResolveEvents.
/// Note that this class should preferably be initialized via its withObject() method.
/// - NOTE: ResolveEvents also need an object family. This is because Discover-Resolve
/// includes both sending a discover and receiving a family of resolves, as well as
/// reacting to a family of discovers and sending out particular resolves.
public class ResolveEvent<Family: ObjectFamily>: CommunicationEvent<ResolveEventData<Family>> {
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: ResolveEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// ResolveEventData provides a wrapper object that stores the entire message payload data
/// for a ResolveEvent including the object itself as well as the associated private data.
public class ResolveEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    public var object: CoatyObject?
    public var relatedObjects: [CoatyObject]?
    public var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    private init(_ object: CoatyObject?, _ relatedObjects: [CoatyObject]?, _ privateData: [String: Any]? = nil) {
        self.object = object
        self.relatedObjects = relatedObjects
        self.privateData = privateData
        super.init()
    }
    
    convenience init(object: CoatyObject, privateData: [String: Any]? = nil) {
        self.init(object, nil, privateData)
    }
    
    convenience init(relatedObjects: [CoatyObject], privateData: [String: Any]? = nil) {
        self.init(nil, relatedObjects, privateData)
    }
    
    convenience init(object: CoatyObject, relatedObjects: [CoatyObject], privateData: [String: Any]? = nil) {
        self.init(object, relatedObjects, privateData)
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: CoatyObject) -> ResolveEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case relatedObjects
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decodeIfPresent(ClassWrapper<Family, CoatyObject>.self, forKey: .object)?.object
        self.relatedObjects = try container.decodeIfPresent(family: Family.self, forKey: .relatedObjects)
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.relatedObjects, forKey: .relatedObjects)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}
