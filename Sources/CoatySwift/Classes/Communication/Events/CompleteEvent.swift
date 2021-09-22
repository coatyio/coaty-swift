//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CompleteEvent.swift
//  CoatySwift
//

import Foundation

/// CompleteEvent provides a generic implementation for responding to an
/// `UpdateEvent`.
public class CompleteEvent: CommunicationEvent<CompleteEventData> {

    // MARK: - Static Factory Methods.

    /// Create a CompleteEvent instance for the given object.
    ///
    /// - Parameters:
    ///   - object: the updated object
    ///   - privateData: application-specific options (optional)
    /// - Returns: a Complete event with the given parameters
    public static func with(object: CoatyObject, privateData: [String: Any]? = nil) -> CompleteEvent {
        let completeEventData = CompleteEventData(object, privateData)
        return .init(eventType: .Complete, eventData: completeEventData)
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: CompleteEventData) {
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

/// CompleteEventData provides the entire message payload data for a
/// `CompleteEvent` including the object itself as well as associated private
/// data.
public class CompleteEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The updated object.
    public var object: CoatyObject?

    /// Application-specific options (optional).
    public var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    internal init(_ object: CoatyObject?, _ privateData: [String: Any]? = nil) {
        self.object = object
        self.privateData = privateData
        super.init()
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decodeIfPresent(AnyCoatyObjectDecodable.self, forKey: .object)?.object
        self.privateData = try container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}

