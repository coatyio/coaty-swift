//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
// Source: https://github.com/Flight-School/AnyCodable/tree/master/Sources/AnyCodable

import Foundation

/**
 A type-erased `Codable` value.
 
 The `AnyCodable` type forwards encoding and decoding responsibilities
 to an underlying value, hiding its specific underlying type.
 
 You can encode or decode mixed-type values in dictionaries
 and other collections that require `Encodable` or `Decodable` conformance
 by declaring their contained type to be `AnyCodable`.
 
 - SeeAlso: `AnyEncodable`
 - SeeAlso: `AnyDecodable`
 */
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable: _AnyEncodable, _AnyDecodable {}

extension AnyCodable: Equatable {
    public static func ==(lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case (let lhs as CoatyUUID, let rhs as CoatyUUID):
            return lhs == rhs
        case let (lhs as CoatyObject, rhs as CoatyObject):
            return AnyCodable.deepEquals(lhs, rhs)
        case (let lhs as [String: AnyCodable], let rhs as [String: AnyCodable]):
            return AnyCodable.deepEquals(lhs, rhs)
        case (let lhs as [Any], let rhs as [Any]):
            return AnyCodable.deepEquals(lhs, rhs)
        default:
            return false
        }
    }
}

extension AnyCodable {
    /// - Note: Internal for Internal use in framework only
    ///
    /// Utitlity function  to pack Any as AnyCodable while using the most specific type for the value.
    ///
    /// - Parameters:
    ///     - value: value to be packed as AnyCodable
    /// - Returns: AnyCodable of the value (with the most specific type); nil if the value should never be packed as AnyCodable
    internal static func _getAnyAsAnyCodable(_ value: Any) -> AnyCodable? {
        if let v = value as? Bool {
            return AnyCodable(booleanLiteral: v)
        } else if let v = value as? Int {
            return AnyCodable(integerLiteral: v)
        } else if let v = value as? Int8 {
            return AnyCodable(v)
        } else if let v = value as? Int16 {
            return AnyCodable(v)
        } else if let v = value as? Int32 {
            return AnyCodable(v)
        } else if let v = value as? Int64 {
            return AnyCodable(v)
        } else if let v = value as? UInt {
            return AnyCodable(v)
        } else if let v = value as? UInt8 {
            return AnyCodable(v)
        } else if let v = value as? UInt16 {
            return AnyCodable(v)
        } else if let v = value as? UInt32 {
            return AnyCodable(v)
        } else if let v = value as? UInt64 {
            return AnyCodable(v)
        } else if let v = value as? Float {
            return AnyCodable(v)
        } else if let v = value as? Double {
            return AnyCodable(v)
        } else if let v = value as? String {
            return AnyCodable(stringLiteral: v)
        } else if let v = value as? CoatyUUID {
            return AnyCodable(v)
        } else if let v = value as? CoatyObject {
            return AnyCodable(v)
        } else if let v = value as? [Any] {
            let result = v.map { any -> AnyCodable in
                if let nonNil = AnyCodable._getAnyAsAnyCodable(any) {
                    return nonNil
                } else {
                    return AnyCodable(nil)
                }
            }
            return AnyCodable(result)
        } else if let v = value as? [String: Any] {
            var result = [String: AnyCodable]()
            for key in v.keys {
                if let unwrappedValue = AnyCodable._getAnyAsAnyCodable(v[key]!) {
                    result[key] = unwrappedValue
                } else {
                    result[key] = nil
                }
            }
            return AnyCodable(result)
        } else if let v = value as? AnyCodable {
            return AnyCodable._getAnyAsAnyCodable(v.value)
        } else {
            return nil
        }
    }
}

