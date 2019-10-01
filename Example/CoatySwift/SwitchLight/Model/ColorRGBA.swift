//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ColorRGBA.swift
//  CoatySwift_Example
//
//

import Foundation

class ColorRGBA: Codable {
    
    private(set) public var r = 0
    private(set) public var g = 0
    private(set) public var b = 0
    private(set) public var a = 0.0
    
    /// Each color value needs to be 0 <= value <= 255.
    /// Alpha value 0 <= value <= 1.
    init(r: Int, g: Int, b: Int, a: Double) {
        if 0 <= r && r <= 255 {
            self.r = r
            
        }
        
        if 0 <= g && g <= 255 {
            self.b = b
        }
        
        if 0 <= b && b <= 255 {
            self.b = b
        }
        
        if 0 <= a && a <= 1 {
            self.a = a
        }
    }
    
    // MARK: Codable methods.
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.r = try container.decode(Int.self)
        self.g = try container.decode(Int.self)
        self.b = try container.decode(Int.self)
        self.a = try container.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(r)
        try container.encode(g)
        try container.encode(b)
        try container.encode(a)
    }
}
