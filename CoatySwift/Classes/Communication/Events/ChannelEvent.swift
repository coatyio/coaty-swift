//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ChannelEvent.swift
//  CoatySwift
//
//

import Foundation

/// A Factory that creates ChannelEvents.
public class ChannelEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Create a ChannelEvent instance for delivering the given object.
    ///
    /// - Parameters:
    ///   - channelId: channel identifier string.
    ///   - object: the object to be channelized.
    ///   - privateData: application-specific options (optional).
    /// - Returns: a channel event that emits CoatyObjects that are part of a defined `ObjectFamily`.
    public func with(object: CoatyObject,
                     channelId: String,
                     privateData: [String: Any]? = nil) -> ChannelEvent<Family> {
        let channelEventData = ChannelEventData<Family>(object: object, privateData: privateData)
        return .init(eventSource: self.identity, eventData: channelEventData, channelId: channelId)
    }
    
    /// Create a ChannelEvent instance for delivering the given objects.
    ///
    /// - Parameters:
    ///   - channelId: channel identifier string.
    ///   - objects: the objects to be channelized
    ///   - privateData: application-specific options (optional)
    /// - Returns: a channel event that emits CoatyObjects that are part of a defined `ObjectFamily`.
    public func with(objects: [CoatyObject],
                     channelId: String,
                     privateData: [String: Any]? = nil) -> ChannelEvent<Family> {
        let channelEventData = ChannelEventData<Family>(objects: objects, privateData: privateData)
        return .init(eventSource: self.identity, eventData: channelEventData, channelId: channelId)
    }
    
}

/// ChannelEvent provides a generic implementation for broadcasting objects through a channel.
///
/// The class requires the definition of an `ObjectFamily`, e.g. `CoatyObjectFamily` or a
/// custom implementation of an `ObjectFamily` to support custom object types.
/// - NOTE: This class should preferably be initialized via its withObject() method.
public class ChannelEvent<Family: ObjectFamily>: CommunicationEvent<ChannelEventData<Family>> {
    
    var channelId: String?
    
    // MARK: - Initializers.
    
    fileprivate override init(eventSource: Component, eventData: ChannelEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }

    internal init(eventSource: Component, eventData: ChannelEventData<Family>, channelId: String) {
        
        if !CommunicationTopic.isValidEventTypeFilter(filter: channelId) {
            LogManager.log.warning("\(channelId) is not a valid channel identifier.")
        }
        
        super.init(eventSource: eventSource, eventData: eventData)
        self.channelId = channelId
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// ChannelEventData provides the entire message payload data for a
/// `ChannelEvent` including the object itself as well as associated private
/// data.
public class ChannelEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The object to be channelized.
    public var object: CoatyObject?
    
    /// The objects to be channelized.
    public var objects: [CoatyObject]?
    
    /// Application-specific options (optional).
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
