//
//  CoreType.swift
//  CoatySwift
//
//

import Foundation

/// All Coaty CoreTypes as defined in https://github.com/coatyio/coaty-js/blob/master/src/model/types.ts
enum CoreType: String, Codable {
    
    // MARK: - Value definitions.
    
    case CoatyObject
    case User
    case Device
    case Annotation
    case Task
    case IoSource
    case IoActor
    case Component
    case Config
    case Log
    case Location
    case Snapshot
    
    // MARK: - Codable methods.
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        
        // Try to parse the raw value to the actual enum.
        guard let coreType = CoreType(rawValue: rawString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Attempted to decode invalid enum."))
        }
        
        self = coreType
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
