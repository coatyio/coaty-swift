//
//  QueryEvent.swift
//  CoatySwift
//

import Foundation

/// QueryEvent provides a generic implementation for all Update Events.
///
public class QueryEvent<Family: ObjectFamily>: CommunicationEvent<QueryEventData<Family>> {
    
    // MARK: - Internal attributes.
    
    /// Provides a complete handler for reacting to complete events.
    internal var retrieveHandler: ((RetrieveEvent<Family>) -> Void)?
    
    
    /// Respond to an observed Update event by sending the given Complete event.
    ///
    /// - Parameter completeEvent: a Complete event.
    public func retrieve(retrieveEvent: RetrieveEvent<Family>) {
        if let retrieveHandler = retrieveHandler {
            retrieveHandler(retrieveEvent)
        }
    }
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    private override init(eventSource: Component, eventData: QueryEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }

    // MARK: - Factory methods.
    
    // TODO: Add documentation.
    public static func withObjectTypes(eventSource: Component,
                                       objectTypes: [String],
                                       objectFilter: ObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(objectTypes: objectTypes,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }
    
    // TODO: Add documentation.
    public static func withCoreTypes(eventSource: Component,
                                       coreTypes: [CoreType],
                                       objectFilter: ObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(coreTypes: coreTypes,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }

    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// - TODO: update documentation
/// UpdateEventData provides a wrapper object that stores the entire message payload data
/// for a UpdateEvent including the object itself as well as the associated private data.
public class QueryEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    public var objectTypes: [String]?
    public var coreTypes: [CoreType]?
    public var objectFilter: ObjectFilter?
    public var objectJoinConditions: [ObjectJoinCondition]?
    public var objectJoinCondition: ObjectJoinCondition?
    
    // MARK: - Initializers.
    
    /**
     - TODO: UPdate
     * Create a QueryEventData instance for the given type, filter, and join conditions.
     * Exactly one of objectTypes or coreTypes parameters must be specified (use undefined
     * for the other parameter). The object filter and join conditions are optional.
     *
     * @param objectTypes Restrict results by object types (logical OR).
     * @param coreTypes Restrict results by core types (logical OR).
     * @param objectFilter Restrict results by object filter (optional).
     * @param objectJoinConditions Join related objects into results (optional).
     */
    private init(objectTypes: [String]? = nil,
                 coreTypes: [CoreType]? = nil,
                 objectFilter: ObjectFilter? = nil,
                 objectJoinConditions: [ObjectJoinCondition]? = nil,
                 objectJoinCondition: ObjectJoinCondition? = nil) {
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
        self.objectFilter = objectFilter
        self.objectJoinConditions = objectJoinConditions
        self.objectJoinCondition = objectJoinCondition
        super.init()
    }
    
    // MARK: - Factory methods.
    
    public static func createFrom(objectTypes: [String],
                           objectFilter: ObjectFilter? = nil,
                           objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEventData {
        
        if objectJoinConditions?.count == 1 {
            return .init(objectTypes: objectTypes,
                         coreTypes: nil,
                         objectFilter: objectFilter,
                         objectJoinConditions: nil,
                         objectJoinCondition: objectJoinConditions![0])
        } else {
            return .init(objectTypes: objectTypes,
                         coreTypes: nil,
                         objectFilter: objectFilter,
                         objectJoinConditions: objectJoinConditions,
                         objectJoinCondition: nil)
            }
    }
    
    public static func createFrom(coreTypes: [CoreType],
                                  objectFilter: ObjectFilter? = nil,
                                  objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEventData {
        
        if objectJoinConditions?.count == 1 {
            return .init(objectTypes: nil,
                         coreTypes: coreTypes,
                         objectFilter: objectFilter,
                         objectJoinConditions: nil,
                         objectJoinCondition: objectJoinConditions![0])
        } else {
            return .init(objectTypes: nil,
                         coreTypes: coreTypes,
                         objectFilter: objectFilter,
                         objectJoinConditions: objectJoinConditions,
                         objectJoinCondition: nil)
        }
    }
    
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case objectTypes
        case coreTypes
        case objectFilter
        case objectJoinConditions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objectTypes = try container.decodeIfPresent([String].self, forKey: .objectTypes)
        self.coreTypes = try container.decodeIfPresent([CoreType].self, forKey: .coreTypes)
        self.objectFilter = try container.decodeIfPresent(ObjectFilter.self, forKey: .objectFilter)
        
        // TODO: The objectJoinConditions can be either a single object OR an array.
        /*self.objectJoinConditions = try container.decodeIfPresent([ObjectJoinCondition].self,
                                                                  forKey: .objectJoinConditions)
        self.objectJoinCondition = try container.decodeIfPresent(ObjectJoinCondition.self,
                                                                 forKey: .objectJoinConditions)
         */
        
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.objectTypes, forKey: .objectTypes)
        try container.encodeIfPresent(self.coreTypes, forKey: .coreTypes)
        try container.encodeIfPresent(self.objectFilter, forKey: .objectFilter)
        try container.encodeIfPresent(self.objectJoinConditions, forKey: .objectJoinConditions)
    }
    
}
