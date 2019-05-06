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
    
    /// - TODO: Validation. Each color value needs to be 0 <= value <= 255
    init(r: Int, g: Int, b: Int, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        
        // Alpha between 0..1
        self.a = a
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
