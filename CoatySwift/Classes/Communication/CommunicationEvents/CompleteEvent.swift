//
//  CompleteEvent.swift
//  CoatySwift
//

import Foundation


/// CompleteEvent provides a generic implementation for all CompleteEvents.
/// Note that this class should preferably initialized via its withObject() method.
public class CompleteEvent<Family: ObjectFamily>: CommunicationEvent<CompleteEventData<Family>> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: CompleteEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Factory methods.
    
    /// Create a CompleteEvent instance for updating the given object.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - object: the updated object
    ///   - privateData: application-specific options (optional)
    public static func withObject(eventSource: Component,
                           object: CoatyObject,
                           privateData: [String: Any]? = nil) -> CompleteEvent {
        
        let completeEventData = CompleteEventData<Family>(object, privateData)
        return .init(eventSource: eventSource, eventData: completeEventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

/// CompleteEventData provides a wrapper object that stores the entire message payload data
/// for a CompleteEvent including the object itself as well as the associated private data.
public class CompleteEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    public var object: CoatyObject?
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
        self.object = try container.decodeIfPresent(ClassWrapper<Family, CoatyObject>.self, forKey: .object)?.object
        self.privateData = try container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}

