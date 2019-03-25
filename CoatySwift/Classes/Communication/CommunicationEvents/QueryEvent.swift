//
//  QueryEvent.swift
//  CoatySwift
//

import Foundation

/// QueryEvent provides a generic implementation for all Update Events.
///
/// - NOTE: This class should preferably initialized via its withPartial() or withFull() method.
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
                                       objectFilter: DBObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(objectTypes: objectTypes,
                                                               coreTypes: nil,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }
    
    // TODO: Add documentation.
    public static func withCoreTypes(eventSource: Component,
                                       coreTypes: [CoreType],
                                       objectFilter: DBObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(objectTypes: nil,
                                                               coreTypes: coreTypes,
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
    public var objectFilter: DBObjectFilter?
    public var objectJoinConditions: [ObjectJoinCondition]?
    
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
                 objectFilter: DBObjectFilter? = nil,
                 objectJoinConditions: [ObjectJoinCondition]? = nil) {
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
        self.objectFilter = objectFilter
        self.objectJoinConditions = objectJoinConditions
        super.init()
    }
    
    // MARK: - Factory methods.
    
    static func createFrom(objectTypes: [String]? = nil,
                           coreTypes: [CoreType]? = nil,
                           objectFilter: DBObjectFilter? = nil,
                           objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEventData {
        
        return .init(objectTypes: objectTypes,
                     coreTypes: coreTypes,
                     objectFilter: objectFilter,
                     objectJoinConditions: objectJoinConditions)
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
        self.objectFilter = try container.decodeIfPresent(DBObjectFilter.self, forKey: .objectFilter)
        
        // TODO: The objectJoinConditions can be either a single object OR an array.
        // WARNING: This will crash!
        self.objectJoinConditions = try container.decodeIfPresent([ObjectJoinCondition].self,
                                                                  forKey: .objectJoinConditions)
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


public class DBObjectFilter: Codable {
    var conditions: [ObjectFilterCondition]?
    
    // Array<[ObjectFilterProperties, "Asc" | "Desc"]>
    var orderByProperties: [String]?
    var take: Int?
    var skip: Int?
    
}


public class ObjectFilterPropertiesArray {
    
}

public class ObjectFilterPropertyString {
    
}

public enum SortingOrder: String {
    case Asc
    case Desc
}

public class ObjectFilterCondition {
    var and: [ObjectFilterCondition]?
    var or: [ObjectFilterCondition]?
}

public class ObjectJoinCondition: Codable {
    
}

public enum ObjectFilterOperator {
    case LessThan
    case LessThanOrEqual
    case GreaterThan
    case GreaterThanOrEqual
    case Between
    case NotBetween
    case Like
    case Equals
    case NotEquals
    case Exists
    case NotExists
    case Contains
    case NotContains
    case In
    case NotIn
}
