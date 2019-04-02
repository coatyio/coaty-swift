//
//  Device.swift
//  CoatySwift
//

import Foundation

// MARK: - Device.

/// Represents an interaction device associated with a Coaty user.
public class Device: CoatyObject {
    
    // TODO: Missing device capabilities.
    /**
     * The IO source and actors associated with this system component.
     */
    // ioCapabilities?: Array<IoSource | IoActor>;
    
    /// Display type of the interaction device.
    public var displayType: DisplayType
    
    public init(objectType: String, objectId: UUID, name: String, displayType: DisplayType) {
        self.displayType = displayType
        super.init(coreType: .Device, objectType: objectType, objectId: objectId, name: name)
    }
    
    public required init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
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
