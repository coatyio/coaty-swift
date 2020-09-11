//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoValueEvent.swift
//  CoatySwift
//
//

import Foundation

public class IoValueEvent: CommunicationEvent<IoValueEventData> {
    
    // MARK: - Internal attributes.
    
    /// The IoSource on which to publish the IO value.
    internal var ioSource: IoSource?
    
    /// Publication topic for this topic-based event.
    internal var topic: String?
    
    /// Binding-specific publication options.
    internal var options: [String: Any]?
    
    // MARK: - Static Factory Methods.
    
    /// Create an IoValueEvent instance for the given IO source and IO value.
    ///
    /// The IO value can be either JSON compatible or in binary format as a
    /// [Uint8] . The data format of the given IO value **must** conform to
    /// the `useRawIoValues` property of the given IO source.
    /// That means, if this property is set to true, the
    /// given value must be in binary format; if this property is set to false,
    /// the value must be a JSON encodable object. If this constraint is
    /// violated, an error is thrown.
    ///
    /// - Parameters:
    ///     - ioSource: the IoSource for publishing
    ///     - value: a  `[UInt8]` value
    ///     - options: binding-specific publication options
    /// - Throws: throws if the given value data format does not comply with the
    ///     `IoSource.useRawIoValues` option
    public static func with(ioSource: IoSource, value: [UInt8], options: [String: Any]) throws -> IoValueEvent {
        let ioValueEventData = IoValueEventData.createFrom(rawPayload: value)
        return try IoValueEvent(eventType: .IoValue, eventData: ioValueEventData, ioSource: ioSource)
    }
    
    /// Create an IoValueEvent instance for the given IO source and IO value.
    ///
    /// The IO value can be either JSON compatible or in binary format as a
    /// [Uint8] . The data format of the given IO value **must** conform to
    /// the `useRawIoValues` property of the given IO source.
    /// That means, if this property is set to true, the
    /// given value must be in binary format; if this property is set to false,
    /// the value must be a JSON encodable object. If this constraint is
    /// violated, an error is thrown.
    ///
    /// - Parameters:
    ///     - ioSource: the IoSource for publishing
    ///     - value: an JSON compatible `AnyCodable` value
    ///     - options: binding-specific publication options
    /// - Throws: throws if the given value data format does not comply with the
    ///     `IoSource.useRawIoValues` option
    public static func with(ioSource: IoSource, value: AnyCodable, options: [String: Any]) throws -> IoValueEvent {
        let ioValueEventData = IoValueEventData.createFrom(jsonPayload: value)
        return try IoValueEvent(eventType: .IoValue, eventData: ioValueEventData, ioSource: ioSource)
    }
    
    // MARK: - Initializers.
    
    fileprivate override init(eventType: CommunicationEventType, eventData: IoValueEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    fileprivate init(eventType: CommunicationEventType, eventData: IoValueEventData, ioSource: IoSource) throws {
        if let useRawIoValues = ioSource.useRawIoValues,
            (eventData.rawPayload != nil && !useRawIoValues) || (eventData.rawPayload == nil && useRawIoValues) {
            throw CoatySwiftError.InvalidArgument("Inconsistent options chosen for IoValueEvent (see: IoSource.useRawIoValue for reference)")
        }
        
        super.init(eventType: eventType, eventData: eventData)
        self.ioSource = ioSource
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

public class IoValueEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The payload represented as raw [UInt8]
    public var rawPayload: [UInt8]?
    
    /// The payload represented as JSON data.
    public var jsonPayload: AnyCodable?
    
    // MARK: - Initializers.
    
    private init(_ rawPayload: [UInt8]? = nil,
                 _ jsonPayload: AnyCodable? = nil) {
        super.init()
        self.rawPayload = rawPayload
        self.jsonPayload = jsonPayload
    }
    
    // MARK: - Static Factory methods.
    
    internal static func createFrom(rawPayload: [UInt8]?) -> IoValueEventData {
        return .init(rawPayload, nil)
    }
    
    internal static func createFrom(jsonPayload: AnyCodable) -> IoValueEventData {
        return .init(nil, jsonPayload)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case payload
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.rawPayload = try container.decode([UInt8].self, forKey: .payload)
        self.jsonPayload = try container.decodeIfPresent(AnyCodable.self, forKey: .payload)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.rawPayload, forKey: .payload)
        try container.encodeIfPresent(self.jsonPayload, forKey: .payload)
    }
}
