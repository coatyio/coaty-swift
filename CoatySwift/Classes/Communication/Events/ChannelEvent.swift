//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ChannelEvent.swift
//  CoatySwift
//
//

import Foundation

/// ChannelEvent provides a generic implementation for broadcasting objects
/// through a channel.
public class ChannelEvent: CommunicationEvent<ChannelEventData> {
    
    // MARK: - Internal attributes.
    
    var channelId: String?

    // MARK: - Static Factory Methods.

    /// Create a ChannelEvent instance for delivering the given object.
    ///
    /// The channel identifier must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///   - object: the object to be channelized.
    ///   - channelId: channel identifier string
    ///   - privateData: application-specific options (optional)
    /// - Returns: a Channel event with the given parameters
    /// - Throws: if channel identifier is invalid
    public static func with(object: CoatyObject,
                            channelId: String,
                            privateData: [String: Any]? = nil) throws -> ChannelEvent {
        let channelEventData = ChannelEventData(object: object, privateData: privateData)
        return try .init(eventType: .Channel, eventData: channelEventData, channelId: channelId)
    }
    
    /// Create a ChannelEvent instance for delivering the given objects.
    ///
    /// The channel identifier must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///   - objects: the objects to be channelized
    ///   - channelId: channel identifier string
    ///   - privateData: application-specific options (optional)
    /// - Returns: a Channel event with the given parameters
    /// - Throws: if channel identifier is invalid
    public static func with(objects: [CoatyObject],
                            channelId: String,
                            privateData: [String: Any]? = nil) throws -> ChannelEvent {
        let channelEventData = ChannelEventData(objects: objects, privateData: privateData)
        return try .init(eventType: .Channel, eventData: channelEventData, channelId: channelId)
    }
    
    // MARK: - Initializers.
    
    fileprivate override init(eventType: CommunicationEventType, eventData: ChannelEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }

    fileprivate init(eventType: CommunicationEventType, eventData: ChannelEventData, channelId: String) throws {
        guard CommunicationTopic.isValidEventTypeFilter(filter: channelId) else {
            throw CoatySwiftError.InvalidArgument("Invalid channel identifier.")
        }
        
        super.init(eventType: eventType, eventData: eventData)
        self.typeFilter = channelId
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
public class ChannelEventData: CommunicationEventData {
    
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
        self.object = try container.decodeIfPresent(AnyCoatyObjectDecodable.self, forKey: .object)?.object
        self.objects = try container.decodeIfPresent([AnyCoatyObjectDecodable].self, forKey: .objects)?.compactMap({ $0.object })
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
