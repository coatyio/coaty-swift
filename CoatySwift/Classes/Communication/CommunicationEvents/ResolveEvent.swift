//
//  ResolveEvent.swift
//  CoatySwift
//

import Foundation

/// ResolveEvent provides a generic implementation for all ResolveEvents.
/// Note that this class should preferably initialized via its withObject() method.
public class ResolveEvent<Family: ClassFamily>: CommunicationEvent<ResolveEventData<Family>> {
    
    // MARK: - Initializers.
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: ResolveEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Factory methods.
    
    /// Create a ResolveEvent instance for resolving the given object.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - object: the object to be resolved
    ///   - privateData: private data object (optional)
    /// - Returns: a resolve event that emits CoatyObjects.
    static func withObject(eventSource: Component,
                           object: CoatyObject,
                           privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(object: object, privateData: privateData)
        return .init(eventSource: eventSource, eventData: resolveEventData)
    }
    
    /// Create a ResolveEvent instance for resolving the given object.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - relatedObjects: related objects to be resolved (optional)
    ///   - privateData: private data object (optional)
    /// - Returns: a resolve event that emits CoatyObjects.
    static func withRelatedObjects(eventSource: Component,
                                   relatedObjects: [CoatyObject],
                                   privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(relatedObjects: relatedObjects, privateData: privateData)
        return .init(eventSource: eventSource, eventData: resolveEventData)
    }
    
    static func withObjectAndRelatedObjects(eventSource: Component,
                                            object: CoatyObject,
                                            relatedObjects: [CoatyObject],
                                            privateData: [String: Any]? = nil) -> ResolveEvent<Family> {
        let resolveEventData = ResolveEventData<Family>(object: object,
                                                relatedObjects: relatedObjects,
                                                privateData: privateData)
        return .init(eventSource: eventSource, eventData: resolveEventData)
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
public class ResolveEventData<Family: ClassFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: CoatyObject?
    var relatedObjects: [CoatyObject]?
    var privateData: [String: Any]?
    
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
