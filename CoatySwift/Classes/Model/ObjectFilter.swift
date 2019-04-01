//
//  ObjectFilter.swift
//  CoatySwift
//

import Foundation


/// Defines criteria for filtering and ordering a result
/// set of Coaty objects. Used in combination with Query events
/// and database operations, as well as the `ObjectMatcher` functionality.
public class ObjectFilter: Codable {
    
    /// A single condition for filtering objects (optional).
    var conditions: ObjectFilterConditions?
    
    /// A set of conditions for filtering objects (optional).
    var condition: ObjectFilterCondition?
    
    /// Determines the ordering of result objects by an array of
    /// OrderByProperty objects.
    var orderByProperties: [OrderByProperty]?
    
    /// If a take count is given, no more than that many objects will be returned
    /// (but possibly less, if the request itself yields less objects).
    /// Typically, this option is only useful if the `orderByProperties` option
    /// is also specified to ensure consistent ordering of paginated results.
    var take: Int?
    
    /// If skip count is given that many objects are skipped before beginning to
    /// return result objects.
    /// Typically, this option is only useful if the `orderByProperties` option
    /// is also specified to ensure consistent ordering of paginated results.
    var skip: Int?
    
    private init(_ conditions: ObjectFilterConditions? = nil,
                 _ condition: ObjectFilterCondition? = nil,
                 _ orderByProperties: [OrderByProperty]? = nil,
                 _ take: Int? = nil,
                 _ skip: Int? = nil) {
        self.conditions = conditions
        self.condition = condition
        self.orderByProperties = orderByProperties
        self.take = take
        self.skip = skip
    }
    
    public convenience init(condition: ObjectFilterCondition,
                            orderByProperties: [OrderByProperty]? = nil,
                            take: Int? = nil,
                            skip: Int? = nil) {
        self.init(nil, condition, orderByProperties, take, skip)
    }
    
    public convenience init(conditions: ObjectFilterConditions,
                            orderByProperties: [OrderByProperty]? = nil,
                            take: Int? = nil,
                            skip: Int? = nil) {
        self.init(conditions, nil, orderByProperties, take, skip)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case conditions
        case orderByProperties
        case take
        case skip
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let condition = condition {
            try container.encodeIfPresent(condition, forKey: .conditions)
        } else if let conditions = conditions {
            try container.encodeIfPresent(conditions, forKey: .conditions)
        }
        
        try container.encodeIfPresent(orderByProperties, forKey: .orderByProperties)
        try container.encodeIfPresent(take, forKey: .take)
        try container.encodeIfPresent(skip, forKey: .skip)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            condition = try container.decodeIfPresent(ObjectFilterCondition.self, forKey: .conditions)
        } catch { /* Surpress error. */ }
        
        do {
            conditions = try container.decodeIfPresent(ObjectFilterConditions.self, forKey: .conditions)
         } catch { /* Surpress error. */ }
        
        take = try container.decodeIfPresent(Int.self, forKey: .take)
        skip = try container.decodeIfPresent(Int.self, forKey: .skip)
        orderByProperties = try container.decodeIfPresent([OrderByProperty].self, forKey: .orderByProperties)
    }
}

public class OrderByProperty: Codable {
    var objectFilterProperties: ObjectFilterProperty
    var sortingOrder: SortingOrder
    
    public init(properties: ObjectFilterProperty,
                 sortingOrder: SortingOrder) {
        self.objectFilterProperties = properties
        self.sortingOrder = sortingOrder
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(objectFilterProperties)
        try container.encode(sortingOrder.rawValue)
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        objectFilterProperties = try container.decode(ObjectFilterProperty.self)
        
        // FIXME: Check enum decoding.
        let sortingOrderString = try container.decode(String.self)
        sortingOrder = SortingOrder(rawValue: sortingOrderString)!
    }
    
}

public class ObjectFilterProperty: Codable {
    var objectFilterProperty: String?
    var objectFilterProperties: [String]?
    
    private init(objectFilterProperty: String? = nil,
                 objectFilterProperties: [String]? = nil) {
        self.objectFilterProperty = objectFilterProperty
        self.objectFilterProperties = objectFilterProperties
    }
    
    public convenience init(_ objectFilterProperty: String) {
        self.init(objectFilterProperty: objectFilterProperty, objectFilterProperties: nil)
    }
    
    public convenience init(_ objectFilterProperties: [String]) {
        self.init(objectFilterProperty: nil, objectFilterProperties: objectFilterProperties)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let objectFilterProperty = objectFilterProperty {
            try container.encode(objectFilterProperty)
        } else if let objectFilterProperties = objectFilterProperties {
            try container.encode(objectFilterProperties)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let objectFilterProperty = try? container.decode(String.self) {
            self.objectFilterProperty = objectFilterProperty
        } else if let objectFilterProperties = try? container.decode([String].self) {
            self.objectFilterProperties = objectFilterProperties
        }
    }
}

public enum SortingOrder: String {
    case Asc
    case Desc
}

public class ObjectFilterConditions: Codable {
    
    // MARK: - Attributes.
    
    var and: [ObjectFilterCondition]?
    var or: [ObjectFilterCondition]?
    
    // MARK: - Initializers.
    
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
    
    // MARK: - Codable methods.
    
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
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            and = try container.decodeIfPresent([ObjectFilterCondition].self, forKey: .and)
         } catch { /* Surpress error. */ }
        
        do {
            or = try container.decodeIfPresent([ObjectFilterCondition].self, forKey: .or)
         } catch { /* Surpress error. */ }
    }
    
}

public class ObjectFilterCondition: Codable {
    
    // MARK: - Attributes.
    
    var property: ObjectFilterProperty
    var expression: ObjectFilterExpression
    
    // MARK: - Initializers.
    
    public init(property: ObjectFilterProperty, expression: ObjectFilterExpression) {
        self.property = property
        self.expression = expression
    }
    
    // MARK: - Codable methods.
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(property)
        try container.encode(expression)
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        self.property = try container.decode(ObjectFilterProperty.self)
        self.expression = try container.decode(ObjectFilterExpression.self)
     }
}

public class ObjectFilterExpression: Codable {
    
    // MARK: - Attributes.
    
    var filterOperator: ObjectFilterOperator
    var firstOperand: AnyCodable?
    var secondOperand: AnyCodable?
    
    // MARK: - Initializers.
    
    public init(filterOperator: ObjectFilterOperator,
                op1: AnyCodable? = nil,
                op2: AnyCodable? = nil) {
        self.filterOperator = filterOperator
        self.firstOperand = op1
        self.secondOperand = op2
    }
    
    // MARK: - Codable methods.
    
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
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // FIXME: enum decoding.
        let filterOperatorInt = try container.decode(Int.self)
        filterOperator = ObjectFilterOperator(rawValue: filterOperatorInt)!
        
        firstOperand = try container.decodeIfPresent(AnyCodable.self)
        secondOperand = try container.decodeIfPresent(AnyCodable.self)
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
