//
//  ResolveEvent.swift
//  CoatySwift
//

import Foundation

/// ResolveEvent provides a generic implementation for all ResolveEvents.
/// Note that this class should preferably initialized via its withObject() method.
public class ResolveEvent<GenericCoatyObject: CoatyObject>: CommunicationEvent<ResolveEventData<GenericCoatyObject>> {
    
    // MARK: - Initializers.
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: ResolveEventData<GenericCoatyObject>) {
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
                           object: GenericCoatyObject,
                           privateData: [String: Any]? = nil) -> ResolveEvent<GenericCoatyObject> {
        let resolveEventData = ResolveEventData(object: object, privateData: privateData)
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
                                   relatedObjects: [GenericCoatyObject],
                                   privateData: [String: Any]? = nil) -> ResolveEvent<GenericCoatyObject> {
        let resolveEventData = ResolveEventData(relatedObjects: relatedObjects, privateData: privateData)
        return .init(eventSource: eventSource, eventData: resolveEventData)
    }
    
    static func withObjectAndRelatedObjects(eventSource: Component,
                                            object: GenericCoatyObject,
                                            relatedObjects: [GenericCoatyObject],
                                            privateData: [String: Any]? = nil) -> ResolveEvent<GenericCoatyObject> {
        let resolveEventData = ResolveEventData(object: object,
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
public class ResolveEventData<S: Resolve>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: S?
    var relatedObjects: [S]?
    var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    private init(_ object: S?, _ relatedObjects: [S]?, _ privateData: [String: Any]? = nil) {
        self.object = object
        self.relatedObjects = relatedObjects
        self.privateData = privateData
        super.init()
    }
    
    convenience init(object: S, privateData: [String: Any]? = nil) {
        self.init(object, nil, privateData)
    }
    
    convenience init(relatedObjects: [S], privateData: [String: Any]? = nil) {
        self.init(nil, relatedObjects, privateData)
    }
    
    convenience init(object: S, relatedObjects: [S], privateData: [String: Any]? = nil) {
        self.init(object, relatedObjects, privateData)
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: S) -> ResolveEventData {
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
        self.object = try container.decodeIfPresent(S.self, forKey: .object)
        self.relatedObjects = try container.decodeIfPresent([S].self, forKey: .relatedObjects)
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
