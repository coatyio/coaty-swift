//
//  Demo+Advertise.swift
//  CoatySwift_Example
//
//  Created by Sandra Grujovic on 25.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/* class DemoAdvertise: Advertise {
    var message: String
    
    init(coreType: CoreType, objectType: String, objectId: UUID,
                  name: String, message: String) {
        self.message = message
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    enum CodingKeys: String, CodingKey {
        case message
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerCodingKeys.self)
        let object = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .object)
        
        message = try object.decode(String.self, forKey: .message)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ContainerCodingKeys.self)
        var object = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .object)
        try object.encode(message, forKey: .message)
        try super.encode(to: encoder)
    }
}

*/

class DemoAdvertise: Advertise {
    var message: String
    
    init(coreType: CoreType, objectType: String, objectId: UUID,
         name: String, message: String) {
        self.message = message
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerCodingKeys.self)
        let object = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .object)
        
        message = try object.decode(String.self, forKey: .message)
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

// MARK: - Extension enable easy access to JSON representation of DemoAdvertise object.
extension DemoAdvertise {
    var json: String { get {
        return PayloadCoder.encode(self)
        }
    }
}