extension AnyCodable {
    /// - Note: Internal for internal use in framework only
    ///
    /// Determines whether two Arrays [Any] are structurally equal
    /// (aka. deep equal) according to a recursive equality algorithm.
    ///
    /// - Parameters:
    ///     - lhs: an array of type [Any]
    ///     - rhs: an array of type [Any]
    internal static func deepEquals(_ lhs: [Any], _ rhs: [Any]) -> Bool {
        // All elements have to be of type AnyCodable to perform element-wise comparisons
        let lhsAsCodables = lhs.map { AnyCodable._getAnyAsAnyCodable($0) }
        let rhsAsCodables = rhs.map { AnyCodable._getAnyAsAnyCodable($0) }
        
        return lhsAsCodables == rhsAsCodables
    }

    /// - Note: Internal for internal use in framework only
    ///
    /// Determines whether two Dictionaries [String: AnyCodable] are structurally equal
    /// (aka. deep equal) according to a recursive equality algorithm.
    ///
    /// - Parameters:
    ///     - lhs: a dictionary of type [String: AnyCodable]
    ///     - rhs: a dictionary of type [String: AnyCodable]
    /// - Returns: true if two dictionaries are structurally equal
    internal static func deepEquals(_ lhs: [String: AnyCodable], _ rhs: [String: AnyCodable]) -> Bool {
        if lhs.keys.count != rhs.keys.count {
            return false
        }
        
        for prop in lhs.keys {
            if let lhsVal = lhs[prop],
                let rhsVal = rhs[prop],
                lhsVal != rhsVal {
                return false
            }
        }
        
        return true
    }
    
    /// - Note: Internal for internal use in framework only
    ///
    /// Determines whether two CoatyObjects are structurally equal
    /// (aka. deep equal) according to a recursive equality algorithm.
    ///
    /// - Parameters:
    ///     - lhs: a Coaty object
    ///     - rhs: a Coaty object
    /// - Returns: true if the two objects are structurally equal (property names and values must be the same)
    internal static func deepEquals(_ lhs: CoatyObject, _ rhs: CoatyObject) -> Bool {
        let lhsProperties = AnyCodable.getDictionaryOfProperties(from: Mirror(reflecting: lhs))
        let rhsProperties = AnyCodable.getDictionaryOfProperties(from: Mirror(reflecting: rhs))
        
        if lhsProperties.keys.count != rhsProperties.keys.count {
            return false
        }
        
        for prop in lhsProperties.keys {
            if let lhsVal = lhsProperties[prop],
                let rhsVal = rhsProperties[prop],
                lhsVal != rhsVal {
                return false
            }
        }
        
        return true
    }
}

extension AnyCodable {
    /// Checks if a JavaScript value (usually an object or array) contains
    /// other values. Primitive value types (number, string, boolean, null,undefined) contain
    /// only the identical value. Object properties match if all the key-value
    /// pairs of the specified object are contained in them. Array properties
    /// match if all the specified array elements are contained in them.
    ///
    /// The general principle is that the contained object must match the containing object
    /// as to structure and data contents recursively on all levels, possibly after discarding
    /// some non-matching array elements or object key/value pairs from the containing object.
    /// But remember that the order of array elements is not significant when doing a containment match,
    /// and duplicate array elements are effectively considered only once.
    ///
    /// As a special exception to the general principle that the structures must match, an
    /// array on *toplevel* may contain a primitive value:
    /// ```ts
    /// contains([1, 2, 3], [3]) => true
    /// contains([1, 2, 3], 3) => true
    /// ```
    ///
    /// @param a a JavaScript value containing another value
    /// @param b a JavaScript value to be contained in another value
    internal static func deepContains(_ a: AnyCodable, _ b: AnyCodable) -> Bool {
        
        let bAsAnyCodable = AnyCodable._getAnyAsAnyCodable(b)!
        let aAsAnyCodable = AnyCodable._getAnyAsAnyCodable(a)!
        return AnyCodable._deepContains(aAsAnyCodable, bAsAnyCodable, true)
    }
    
