//
//  ChannelEvent.swift
//  CoatySwift
//
//

import Foundation

/// ChannelEvent provides a generic implementation for all ChannelEvents.
///
/// The class requires the definition of a `ClassFamily`, e.g. `CoatyObjectFamily` or a
/// custom implementation of a `ClassFamily` to support custom object types.
/// - NOTE: This class should preferably initialized via its withObject() method.
public class ChannelEvent<Family: ObjectFamily>: CommunicationEvent<ChannelEventData<Family>> {
    
    var channelId: String?
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    private override init(eventSource: Component, eventData: ChannelEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Main initializer.
    ///
    /// - NOTE: Should not be called directly by application programmers. Needed because of
    /// extra parameter channelId.
    internal init(eventSource: Component, eventData: ChannelEventData<Family>, channelId: String) {
        super.init(eventSource: eventSource, eventData: eventData)
        self.channelId = channelId
    }
    
    // MARK: - Factory methods.

    /// Create a ChannelEvent instance for delivering the given object.
    ///
    /// - TODO: Missing documentation.
    /// - Parameters:
    ///   - eventSource: the event source component.
    ///   - channelId: channel identifier string.
    ///   - object: the object to be channelized.
    ///   - privateData: application-specific options (optional).
    /// - Returns: a channel event that emits CoatyObjects that are part of the `ClassFamily`.
    public static func withObject(eventSource: Component,
                           channelId: String,
                           object: CoatyObject,
                           privateData: [String: Any]? = nil) -> ChannelEvent<Family> {
        let channelEventData = ChannelEventData<Family>(object: object, privateData: privateData)
        return .init(eventSource: eventSource, eventData: channelEventData, channelId: channelId)
    }
    
    /// Create a ChannelEvent instance for delivering the given objects.
    ///
    /// - TODO: Missing documentation.
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - channelId: channel identifier string.
    ///   - objects: the objects to be channelized
    ///   - privateData: application-specific options (optional)
    /// - Returns: a channel event that emits CoatyObjects that are part of the `ClassFamily`.
    public static func withObjects(eventSource: Component,
                            channelId: String,
                            objects: [CoatyObject],
                            privateData: [String: Any]? = nil) -> ChannelEvent<Family> {
        let channelEventData = ChannelEventData<Family>(objects: objects, privateData: privateData)
        return .init(eventSource: eventSource, eventData: channelEventData, channelId: channelId)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// ChannelEventData provides a wrapper object that stores the entire message payload data
/// for a ChannelEvent including the object itself as well as the associated private data.
public class ChannelEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    public var object: CoatyObject?
    public var objects: [CoatyObject]?
    public var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    private init(_ object: CoatyObject?, _ objects: [CoatyObject]?, _ privateData: [String: Any]? = nil) {
        self.object = object
        self.objects = objects
        self.privateData = privateData
        super.init()
    }
    
    convenience init(object: CoatyObject, privateData: [String: Any]? = nil) {
        self.init(object, nil, privateData)
    }
    
    convenience init(objects: [CoatyObject], privateData: [String: Any]? = nil) {
        self.init(nil, objects, privateData)
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: CoatyObject) -> ChannelEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case objects
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decodeIfPresent(ClassWrapper<Family, CoatyObject>.self, forKey: .object)?.object
        self.objects = try container.decodeIfPresent(family: Family.self, forKey: .objects)
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.objects, forKey: .objects)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}
