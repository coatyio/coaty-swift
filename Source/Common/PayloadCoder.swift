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
    /// Please make sure to implement it in all CommunicationEvent and CoatyObject classes.
    public static func decode<T: Codable>(_ jsonString: String) -> T? {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.initPushContext(forKey: "coreTypeKeys")
        do {
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            LogManager.log.debug("Could not decode \(T.self): \(error)")
            return nil
        }
    }
    
    /// Encodes a communication event to its JSON representation.
    ///
    /// - NOTE: The JSON encoding is based on the Codable protocol from the Swift standard library.
    /// Please make sure to implement it in all CommunicationEvent and CoatyObject classes.
    public static func encode<T: Codable>(_ event: T) -> String {
        let jsonData = try! JSONEncoder().encode(event)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}
