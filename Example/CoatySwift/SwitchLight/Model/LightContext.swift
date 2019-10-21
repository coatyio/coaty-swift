//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  LightContext.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

/// A Coaty object type that represents the environmental context of a light. The
/// light context defines a building number, a floor number, and a room number
/// indicating where the light is physically located. To control an individual
/// light, the light's ID is also defined in the context.
final class LightContext: CoatyObject {
    
    init(lightId: CoatyUUID = .init(), building: Int, floor: Int, room: Int) {
        self.lightId = lightId
        self.building = building
        self.floor = floor
        self.room = room
        super.init(coreType: .CoatyObject,
                   objectType: SwitchLightObjectFamily.lightContext.rawValue,
                   objectId: .init(),
                   name: "LightContext")
    }
    
    /// The object Id of the associated light.
    var lightId: CoatyUUID;
    
    /// The number of the building in which this light is located.
    var building: Int
    
    /// The number of the floor on which the light is located.
    var floor: Int
    
    /// The number of the room on which the light is located.
    var room: Int
    
    // MARK: Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case lightId
        case building
        case floor
        case room
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lightId = try container.decode(CoatyUUID.self, forKey: .lightId)
        self.building = try container.decode(Int.self, forKey: .building)
        self.floor = try container.decode(Int.self, forKey: .floor)
        self.room = try container.decode(Int.self, forKey: .room)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lightId, forKey: .lightId)
        try container.encode(building, forKey: .building)
        try container.encode(floor, forKey: .floor)
        try container.encode(room, forKey: .room)
    }
}
