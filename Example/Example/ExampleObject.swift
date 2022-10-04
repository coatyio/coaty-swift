//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleObject.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift

final class ExampleObject: CoatyObject {
    
    // MARK: - Class registration.
    
    override class var objectType: String {
        return register(objectType: "hello.coaty.ExampleObject", with: self)
    }
    
    // MARK: - Initializers.
    
    let myValue: String
    
    init(myValue: String) {
        self.myValue = myValue
        super.init(coreType: .CoatyObject,
                   objectType: ExampleObject.objectType,
                   objectId: .init(),
                   name: "ExampleObject Name :)")
    }
    
    // MARK: Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case myValue
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.myValue = try container.decode(String.self, forKey: .myValue)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.myValue, forKey: .myValue)
    }
    
}
    

