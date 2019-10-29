//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationEvent.swift
//  CoatySwift
//
//

import Foundation

/// CommunicationEvent is a generic supertype for all defined Coaty event types.
public class CommunicationEvent<T: CommunicationEventData>: Codable {
    
    // MARK: - Public attributes.
    
    public var type: CommunicationEventType?
    
    /// Event data that conforms to event type specific CommunicationEventData
    public var data: T

    public var source: Identity?
    public var sourceId: CoatyUUID?

    /// The associated user id of an inbound event. The value is always nil for
    /// outbound events. For inbound events, the value is nil if the event
    /// doesn't provide an associated user id in the topic.
    internal (set) public var userId: CoatyUUID?
    
    // MARK: - Initializer.
    
    init(eventSource: Identity, eventData: T) {
        self.source = eventSource
        self.sourceId = eventSource.objectId
        self.userId = nil
        self.data = eventData
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(T.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

// MARK: - Extension enable easy access to JSON representation of event data.

extension CommunicationEvent {
    public var json: String {
        get {
            return PayloadCoder.encode(self)
        }
    }
}

/// CommunicationEventData provides the generic type required by the CommunicationEvent.
/// Note that this cannot be a type alias since we need it to be an actual class.
public class CommunicationEventData: Codable {}
