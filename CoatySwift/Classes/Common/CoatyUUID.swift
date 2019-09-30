//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyUUID.swift
//  CoatySwift
//
//

import Foundation

/// Custom implementation of a UUID that actually is compatible with the RFC
/// specification of sending UUIDs over the network (lowercase in contrast to Apple's
/// uppercase implementation. )
@objcMembers
public class CoatyUUID: NSObject, Codable {
    
    private var uuid: UUID
    
    public var string: String {
        return uuid.uuidString.lowercased()
    }
    
    public override init() {
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
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CoatyUUID {
            return self.uuid == other.uuid
        }
        return false
    }
    
    // MARK: - String Convertible.
    
    override public var description: String {
        return self.string
    }
}
