// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationEvent.swift
//  CoatySwift
//
//

import Foundation

/// CommunicationEvent is a generic supertype for AdvertiseEvent, DeadvertiseEvent etc.
public class CommunicationEvent<T: CommunicationEventData>: Codable {
    
    // MARK: - Public attributes.
    
    public var type: CommunicationEventType?
    
    /// Event data that conforms for CommunicationEventData, e.g. AdvertiseEventData.
    public var data: T

    // MARK: - Private attributes.
    
    public var source: Component?
    public var sourceId: CoatyUUID?
    public var userId: String? // or UUID?
    
    // MARK: - Initializer.
    
    init(eventSource: Component, eventData: T) {
        self.source = eventSource
        self.sourceId = eventSource.objectId
        self.userId = EMPTY_ASSOCIATED_USER_ID // FIXME: Default value.
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
