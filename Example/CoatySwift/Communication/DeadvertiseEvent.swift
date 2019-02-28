//
//  DeadvertiseEvent.swift
//  CoatySwift
//
//

/// Deadvertise provides a generic implementation for all DeadvertiseEvents.
/// Note that this class should preferably initialized via its withObject() method.
class DeadvertiseEvent<GenericDeadvertise: Deadvertise>: CommunicationEvent<DeadvertiseEventData<GenericDeadvertise>> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DeadvertiseEventData<GenericDeadvertise>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of and DeadvertiseEvent with
    /// a Deadvertisement Object. Note that the event source should be the controller that
    /// creates the DeadvertiseEvent.
    /// FIXME: Replace CoatyObject with Component object.
    static func withObject(eventSource: Component,
                           object: GenericDeadvertise) throws -> DeadvertiseEvent {
        
        let deadvertiseEventData = DeadvertiseEventData(object: object)
        return .init(eventSource: eventSource, eventData: deadvertiseEventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// DeadvertiseEventData provides a wrapper object that stores the entire message payload data
/// for a DeadvertiseEvent.
class DeadvertiseEventData<S: Deadvertise>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: S
    
    // MARK: - Initializers.
    
    init(object: S) {
        self.object = object
        // TODO: hasValidParameters() ?
        super.init()
    }
    
    static func createFrom(eventData: S) -> DeadvertiseEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.object = try container.decode(S.self)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.object)
    }
}
