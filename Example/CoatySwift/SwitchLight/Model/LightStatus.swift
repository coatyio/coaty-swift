//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  LightStatus.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

/// Models the current status of a light including on-off, color-change and
/// luminosity-adjust features as a Coaty object type. Its `parentObjectId`
/// property refers to the associated `Light` object.
final class LightStatus: CoatyObject {
    
    /// Determines whether the light is currently switched on or off.
    var on: Bool;
    
    /// The current luminosity level of the light, a number between 0 (0%) and 1 (100%).
    var luminosity: Double;
    
    /// The current color of the light as an rgba tuple.
    var color: ColorRGBA;
    
    init(on: Bool, luminosity: Double, color: ColorRGBA) {
        self.on = on
        self.luminosity = luminosity
        self.color = color
        super.init(coreType: .CoatyObject,
                   objectType: SwitchLightObjectFamily.lightStatus.rawValue,
                   objectId: .init(),
                   name: "LightStatus")
    }
    
    // MARK: Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case on
        case luminosity
        case color
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.on = try container.decode(Bool.self, forKey: .on)
        self.luminosity =  try container.decode(Double.self, forKey: .luminosity)
        self.color = try container.decode(ColorRGBA.self, forKey: .color)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(on, forKey: .on)
        try container.encode(luminosity, forKey: .luminosity)
        try container.encode(color, forKey: .color)
    }
}
