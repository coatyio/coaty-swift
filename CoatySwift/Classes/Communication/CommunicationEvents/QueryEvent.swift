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
                                       objectFilter: DBObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(objectTypes: objectTypes,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }
    
    // TODO: Add documentation.
    public static func withCoreTypes(eventSource: Component,
                                       coreTypes: [CoreType],
                                       objectFilter: DBObjectFilter? = nil,
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
    public var objectFilter: DBObjectFilter?
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
                 objectFilter: DBObjectFilter? = nil,
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
                           objectFilter: DBObjectFilter? = nil,
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
                                  objectFilter: DBObjectFilter? = nil,
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
        /*let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objectTypes = try container.decodeIfPresent([String].self, forKey: .objectTypes)
        self.coreTypes = try container.decodeIfPresent([CoreType].self, forKey: .coreTypes)
        self.objectFilter = try container.decodeIfPresent(DBObjectFilter.self, forKey: .objectFilter)
        
        // TODO: The objectJoinConditions can be either a single object OR an array.
        self.objectJoinConditions = try container.decodeIfPresent([ObjectJoinCondition].self,
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


public class DBObjectFilter: Encodable {
    var conditions: ObjectFilterConditions?
    var condition: ObjectFilterCondition?
    
    /// FIXME: Heterogenous array here brings us problems. Try with Any
    /// object at first.
    /// Array<[ObjectFilterProperties, "Asc" | "Desc"]>
    var orderByProperties: [Any]?
    var take: Int?
    var skip: Int?
    
    private init(_ conditions: ObjectFilterConditions? = nil,
                 _ condition: ObjectFilterCondition? = nil,
                 _ orderByProperties: [Any]? = nil,
                 _ take: Int? = nil,
                 _ skip: Int? = nil) {
        self.conditions = conditions
        self.condition = condition
        self.orderByProperties = orderByProperties
        self.take = take
        self.skip = skip
    }
    
    public convenience init(condition: ObjectFilterCondition,
                            orderByProperties: [Any]? = nil,
                            take: Int? = nil,
                            skip: Int? = nil) {
        self.init(nil, condition, orderByProperties, take, skip)
    }
    
    public convenience init(conditions: ObjectFilterConditions,
                            orderByProperties: [Any]? = nil,
                            take: Int? = nil,
                            skip: Int? = nil) {
        self.init(conditions, nil, orderByProperties, take, skip)
    }
    
    enum CodingKeys: String, CodingKey {
        case conditions
        case orderByProperties
        case take
        case skip
    }
    
    // TODO: Implement me.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let condition = condition {
            try container.encodeIfPresent(condition, forKey: .conditions)
        } else if let conditions = conditions {
            try container.encodeIfPresent(conditions, forKey: .conditions)
        }
        
        // TODO try container.encodeIfPresent(orderByProperties, forKey: .orderByProperties)
        try container.encodeIfPresent(take, forKey: .take)
        try container.encodeIfPresent(skip, forKey: .skip)
    }
    
    // TODO: Implement me.
    /*public required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.condition = try container.decodeIfPresent(ObjectFilterCondition.self, forKey: .conditions)
    }*/
    
    
}


public class ObjectFilterProperties: Encodable {
    var objectFilterProperty: String?
    var objectFilterProperties: [String]?
    
    private init(_ objectFilterProperty: String? = nil,
                 _ objectFilterProperties: [String]? = nil) {
        self.objectFilterProperty = objectFilterProperty
        self.objectFilterProperties = objectFilterProperties
    }
    
    public convenience init(objectFilterProperty: String) {
        self.init(objectFilterProperty)
    }
    
    public convenience init(objectFilterProperties: [String]) {
        self.init(nil, objectFilterProperties)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let objectFilterProperty = objectFilterProperty {
            try container.encode(objectFilterProperty)
        } else if let objectFilterProperties = objectFilterProperties {
            try container.encode(objectFilterProperties)
        }
    }
}

public enum SortingOrder: String {
    case Asc
    case Desc
}

public class ObjectFilterConditions: Encodable {
    var and: [ObjectFilterCondition]?
    var or: [ObjectFilterCondition]?
    
    private init(_ and: [ObjectFilterCondition]? = nil, _ or: [ObjectFilterCondition]? = nil) {
        self.and = and
        self.or = or
    }
    
    public convenience init(and: [ObjectFilterCondition]) {
        self.init(and, nil)
    }
    
    public convenience init(or: [ObjectFilterCondition]) {
        self.init(nil, or)
    }
    
    
    enum CodingKeys: String, CodingKey {
        case and
        case or
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let andObjectFilterConditions = and {
            try container.encode(andObjectFilterConditions, forKey: .and)
        } else if let orObjectFilterConditions = or {
            try container.encode(orObjectFilterConditions, forKey: .or)
        }
    }
    
}

public class ObjectFilterCondition: Encodable/*, Decodable*/ {
    var first: ObjectFilterProperties
    var second: ObjectFilterExpression
    
    public init(first: ObjectFilterProperties, second: ObjectFilterExpression) {
        self.first = first
        self.second = second
    }
    
