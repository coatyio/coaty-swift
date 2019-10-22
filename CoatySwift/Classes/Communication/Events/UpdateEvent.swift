//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  UpdateEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates UpdateEvents.
public class UpdateEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Create an UpdateEvent instance for the given partial update.
    ///
    /// - Parameters:
    ///   - objectId: the UUID of the object to be updated (partial update)
    ///   - changedValues: Object hash for properties that have changed or should
    ///     be changed (partial update)
    public func withPartial(objectId: CoatyUUID,
                            changedValues: [String: Any]) -> UpdateEvent<Family> {
        let updateEventData = UpdateEventData<Family>(objectId: objectId, changedValues: changedValues)
        return .init(eventSource: self.identity, eventData: updateEventData)
    }
    
    /// Create an UpdateEvent instance for the given full update.
    ///
    /// - Parameters:
    ///   - object: the full object to be updated
    public func withFull(object: CoatyObject) -> UpdateEvent<Family> {
        let updateEventData = UpdateEventData<Family>(object: object)
        return .init(eventSource: self.identity, eventData: updateEventData)
    }
}

/// UpdateEvent provides a generic implementation for updating a CoatyObject.
///
/// - NOTE: This class should preferably be initialized via its withPartial() or withFull() method.
public class UpdateEvent<Family: ObjectFamily>: CommunicationEvent<UpdateEventData<Family>> {
    
    // MARK: - Internal attributes.
    
    /// Provides a complete handler for reacting to complete events.
    internal var completeHandler: ((CompleteEvent<Family>) -> Void)?
    
    
    /// Respond to an observed Update event by sending the given Complete event.
    ///
    /// - Parameter completeEvent: a Complete event.
    public func complete(completeEvent: CompleteEvent<Family>) {
        if let completeHandler = completeHandler {
            completeHandler(completeEvent)
        }
    }
    
    // MARK: - Initializers.
    
    fileprivate override init(eventSource: Component, eventData: UpdateEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
    
    /// For internal use in framework only.
    ///
    /// - Parameter eventData: event data for Complete response event
    /// - Returns: Returns false if the given Complete event data does not correspond to
    /// the event data of this Update event.
    internal func ensureValidResponseParameters(eventData: CompleteEventData<Family>) -> Bool {
        
        if self.data.isPartialUpdate && self.data.objectId != eventData.object?.objectId {
            LogManager.log.warning("object ID of Complete event doesn't match object ID of Update event")
            return false
        }
        
        if self.data.isFullUpdate && self.data.object?.objectId != eventData.object?.objectId {
            LogManager.log.warning("object ID of Complete event doesn't match object ID of Update event")
            return false
        }
        
        return true
    }
}

/// UpdateEventData provides the entire message payload data for an
/// `UpdateEvent` including the object itself as well as associated private
/// data.
public class UpdateEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The object to be updated (for full updates only).
    public var object: CoatyObject?

    /// The UUID of the object to be updated (for partial updates only).
    public var objectId: CoatyUUID?

    /// Key value pairs for properties that have changed or should be changed
    /// (accessible by indexer). For partial updates only.
    public var changedValues: [String: Any]?
    
    /// Determines wheher this event data defines a partial update.
    public var isPartialUpdate: Bool {
        return objectId != nil
    }
    
    /// Determines wheher this event data defines a full update.
    public var isFullUpdate: Bool {
        return object != nil
    }
    
    // MARK: - Initializers.
    
    private init(_ object: CoatyObject?, objectId: CoatyUUID?, _ changedValues: [String: Any]? = nil) {
        self.object = object
        self.objectId = objectId
        self.changedValues = changedValues
        super.init()
    }
    
    convenience init(object: CoatyObject) {
        self.init(object, objectId: nil, nil)
    }
    
    convenience init(objectId: CoatyUUID, changedValues: [String: Any]) {
        self.init(nil, objectId: objectId, changedValues)
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(eventData: CoatyObject) -> UpdateEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case objectId
        case changedValues
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decodeIfPresent(ClassWrapper<Family, CoatyObject>.self, forKey: .object)?.object
        self.objectId = try container.decodeIfPresent(CoatyUUID.self, forKey: .objectId)
        self.changedValues = try container.decodeIfPresent([String: Any].self, forKey: .changedValues)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.objectId, forKey: .objectId)
        try container.encodeIfPresent(self.changedValues, forKey: .changedValues)
    }

}

