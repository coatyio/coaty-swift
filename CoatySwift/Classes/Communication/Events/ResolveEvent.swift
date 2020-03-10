//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ResolveEvent.swift
//  CoatySwift
//

import Foundation

/// ResolveEvent provides a generic implementation for responding to a
/// `DiscoverEvent`.
public class ResolveEvent: CommunicationEvent<ResolveEventData> {
    
    // MARK: - Static Factory Methods.

    /// Create a ResolveEvent instance for resolving the given object and
    /// optional private data.
    ///
    /// - Parameters:
    ///   - object: the object to be resolved
    ///   - privateData: private data object (optional)
    /// - Returns: a Resolve event with the given parameters
    public static func with(object: CoatyObject, privateData: [String: Any]? = nil) -> ResolveEvent {
        let resolveEventData = ResolveEventData(object: object, privateData: privateData)
        return .init(eventType: .Resolve, eventData: resolveEventData)
    }
    
    /// Create a ResolveEvent instance for resolving the given related objects
    /// and optional private data.
    ///
    /// - Parameters:
    ///   - relatedObjects: related objects to be resolved
    ///   - privateData: private data object (optional)
    /// - Returns: a Query event with the given parameters
    public static func with(relatedObjects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> ResolveEvent {
        let resolveEventData = ResolveEventData(relatedObjects: relatedObjects, privateData: privateData)
        return .init(eventType: .Resolve, eventData: resolveEventData)
    }
    
    /// Create a ResolveEvent instance for resolving the given object, related
    /// object, and optional private data.
    ///
    /// - Parameters:
    ///   - object: the object to be resolved
    ///   - relatedObjects: related objects to be resolved
    ///   - privateData: private data object (optional)
    /// - Returns: a Query event with the given parameters
    public static func with(object: CoatyObject, relatedObjects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> ResolveEvent {
        let resolveEventData = ResolveEventData(object: object,
                                                relatedObjects: relatedObjects,
                                                privateData: privateData)
        return .init(eventType: .Resolve, eventData: resolveEventData)
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: ResolveEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// ResolveEventData provides the entire message payload data for a
/// `ResolveEvent` including the object itself as well as associated private
/// data.
public class ResolveEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The object to be resolved (may be nil if `relatedObjects` property is
    /// defined).
    public var object: CoatyObject?

    /// Related objects, i.e. child objects to be resolved (may be nil if
    /// `object` property is defined).
    public var relatedObjects: [CoatyObject]?

    ///Application-specific options (optional).
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
        self.object = try container.decodeIfPresent(AnyCoatyObjectDecodable.self, forKey: .object)?.object
        self.relatedObjects = try container.decodeIfPresent([AnyCoatyObjectDecodable].self, forKey: .relatedObjects)?.compactMap({ $0.object })
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