    internal static func _deepContains(_ x: AnyCodable, _ y: AnyCodable, _ isTopLevel: Bool) -> Bool {
        if let xValues = x.value as? [AnyCodable] {
            if let yValues = y.value as? [AnyCodable] {
                return yValues.allSatisfy { yv -> Bool in
                    return xValues.contains { xv -> Bool in
                        AnyCodable._deepContains(xv, yv, false)
                    }
                }
            } else {
                // Special exception: check containment of a primitive array element on toplevel
                if isTopLevel {
                    return xValues.contains { xv -> Bool in
                        xv == y
                    }
                }
                return false
            }
            
        }
        
        if let xAsObject = x.value as? CoatyObject {
            if let yAsObject = y.value as? CoatyObject {
                let xProperties = AnyCodable.getDictionaryOfProperties(from: Mirror(reflecting: xAsObject))
                let yProperties = AnyCodable.getDictionaryOfProperties(from: Mirror(reflecting: yAsObject))
                
                return xProperties.keys.allSatisfy { xk -> Bool in
                    if yProperties.index(forKey: xk) == nil {
                        return false
                    }
                    return AnyCodable._deepContains(xProperties[xk]!, yProperties[xk]!, false)
                }
            } else {
                return false
            }
        }
        
        return x == y
    }
}

extension AnyCodable {
    
    /// - Note: Internal for internal use in framework only
    ///
    /// Checks if a value is included on toplevel in the given
    /// operand array of values which may be primitive types (number, string, boolean, null)
    /// or object types compared using the == equality operator.
    ///
    /// - Parameters:
    ///     - lhs: an  array containing another value on toplevel
    ///     - rhs: a  value to be contained on toplevel in an array
    /// - Returns: true if rhs is contained in lhs
    internal static func deepIncludes(_ lhs: AnyCodable, _ rhs: AnyCodable) -> Bool {
        // First argument must be an array of Any values
        guard let lhsAsArray = lhs.value as? [Any] else {
            return false
        }
        
        let lhsAsCodables = lhsAsArray.compactMap { AnyCodable._getAnyAsAnyCodable($0) }
        
        return lhsAsCodables.contains { element -> Bool in
            return element == rhs
        }
    }
}

extension AnyCodable {
    /// - Note: Internal for interal use in framework only
    ///
    /// Recursively get a dictionary of all properties as [String: AnyCodable] associated with a given mirror of an object
    ///
    /// - Parameters:
    ///     - mirror: mirror of the object that properties need to be extracted
    /// - Returns: a dictionary of all properties associated with the object (only those properties that can be represented as AnyCodable)
    internal static func getDictionaryOfProperties(from mirror: Mirror) -> [String: AnyCodable] {
        var result = [String: AnyCodable]()
        
        for child in mirror.children {
            result[child.label!] = AnyCodable._getAnyAsAnyCodable(child.value)
        }
        
        guard let superMirror = mirror.superclassMirror else {
            return result
        }
        
        return result.merging(AnyCodable.getDictionaryOfProperties(from: superMirror)) { (_, new) in
            new
        }
    }
}

extension AnyCodable: Comparable {
    public static func < (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return false
        case let (lhs as Bool, rhs as Bool):
            return (lhs == false) && (rhs == true)
        case let (lhs as Int, rhs as Int):
            return lhs < rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs < rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs < rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs < rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs < rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs < rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs < rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs < rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs < rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs < rhs
        case let (lhs as Float, rhs as Float):
            return lhs < rhs
        case let (lhs as Double, rhs as Double):
            return lhs < rhs
        case let (lhs as String, rhs as String):
            switch lhs.localizedCompare(rhs) {
            case .orderedAscending:
                return true
            default:
                return false
            }
        // CoatyUUID (description)
        default:
            return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyCodable(\(value.debugDescription))"
        default:
            return "AnyCodable(\(self.description))"
        }
    }
}

extension AnyCodable: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {}

