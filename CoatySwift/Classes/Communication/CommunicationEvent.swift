//
//  CommunicationEvent.swift
//  CoatySwift
//
//

import Foundation

/// CommunicationEvent is a generic supertype for AdvertiseEvent, DeadvertiseEvent etc.
public class CommunicationEvent<T: CommunicationEventData>: Codable {
    
    // MARK: - Public attributes.
    
    public var eventType: CommunicationEventType?
    
    /// Event data that conforms for CommunicationEventData, e.g. AdvertiseEventData.
    public var eventData: T

    // MARK: - Private attributes.
    
    public var eventSource: Component?
    public var eventSourceId: UUID?
    public var eventUserId: String? // or UUID?
    
    // MARK: - Initializer.
    
    /// TODO: Only accept components as eventSource.
    init(eventSource: Component, eventData: T) {
        self.eventSource = eventSource
        self.eventSourceId = eventSource.objectId
        self.eventUserId = "default-user-id" // FIXME: Default value.
        self.eventData = eventData
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.eventData = try container.decode(T.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(eventData)
    }
}

// MARK: - Extension enable easy access to JSON representation of DemoAdvertise object.

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
