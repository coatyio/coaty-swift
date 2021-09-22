//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ObjectMatcher.swift
//  CoatySwift

import Foundation


/// Provides a static `matchesFilter` method to match an object against a
/// given object filter. Useful for retrieving matching objects on Query events
/// without using a database adapter. Also useful to filter out Coaty objects
/// that match given filter conditions before publishing with Advertise or
/// Channel events.
public enum ObjectMatcher {
    
    // MARK: - Public methods.
    
    /// Determines whether the given object matches the given context filter.
    /// Note that if you pass in an `ObjectFilter`, only the filter conditions are
    /// heeded for the result.
    /// - Parameters:
    ///     - obj: The object to pass the filter on (optional).
    ///     - filter: The context filter to apply (optional).
    /// - Returns: true: on match; false otherwise
    public static func matchesFilter(obj: CoatyObject?, filter: ContextFilter?) -> Bool {
        if obj == nil {
            return false
        }
        if filter == nil {
            return true
        }
        if filter?.condition == nil && filter?.conditions == nil {
            return true
        }
        
        // If both condition and conditions.and are not nil, check the condition and
        // logically 'and' it with the conditions.and
        if let singleCondition = filter?.condition, let multipleConditionsAnd = filter?.conditions?.and {
            let singleConditionResult = ObjectMatcher._matchesCondition(obj: obj!,
                                                                        condition: singleCondition)

            let multipleConditionsAndResult = multipleConditionsAnd.allSatisfy { cond -> Bool in
                return ObjectMatcher._matchesCondition(obj: obj!,
                                                       condition: cond)
            }
            
            return singleConditionResult && multipleConditionsAndResult
        }
        
        // If both condition and conditions.or are not nil, check the condition and
        // logically 'and' it with the conditions
        if let singleCondition = filter?.condition, let multipleConditionsOr = filter?.conditions?.or {
            let singleConditionResult = ObjectMatcher._matchesCondition(obj: obj!,
                                                                        condition: singleCondition)

            let multipleConditionsOrResult = multipleConditionsOr.contains { cond -> Bool in
                return ObjectMatcher._matchesCondition(obj: obj!,
                                                       condition: cond)
            }
            
            return singleConditionResult && multipleConditionsOrResult
        }
        
        if let singleCondition = filter?.condition {
            return ObjectMatcher._matchesCondition(obj: obj!,
                                                   condition: singleCondition)
        }
        if let multipleConditionsAnd = filter?.conditions?.and {
            return multipleConditionsAnd.allSatisfy { cond -> Bool in
                return ObjectMatcher._matchesCondition(obj: obj!,
                                                       condition: cond)
            }
        }
        if let multipleConditionsOr = filter?.conditions?.or {
            return multipleConditionsOr.contains { cond -> Bool in
                return ObjectMatcher._matchesCondition(obj: obj!,
                                                       condition: cond)
            }
        }
        
        return true
    }
    
    // MARK: - Internal methods.
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Gets an array of property names for the given nested properties specified either
    /// in dot notation or array notation.
    ///
    /// - Parameters:
    ///     - propNames property names as string in dot notation or as array of property names
    /// - Returns: an array of nested property names
    internal static func getFilterProperties(propNames: ObjectFilterProperty) -> [String] {
        if let singleString = propNames.objectFilterProperty {
            return singleString.split(separator: Character(".")).map(String.init)
        } else if let multipleStrings = propNames.objectFilterProperties {
            return multipleStrings
        } else {
            return []
        }
    }
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Gets the value of a given property for the given object. Property names may be
    /// specified to retrieve the value of a nested property of a subordinate object.
    ///
    /// - Parameters:
    ///     - propNames: property names as string in dot notation or as array of property names
    ///     - obj: a Coaty object
    /// - Returns: the value of the nested properties of the given object as AnyCodable (nil if no such property has been found or any other error has occured)
    internal static func getFilterPropertyValue(propNames: ObjectFilterProperty, obj: CoatyObject) -> AnyCodable? {
        let propNamesAsArray = ObjectMatcher.getFilterProperties(propNames: propNames)
        
        return ObjectMatcher._getFilterPropertyValue(propNames: propNamesAsArray,
                                                     obj: obj)
    }
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Gets the value of a given property for the given object. Property names may be
    /// specified to retrieve the value of a nested property of a subordinate object.
    ///
    /// - Parameters:
    ///     - propNames property names as an array of property names (already in a correct format)
    ///     - obj: a Coaty object
    /// - Returns: the value of the nested properties of the given object
    internal static func _getFilterPropertyValue(propNames: [String], obj: Any) -> AnyCodable? {
        var nextPropNames = propNames
        if nextPropNames.isEmpty {
            return nil
        }
        
        let currentLevelLabel = nextPropNames.remove(at: 0)
        
        // Fetch the properties of the obj
        let properties = ObjectMatcher._fetchProperties(of: obj)
        let currentLevelProperty = properties.first { (label, _) -> Bool in
            return label == currentLevelLabel
        }
        
        if let (_, value) = currentLevelProperty {
            // We have reached the end of the property names.
            if nextPropNames.count == 0 {
                return AnyCodable._getAnyAsAnyCodable(value)
            } else {
                return ObjectMatcher._getFilterPropertyValue(propNames: nextPropNames, obj: value)
            }
        } else {
            return nil
        }
    }
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Recursively list all properties of an AnyObject.
    ///
    /// - Parameters:
    ///     - structure: any object from which properties can be extracted (either a CoatyObject or Dictionary)
    /// - Returns: a tuple list that contains all attributes and their values representes as Any.
    internal static func _fetchProperties(of structure: Any) -> [(String, Any)] {
        // Since access to properties in dictionaries is different than access to properties in object perform an if as? distinction.
        if let structureAsDictionary = structure as? Dictionary<String, Any> {
            return structureAsDictionary.map { ($0.key, $0.value) }
        } else {
            let mirror = Mirror(reflecting: structure)
            
            var result = [(String, Any)]()
            
            for child in mirror.children {
                result.append((child.label!, child.value))
            }
            
            guard let superMirror = mirror.superclassMirror else {
                return result
            }
            
            // Since we are dealing with a structure which is not a Dictionary, there might be some properties in the superMirror
            result.insert(contentsOf: ObjectMatcher._fetchPropertiesSuperMirrorHelper(of: superMirror), at: 0)
            
            return result
        }
    }
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Recursively list all properties of a Swift object.
    ///
    /// - Parameters:
    ///     - mirror: a mirror of an object from which properties are to be extracted.
    /// - Returns: a tuple list that contains all attributes and their values representes as Any.
    internal static func _fetchPropertiesSuperMirrorHelper(of mirror: Mirror) -> [(String, Any)] {
        var result = [(String, Any)]()
        
        for child in mirror.children {
            result.append((child.label!, child.value))
        }
        
        guard let superMirror = mirror.superclassMirror else {
            return result
        }
        
        result.insert(contentsOf: ObjectMatcher._fetchPropertiesSuperMirrorHelper(of: superMirror), at: 0)
        
        return result
    }
    
