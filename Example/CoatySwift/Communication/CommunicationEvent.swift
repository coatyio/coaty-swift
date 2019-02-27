//
//  CommunicationEvent.swift
//  CoatySwift
//
//

import Foundation

/// CommunicationEvent is a generic supertype for AdvertiseEvent, DeadvertiseEvent etc.
class CommunicationEvent<T: CommunicationEventData>: Codable {
    
    // MARK: - Public attributes.
    
    var eventType: CommunicationEventType?
    
    /// Event data that conforms for CommunicationEventData, e.g. AdvertiseEventData.
    var eventData: T

    // MARK: - Private attributes.
    
    // private var eventSource: CoatyObject.Type
    private var eventSourceId: UUID?
    private var eventUserId: String? // or UUID?
    
    // MARK: - Initializer.
    
    /// TODO: Only accept components as eventSource.
    init(eventSource: CoatyObject, eventData: T) throws {
        if eventSource.coreType != .Component {
            throw CoatySwiftError.InvalidArgument("EventSource needs to have core type 'Component'")
        }
        
        self.eventSourceId = eventSource.objectId
        self.eventUserId = "default-user-id" // FIXME: Default value.
        self.eventData = eventData
        self.eventType = .Advertise // FIXME: Default value.
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.eventData = try container.decode(T.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(eventData)
    }
}

// MARK: - Extension enable easy access to JSON representation of DemoAdvertise object.

extension CommunicationEvent {
    var json: String {
        get {
            return PayloadCoder.encode(self)
        }
    }
}

/// CommunicationEventData provides the generic type required by the CommunicationEvent.
/// Note that this cannot be a type alias since we need it to be an actual class.
class CommunicationEventData: Codable {}
