//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DeadvertiseEvent.swift
//  CoatySwift
//
//

/// A Factory that creates DeadvertiseEvents.
public class DeadvertiseEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Convenience factory method that configures an instance of and DeadvertiseEvent with
    /// object ids to be deadvertised. Note that the event source should be the controller that
    /// creates the DeadvertiseEvent.
    public func with(objectIds: [CoatyUUID]) throws -> DeadvertiseEvent<Family> {
        return try DeadvertiseEvent.withObjectIds(eventSource: self.identity, objectIds: objectIds)
    }
}

/// DeadvertiseEvent provides a generic implementation for deadvertising CoatyObjects.
/// Note that this class should preferably be initialized via its withObjectIds() method.
public class DeadvertiseEvent<Family: ObjectFamily>: CommunicationEvent<DeadvertiseEventData<Family>> {
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: DeadvertiseEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of a DeadvertiseEvent with
    /// object ids to be deadvertised. Note that the event source should be the controller that
    /// creates the DeadvertiseEvent.
    internal static func withObjectIds(eventSource: Component,
                                       objectIds: [CoatyUUID]) throws -> DeadvertiseEvent {
        
        let deadvertiseEventData = DeadvertiseEventData<Family>(objectIds: objectIds)
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


/// DeadvertiseEventData provides the entire message payload data for a
/// `DeadvertiseEvent`.
public class DeadvertiseEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The objectIds of the objects to be deadvertised.
    var objectIds: [CoatyUUID]
    
    // MARK: - Initializers.
    
    init(objectIds: [CoatyUUID]) {
        self.objectIds = objectIds
        super.init()
    }
    
    static func createFrom(eventData: [CoatyUUID]) -> DeadvertiseEventData {
        return .init(objectIds: eventData)
    }
    
    // MARK: - Codable methods.

    enum CodingKeys: String, CodingKey {
        case objectIds
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objectIds = try container.decode([CoatyUUID].self, forKey: .objectIds)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let objectIds = self.objectIds.map { (uuid) -> String in
            return uuid.string
        }
        try container.encode(objectIds, forKey: .objectIds)
    }
}
