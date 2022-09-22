//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
// Source: https://github.com/Flight-School/AnyCodable/tree/master/Sources/AnyCodable

import Foundation

/**
 A type-erased `Encodable` value.
 
 The `AnyEncodable` type forwards encoding responsibilities
 to an underlying value, hiding its specific underlying type.
 
 You can encode mixed-type values in dictionaries
 and other collections that require `Encodable` conformance
 by declaring their contained type to be `AnyEncodable`:
 
 let dictionary: [String: AnyEncodable] = [
 "boolean": true,
 "integer": 1,
 "double": 3.14159265358979323846,
 "string": "string",
 "array": [1, 2, 3],
 "nested": [
 "a": "alpha",
 "b": "bravo",
 "c": "charlie"
 ]
 ]
 
 let encoder = JSONEncoder()
 let json = try! encoder.encode(dictionary)
 */
public struct AnyEncodable: Encodable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyEncodable: _AnyEncodable {}

/// https://forums.swift.org/t/how-to-encode-objects-of-unknown-type/12253/5
extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

extension AnyEncodable: Equatable {
    public static func ==(lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
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
        case let (lhs as CoatyUUID, rhs as CoatyUUID):
            return lhs == rhs
        case (let lhs as [String: AnyEncodable], let rhs as [String: AnyEncodable]):
            return lhs == rhs
        case (let lhs as [AnyEncodable], let rhs as [AnyEncodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyEncodable: CustomStringConvertible {
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

extension AnyEncodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyEncodable(\(value.debugDescription))"
        default:
            return "AnyEncodable(\(self.description))"
        }
    }
}

extension AnyEncodable: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {}
