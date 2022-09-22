//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.s

import Foundation

#if swift(>=4.2)
@usableFromInline
protocol _AnyEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _AnyEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension _AnyEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(int8)
        case let int16 as Int16:
            try container.encode(int16)
        case let int32 as Int32:
            try container.encode(int32)
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint8 as UInt8:
            try container.encode(uint8)
        case let uint16 as UInt16:
            try container.encode(uint16)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let coatyUUID as CoatyUUID:
            try container.encode(coatyUUID)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case let encodable as Encodable:
            try encodable.encode(to: &container)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

extension _AnyEncodable {
    public init(nilLiteral: ()) {
        self.init(nil as Any?)
    }
    
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
    
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public init(floatLiteral value: Double) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
    
    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init(Dictionary<AnyHashable, Any>(elements, uniquingKeysWith: { (first, _) in first }))
    }
}
