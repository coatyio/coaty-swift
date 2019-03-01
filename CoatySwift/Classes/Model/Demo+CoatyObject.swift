//
//  Demo+Advertise.swift
//  CoatySwift
//
//

import Foundation

/// DemoObjects shows a custom implementation of a CoatyObject for demonstration purposes.
/// When implementing a CoatyObject remember to conform to Codable by implementing
/// the required methods and call their super implementation inside them, e.g. in
/// encode(to encoder: Encoder) and init(from decoder: Decoder).
public class DemoObject: CoatyObject {
    
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
    
    required init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
    }
}
