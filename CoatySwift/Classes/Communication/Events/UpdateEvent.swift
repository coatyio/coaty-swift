//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  UpdateEvent.swift
//  CoatySwift
//

import Foundation

/// UpdateEvent provides a generic implementation for updating a CoatyObject.
public class UpdateEvent: CommunicationEvent<UpdateEventData> {
    
    // MARK: - Internal attributes.

    /// Provides a complete handler for reacting to Complete events.
    internal var completeHandler: ((CompleteEvent) -> Void)?

    // MARK: - Static Factory Methods.
    
    /// Create an UpdateEvent instance for the given object.
    ///
    /// The object type of the given object must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///   - object: the object with properties to be updated
    /// - Returns: an Update event with the given parameters
    /// - Throws: if object type of given object is invalid
    public static func with(object: CoatyObject) throws -> UpdateEvent {
        let updateEventData = UpdateEventData(object: object)
        return try .init(eventType: .Update, eventData: updateEventData, objectType: updateEventData.object.objectType)
    }
    
    /// Respond to an observed Update event by sending the given Complete event.
    ///
    /// - Parameter completeEvent: a Complete event.
    public func complete(completeEvent: CompleteEvent) {
        if let completeHandler = completeHandler {
            completeHandler(completeEvent)
        }
    }
    
    // MARK: - Initializers.
    
    fileprivate override init(eventType: CommunicationEventType, eventData: UpdateEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    fileprivate init(eventType: CommunicationEventType, eventData: UpdateEventData, objectType: String) throws {
        guard CommunicationTopic.isValidEventTypeFilter(filter: eventData.object.objectType) else {
            throw CoatySwiftError.InvalidArgument("Invalid object type: \(objectType)")
        }
        
        super.init(eventType: eventType, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }

    /// Validates response parameters of Complete event against the
    /// corresponding Update event.
    /// - Parameter eventData: event data for Complete response event
    /// - Returns: Returns false if the given Complete event data does not
    ///   correspond to the event data of this Update event.
    internal func ensureValidResponseParameters(eventData: CompleteEventData) -> Bool {
        
        if self.data.object.objectId != eventData.object?.objectId {
            LogManager.log.debug("object ID of Complete event doesn't match object ID of Update event")
            return false
        }
        
        return true
    }
}

/// Defines event data format for update operations on an object.
public class UpdateEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The object with properties to be updated.
    public var object: CoatyObject
    
    // MARK: - Initializers.
    
    init(object: CoatyObject) {
        self.object = object
        super.init()
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: CoatyObject) -> UpdateEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decode(AnyCoatyObjectDecodable.self, forKey: .object).object
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.object, forKey: .object)
    }

}

