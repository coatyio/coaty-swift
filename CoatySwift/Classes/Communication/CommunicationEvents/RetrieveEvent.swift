//
//  RetrieveEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates RetrieveEvents.
public class RetrieveEventFactory<Family: ObjectFamily> {
    
    /// Create a RetrieveEvent instance for delivering the given objects.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component.
    ///   - objects: the objects payload.
    ///   - privateData: application-specific options (optional).
    /// - Returns: a retrieve event that contains CoatyObjects that are part of the `ObjectFamily`.
    static func withObjects(eventSource: Component,
                            objects: [CoatyObject],
                            privateData: [String: Any]? = nil) -> RetrieveEvent<Family> {
        let retrieveEventData = RetrieveEventData<Family>(objects: objects, privateData: privateData)
        return .init(eventSource: eventSource, eventData: retrieveEventData)
    }
    
}

/// RetrieveEvent provides a generic implementation for all RetrieveEvents.
///
/// The class requires the definition of a `ObjectFamily`, e.g. `CoatyObjectFamily` or a
/// custom implementation of a `ObjectFamily` to support custom object types.
/// - NOTE: This class should preferably initialized via its withObject() method.
public class RetrieveEvent<Family: ObjectFamily>: CommunicationEvent<RetrieveEventData<Family>> {
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    fileprivate override init(eventSource: Component, eventData: RetrieveEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// RetrieveEventData provides a wrapper object that stores the entire message payload data
/// for a RetrieveEvent including the object itself as well as the associated private data.
public class RetrieveEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    public var objects: [CoatyObject]
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
