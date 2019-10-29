//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  RetrieveEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates RetrieveEvents.
public class RetrieveEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Create a RetrieveEvent instance for delivering the given objects.
    ///
    /// - Parameters:
    ///   - objects: the objects payload.
    ///   - privateData: application-specific options (optional).
    /// - Returns: a retrieve event that contains CoatyObjects that are part of the `ObjectFamily`.
    public func with(objects: [CoatyObject],
                     privateData: [String: Any]? = nil) -> RetrieveEvent<Family> {
        let retrieveEventData = RetrieveEventData<Family>(objects: objects, privateData: privateData)
        return .init(eventSource: self.identity, eventData: retrieveEventData)
    }
    
}

/// RetrieveEvent provides a generic implementation for responding to a `QueryEvent`.
///
/// The class requires the definition of a `ObjectFamily`, e.g. `CoatyObjectFamily` or a
/// custom implementation of a `ObjectFamily` to support custom object types.
/// - NOTE: This class should preferably be initialized via its withObject() method.
public class RetrieveEvent<Family: ObjectFamily>: CommunicationEvent<RetrieveEventData<Family>> {
    
    // MARK: - Initializers.
    
    fileprivate override init(eventSource: Identity, eventData: RetrieveEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
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
public class RetrieveEventData<Family: ObjectFamily>: CommunicationEventData {
    
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
        self.objects = try container.decode(family: Family.self, forKey: .objects)
        self.privateData = try container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.objects, forKey: .objects)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}
