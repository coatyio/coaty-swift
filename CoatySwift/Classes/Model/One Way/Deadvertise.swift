//
//  Deadvertise.swift
//  CoatySwift
//
//

import Foundation

/// Deadvertise implements the common fields from a standard Coaty Deadvertise message as defined in
/// the [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/)
public class Deadvertise: Codable {
    
    // MARK: - Required attributes.
    var objectIds: [UUID]
    
    // MARK: - Initializers.
    
    init(objectIds: [UUID]) {
        self.objectIds = objectIds
    }
    
    // MARK: - Codable methods.
    
    enum DeadvertiseCodingKeys: String, CodingKey {
        case objectIds
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DeadvertiseCodingKeys.self)
        
        // Decode required attributes.
        objectIds = try container.decode([UUID].self, forKey: .objectIds)

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DeadvertiseCodingKeys.self)
        
        // Encode required attributes.
        try container.encode(objectIds, forKey: .objectIds)
    }
}