    // MARK: - Codable methods.
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(first)
        try container.encode(second)
    }
    
    /*public required init(from decoder: Decoder) throws {
        /*let container = decoder.
        
        self.first = ObjectFilterProperties.init(objectFilterProperty: "asdf")
        let objectFilterOperator = ObjectFilterOperator.Exists
        self.second = ObjectFilterExpression.init(filterOperator: objectFilterOperator)*/
    }*/
}

public class ObjectFilterExpression: Encodable {
    var filterOperator: ObjectFilterOperator
    
    // TODO: Operands are arbitrary JSONs.
    var firstOperand: String?
    var secondOperand: String?
    
    public init(filterOperator: ObjectFilterOperator,
         firstOperand: String? = nil,
         secondOperand: String? = nil) {
        self.filterOperator = filterOperator
        self.firstOperand = firstOperand
        self.secondOperand = secondOperand
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(filterOperator.rawValue)
        
        if let firstOperand = firstOperand {
            try container.encode(firstOperand)
        }
        
        if let secondOperand = secondOperand {
            try container.encode(secondOperand)
        }
    }
}

public class FilterOperations {
    
    static func lessThan(value: Double) -> (ObjectFilterOperator, Double) {
        return (ObjectFilterOperator.LessThan, value)
    }
    
    static func lessThan(value: String) -> (ObjectFilterOperator, String) {
        return (ObjectFilterOperator.LessThan, value)
    }
    
    static func lessThanOrEqual(value: Double) -> (ObjectFilterOperator, Double) {
        return (ObjectFilterOperator.LessThanOrEqual, value)
    }
    
    static func lessThanOrEqual(value: String) -> (ObjectFilterOperator, String) {
        return (ObjectFilterOperator.LessThanOrEqual, value)
    }
    
    static func greaterThan(value: Double) -> (ObjectFilterOperator, Double) {
        return (ObjectFilterOperator.GreaterThan, value)
    }
    
    static func greaterThan(value: String) -> (ObjectFilterOperator, String) {
        return (ObjectFilterOperator.GreaterThan, value)
    }
    
    static func greaterThanOrEqual(value: Double) -> (ObjectFilterOperator, Double) {
        return (ObjectFilterOperator.LessThanOrEqual, value)
    }
    
    static func greaterThanOrEqual(value: String) -> (ObjectFilterOperator, String) {
        return (ObjectFilterOperator.LessThanOrEqual, value)
    }
    
    // TODO: Currently only doing betweens that expect the same type from both operands.
    static func between(value1: Double, value2: Double) ->  (ObjectFilterOperator, Double, Double) {
       return (ObjectFilterOperator.LessThanOrEqual, value1, value2)
    }
    
    static func between(value1: String, value2: String) ->  (ObjectFilterOperator, String, String) {
        return (ObjectFilterOperator.LessThanOrEqual, value1, value2)
    }
    
    static func notBetween(value1: Double, value2: Double) ->  (ObjectFilterOperator, Double, Double) {
        return (ObjectFilterOperator.LessThanOrEqual, value1, value2)
    }
    
    static func notBetween(value1: String, value2: String) ->  (ObjectFilterOperator, String, String) {
        return (ObjectFilterOperator.LessThanOrEqual, value1, value2)
    }
    
    static func like(pattern: String) -> (ObjectFilterOperator, String) {
        return (ObjectFilterOperator.Like, pattern)
    }
    
    static func exists() -> (ObjectFilterOperator) {
        return ObjectFilterOperator.Exists
    }
    
    static func notExists() -> (ObjectFilterOperator) {
        return ObjectFilterOperator.NotExists
    }
    
    /// TODO: Missing methods:
    /*
     equals: (value: any): [ObjectFilterOperator, any] =>
     [ObjectFilterOperator.Equals, value],
     
     notEquals: (value: any): [ObjectFilterOperator, any] =>
     [ObjectFilterOperator.NotEquals, value],
     
     contains: (values: any): [ObjectFilterOperator, any] =>
     [ObjectFilterOperator.Contains, values],
     
     notContains: (values: any): [ObjectFilterOperator, any] =>
     [ObjectFilterOperator.NotContains, values],
     
     in: (values: any[]): [ObjectFilterOperator, any[]] =>
     [ObjectFilterOperator.In, values],
     
     notIn: (values: any[]): [ObjectFilterOperator, any[]] =>
     [ObjectFilterOperator.NotIn, values],
     
    */

    

}


public class ObjectJoinCondition: Codable {
    var localProperty: String
    var isLocalPropertyArray: Bool?
    var asProperty: String
    var isOneToOneRelation: Bool?
    
    public init(localProperty: String, asProperty: String,
         isLocalPropertyArray: Bool? = nil, isOneToOneRelation: Bool? = nil) {
        self.localProperty = localProperty
        self.asProperty = asProperty
        self.isLocalPropertyArray = isLocalPropertyArray
        self.isOneToOneRelation = isOneToOneRelation
    }
}

public enum ObjectFilterOperator: Int {
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
