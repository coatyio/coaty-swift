//
//  Demo+Advertise.swift
//  CoatySwift
//
//

import Foundation

class DemoAdvertise: Advertise {
    var message: String
    
    init(coreType: CoreType, objectType: String, objectId: UUID,
         name: String, message: String) {
        self.message = message
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        try super.init(from: decoder)
    }
    
    enum CodingKeys: String, CodingKey {
        case message
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
    }
}
