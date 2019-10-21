//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Light.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

/// Models a lighting source which can change color and adjust luminosity as a
/// Coaty object type. The light source status is represented by a separate object type
/// `LightStatus`, which is associated with its light by the `parentObjectId`
/// relationship.
final class Light: CoatyObject {
    
    /// Determines whether the light is currently defect. The default value is `false`.
    var isDefect: Bool
    
    init(isDefect: Bool = false) {
        self.isDefect = isDefect
        super.init(coreType: .CoatyObject,
                   objectType: SwitchLightObjectFamily.light.rawValue,
                   objectId: .init(),
                   name: "Light")
    }
    
    // MARK: Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case isDefect
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isDefect = try container.decode(Bool.self, forKey: .isDefect)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isDefect, forKey: .isDefect)
    }
}