    /// - Note: Internal For internal use in framework only.
    ///
    /// Check if a coaty object satisfies the condition.
    ///
    /// - Parameters:
    ///     - obj: coaty object to check
    ///     - condition: considered condition
    /// - Returns: true if object satisfies the condition; false otherwise
    internal static func _matchesCondition(obj: CoatyObject, condition: ObjectFilterCondition) -> Bool {
        let props = condition.property
        let op = condition.expression.filterOperator
        let v1 = condition.expression.firstOperand
        let v2 = condition.expression.secondOperand
        let v = ObjectMatcher.getFilterPropertyValue(propNames: props, obj: obj)
        
        if op == .NotExists {
            return v == nil
        }
        if v == nil {
            return false
        }
        
        switch op {
        case .LessThan:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value < value1
        case .LessThanOrEqual:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value <= value1
        case .GreaterThan:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value > value1
        case .GreaterThanOrEqual:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value >= value1
        case .Between:
            if let value1 = v1, let value2 = v2 {
                if value1 > value2 {
                    return v! >= value2 && v! <= value1
                } else {
                    return v! >= value1 && v! <= value2
                }
            } else {
                return false
            }
        case .NotBetween:
            if let value1 = v1, let value2 = v2 {
                if value1 > value2 {
                    return v! < value2 || v! > value1
                } else {
                    return v! < value1 || v! > value2
                }
            } else {
                return false
            }
        case .Like:
            guard let value = v?.value as? String, let value1 = v1?.value as? String else {
                return false
            }
            
            // NOTE: Ask if this kind of caching is okay
            // To speed up regexp matching, generate regexp once and
            // cache it as extra property on object filter op2 property.
            if let cachedRegex = condition.expression.secondOperand?.value as? NSRegularExpression {
                return cachedRegex._matches(value)
            } else {
                if let likeRegex = ObjectMatcher._createLikeRegexp(pattern: value1) {
                    condition.expression.secondOperand = AnyCodable(likeRegex)
                    return likeRegex._matches(value)
                } else {
                    return false
                }
            }
        case .Equals:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value == value1
        case .NotEquals:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return value != value1
        case .Exists:
            return true
        case .Contains:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return AnyCodable.deepContains(value, value1)
        case .NotContains:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return !AnyCodable.deepContains(value, value1)
        case .In:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return AnyCodable.deepIncludes(value1, value)
        case .NotIn:
            guard let value = v, let value1 = v1 else {
                return false
            }
            return !AnyCodable.deepIncludes(value1, value)
        default:
            return false
        }
    }
    
    internal static func _createLikeRegexp(pattern: String) -> NSRegularExpression? {
        // Convert underscore/percent based SQL LIKE pattern into Swift NSRegularExpression regex syntax
        var regexStr = "^"
        var isEscaped = false
        for c in pattern {
            if c == "\\" {
                if isEscaped {
                    isEscaped = false
                    regexStr += "\\\\"
                } else {
                    isEscaped = true
                }
            } else if ".*+?^${}()|[]/".contains(c) {
                regexStr += "\\" + "\(c)"
                isEscaped = false
            } else if c == "_" && !isEscaped {
                regexStr += "."
            } else if c == "%" && !isEscaped {
                regexStr += ".*"
            } else {
                regexStr += "\(c)"
            }
        }
        regexStr += "$"
        
        return try? NSRegularExpression(pattern: regexStr, options: .anchorsMatchLines)
    }
}

extension NSRegularExpression {
    func _matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        let result = firstMatch(in: string, options: [], range: range)
        return result != nil
    }
}
