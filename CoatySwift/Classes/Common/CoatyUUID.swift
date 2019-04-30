//
//  CoatyUUID.swift
//  CoatySwift
//
//

import Foundation

/// TODO: Missing comment
public class CoatyUUID: Codable {
    
    private var uuid: UUID
    
    public var string: String {
        return uuid.uuidString.lowercased()
    }
    
    public init() {
        self.uuid = .init()
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
    
}
