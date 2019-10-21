//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  PayloadCoder.swift
//  CoatySwift
//
//

import Foundation

/// PayloadCoder provides utility methods to encode and decode communication events from and to JSON.
public class PayloadCoder {
    
    /// Decodes a communication event from its JSON representation.
    ///
    /// - NOTE: The JSON decoding is based on the Codable protocol from the Swift standard library.
    /// Please make sure to implement it in all your classes and also call their base implementations.
    public static func decode<T: Codable>(_ jsonString: String) -> T? {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: jsonData)
    }
    
    /// Encodes a communication event to its JSON representation.
    ///
    /// - NOTE: The JSON encoding is based on the Codable protocol from the Swift standard library.
    /// Please make sure to implement it in all classes that implement the CoatyObject protocol.
    public static func encode<T: Codable>(_ event: T) -> String {
        let jsonData = try! JSONEncoder().encode(event)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}
