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
    
    public required init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    // MARK: - Codable methods.

    public required init(from decoder: Decoder) throws {
        // TODO: add Decodable conformance.
        fatalError("Codable is not implemented for Device.")
    }
    
    public override func encode(to encoder: Encoder) throws {
        // TODO: add Encodable conformance.
        fatalError("Codable is not implemented for Device.")
    }
}

// MARK: - DisplayType.

/// Defines display types for Coaty interaction devices.
public enum DisplayType {
    
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
