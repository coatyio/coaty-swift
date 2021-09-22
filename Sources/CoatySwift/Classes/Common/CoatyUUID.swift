//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyUUID.swift
//  CoatySwift
//
//

import Foundation

/// Custom implementation of a UUID that actually is compatible with the RFC
/// 4122 V4 specification of defining UUIDs (lowercase in contrast to
/// Apple's uppercase implementation).
public class CoatyUUID: Codable, CustomStringConvertible, Hashable {
    
    private var uuid: UUID
    
    /// The UUID as a lowercased string.
    public var string: String {
        return uuid.uuidString.lowercased()
    }
    
    /// Default initializer for a `CoatyUUID` object which assigns a new UUID.
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
    
    // MARK: - Hashable / Equatable methods.
    
    public static func == (lhs: CoatyUUID, rhs: CoatyUUID) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuid)
    }
    
    // MARK: - Custom String Convertible.
    
    public var description: String {
        return self.string
    }
}
