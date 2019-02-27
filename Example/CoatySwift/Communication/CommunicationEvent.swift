//
//  CommunicationEvent.swift
//  CoatySwift
//
//

import Foundation

class CommunicationEventData: Codable {
    
}

class CommunicationEvent<T: CommunicationEventData>: Codable {
    
    // MARK: - Public attributes.
    var eventType: CommunicationEventType?
    
    // MARK: - Private attributes.
    
    // private var eventSource: CoatyObject.Type
    private var eventSourceId: UUID?
    var eventData: T
    private var eventUserId: String? // or UUID?
    
    // MARK: - Initializer.
    
    init(eventSource: CoatyObject, eventData: T) throws {
        // TODO: Only accept components as eventSource.
        
        if eventSource.coreType != .Component {
            // throw CoatySwiftError.InvalidArgument("EventSource needs to have core type 'Component'")
        }
        
        self.eventSourceId = eventSource.objectId
        self.eventUserId = "default-user-id" // FIXME: Default value.
        self.eventData = eventData
        self.eventType = .Advertise // FIXME: Default value.
    }
    
    // MARK: - Codable methods.
    required init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        self.eventData = try container.decode(T.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(eventData)
    }
}

// MARK: - Extension enable easy access to JSON representation of DemoAdvertise object.
extension CommunicationEvent {
    var json: String { get {
        return PayloadCoder.encode(self)
        }
    }
}
