//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyUUID.swift
//  CoatySwift
//
//

import Foundation

/// Custom implementation of a UUID that actually is compatible with the RFC
/// specification of sending UUIDs over the network (lowercase in contrast to Apple's
/// uppercase implementation).
public class CoatyUUID: Codable, Equatable {
    
    private var uuid: UUID
    
    public var string: String {
        return uuid.uuidString.lowercased()
    }
    
    public init() {
        self.uuid = .init()
    }
    
    public init?(uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        
        self.uuid = uuid
    }
    
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.uuid = try container.decode(UUID.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.string)
    }
    
    // MARK: - Equatable methods.
    
    public static func == (lhs: CoatyUUID, rhs: CoatyUUID) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    // MARK: - String Convertible.
    
    public var description: String {
        return self.string
    }
}
