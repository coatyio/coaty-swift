// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Device.swift
//  CoatySwift
//

import Foundation

/// Represents an interaction device associated with a Coaty user.
public class Device: CoatyObject {
    
    // MARK: - Attributes.
    
    /// The IO source and actors associated with this system component.
    /// - TODO: Missing device capabilities.
    /// ioCapabilities?: Array<IoSource | IoActor>;
    
    /// Display type of the interaction device.
    public var displayType: DisplayType
    
    // MARK: - Initializers.
    
    public init(objectType: String, objectId: CoatyUUID, name: String, displayType: DisplayType) {
        self.displayType = displayType
        super.init(coreType: .Device, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum DeviceKeys: String, CodingKey {
        case displayType
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DeviceKeys.self)
        self.displayType = try container.decode(DisplayType.self, forKey: .displayType)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: DeviceKeys.self)
        try container.encode(displayType, forKey: .displayType)
    }
}

// MARK: - DisplayType.

/// Defines display types for Coaty interaction devices.
public enum DisplayType: Int, Codable {
    
    /// A headless device representing a field device or a
    /// backend/service component.
    case none
    
    /// A smart watch.
    case watch
    
    /// An arm wearable.
    case arm
    
    /// A tablet.
    case tablet
    
    /// A monitor.
    case monitor
}
