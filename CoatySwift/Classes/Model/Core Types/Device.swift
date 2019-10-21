//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Device.swift
//  CoatySwift
//

import Foundation

/// Represents an interaction device associated with a Coaty user.
open class Device: CoatyObject {
    
    // MARK: - Attributes.
    
    /// The IO source and actors associated with this system component.
    public var ioCapabilities: [IoPoint]?
    
    /// Display type of the interaction device.
    public var displayType: DisplayType
    
    // MARK: - Initializers.
    
    public init(displayType: DisplayType,
                ioCapabilities: [IoPoint]? = nil,
                name: String = "DeviceObject",
                objectType: String = "\(COATY_PREFIX)\(CoreType.Device)",
                objectId: CoatyUUID = .init()) {
        self.displayType = displayType
        self.ioCapabilities = ioCapabilities
        super.init(coreType: .Device, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum DeviceKeys: String, CodingKey {
        case displayType
        case ioCapabilities
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DeviceKeys.self)
        self.displayType = try container.decode(DisplayType.self, forKey: .displayType)
        self.ioCapabilities = try container.decodeIfPresent([IoPoint].self, forKey: .ioCapabilities)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: DeviceKeys.self)
        try container.encode(displayType, forKey: .displayType)
        try container.encodeIfPresent(ioCapabilities, forKey: .ioCapabilities)
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
