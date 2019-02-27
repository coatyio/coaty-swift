//
//  PayloadCoder.swift
//  CoatySwift
//
//

import Foundation

/// PayloadCoder provides utility methods to encode and decode CoatyObjects from and to JSON.
class PayloadCoder {
    
    /// Decodes an arbitrary CoatyObject from its JSON representation.
    /// Note: The JSON decoding is based on the Codable protocol from the Swift standard library.
    /// Please make sure to implement it in all your classes and also call their base implementations.
    static func decode<T: Codable>(_ jsonString: String) -> T? {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(T.self, from: jsonData)
    }
    
    /// Encodes an arbitrary CoatyObject to its JSON representation.
    /// Note: The JSON encoding is based on the Codable protocol from the Swift standard library.
    /// Please make sure to implement it in all classes that implement the CoatyObject protocol.
    static func encode<T: Codable>(_ event: T) -> String {
        // TODO: Remove force unwrap.
        let jsonData = try! JSONEncoder().encode(event)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}
