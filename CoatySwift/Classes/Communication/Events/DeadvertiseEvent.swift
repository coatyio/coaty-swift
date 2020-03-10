//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DeadvertiseEvent.swift
//  CoatySwift
//
//

/// DeadvertiseEvent provides a generic implementation for deadvertising
/// CoatyObjects.
public class DeadvertiseEvent: CommunicationEvent<DeadvertiseEventData> {

    // MARK: - Static Factory Methods.
    
    /// Create a Deadvertise event with object ids to be deadvertised.
    ///
    /// - Parameters:
    ///   - objectIds: the object ids to be deadvertised
    /// - Returns: a Deadvertise event with the given parameters
    public static func with(objectIds: [CoatyUUID]) -> DeadvertiseEvent {
        let deadvertiseEventData = DeadvertiseEventData(objectIds: objectIds)
        return .init(eventType: .Deadvertise, eventData: deadvertiseEventData)
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: DeadvertiseEventData) {
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


/// DeadvertiseEventData provides the entire message payload data for a
/// `DeadvertiseEvent`.
public class DeadvertiseEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The objectIds of the objects to be deadvertised.
    public var objectIds: [CoatyUUID]
    
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
