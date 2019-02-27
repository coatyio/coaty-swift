//
//  Demo+Advertise.swift
//  CoatySwift
//
//

import Foundation

/// DemoAdvertise implements a customized Advertise message for demonstration purposes.
/// When implementing a custom Advertise message make sure to conform to Codable by implementing
/// the required methods and call their super implementation inside them.
/// It may be altered or entirely removed in the future.
class DemoAdvertise: Advertise {
    
    // MARK: - Public Attributes.
    
    var message: String
    
    // MARK: - Initializers.
    
    init(coreType: CoreType, objectType: String, objectId: UUID,
         name: String, message: String) {
        self.message = message
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case message
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
    }
}
