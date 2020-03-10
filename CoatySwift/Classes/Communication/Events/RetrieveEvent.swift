//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  RetrieveEvent.swift
//  CoatySwift
//

import Foundation

/// RetrieveEvent provides a generic implementation for responding to a
/// `QueryEvent`.
public class RetrieveEvent: CommunicationEvent<RetrieveEventData> {
    
    // MARK: - Static Factory Methods.

    /// Create a RetrieveEvent instance for delivering the queried objects.
    ///
    /// - Parameters:
    ///   - objects: the objects which have been queried.
    ///   - privateData: application-specific options (optional).
    /// - Returns: a Retrieve event with the given parameters
    public static func with(objects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> RetrieveEvent {
        let retrieveEventData = RetrieveEventData(objects: objects, privateData: privateData)
        return .init(eventType: .Retrieve, eventData: retrieveEventData)
    }

    // MARK: - Initializers.
    
    fileprivate override init(eventType: CommunicationEventType, eventData: RetrieveEventData) {
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

/// RetrieveEventData provides the entire message payload data for a
/// `RetrieveEvent` including the object itself as well as associated private
/// data.
public class RetrieveEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// An array of objects to be retrieved (array may be empty).
    public var objects: [CoatyObject]

    /// Application-specific options (optional).
    public var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    internal init(objects: [CoatyObject], privateData: [String: Any]? = nil) {
        self.objects = objects
        self.privateData = privateData
        super.init()
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: [CoatyObject]) -> RetrieveEventData {
        return .init(objects: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case objects
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objects = try container.decode([AnyCoatyObjectDecodable].self, forKey: .objects).compactMap({ $0.object })
        self.privateData = try container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.objects, forKey: .objects)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}
