// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DeadvertiseEvent.swift
//  CoatySwift
//
//

/// A Factory that creates DeadvertiseEvents.
public class DeadvertiseEventFactory<Family: ObjectFamily> {
    
    /// Convenience factory method that configures an instance of and DeadvertiseEvent with
    /// a Deadvertisement Object. Note that the event source should be the controller that
    /// creates the DeadvertiseEvent.
    /// FIXME: Replace CoatyObject with Component object.
    public static func withObject(eventSource: Component,
                                  object: Deadvertise) throws -> DeadvertiseEvent {
        
        return try DeadvertiseEvent.withObject(eventSource: eventSource, object: object)
    }
}

/// Deadvertise provides a generic implementation for all DeadvertiseEvents.
/// Note that this class should preferably initialized via its withObject() method.
public class DeadvertiseEvent: CommunicationEvent<DeadvertiseEventData> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DeadvertiseEventData) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of and DeadvertiseEvent with
    /// a Deadvertisement Object. Note that the event source should be the controller that
    /// creates the DeadvertiseEvent.
    /// FIXME: Replace CoatyObject with Component object.
    internal static func withObject(eventSource: Component,
                           object: Deadvertise) throws -> DeadvertiseEvent {
        
        let deadvertiseEventData = DeadvertiseEventData(object: object)
        return .init(eventSource: eventSource, eventData: deadvertiseEventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// DeadvertiseEventData provides a wrapper object that stores the entire message payload data
/// for a DeadvertiseEvent.
public class DeadvertiseEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: Deadvertise
    
    // MARK: - Initializers.
    
    init(object: Deadvertise) {
        self.object = object
        // TODO: hasValidParameters() ?
        super.init()
    }
    
    static func createFrom(eventData: Deadvertise) -> DeadvertiseEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.object = try container.decode(Deadvertise.self)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.object)
    }
}
