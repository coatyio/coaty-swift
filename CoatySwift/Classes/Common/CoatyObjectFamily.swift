//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyObjectFamily.swift
//  CoatySwift
//
//

import Foundation

/// CoatyObjectFamily defines the objectType to Class mapping for all Coaty default objects.
public enum CoatyObjectFamily: String, ObjectFamily {
    case coatyObject = "coaty.CoatyObject"
    case user = "coaty.User"
    case device = "coaty.Device"
    case annotation = "coaty.Annotation"
    case task = "coaty.Task"
    case ioSource = "coaty.IoSource"
    case ioActor = "coaty.IoActor"
    
    /// Config is unspported for CoatySwift.
    case config = "coaty.Config"
    case log = "coaty.Log"
    case location = "coaty.Location"
    case snapshot = "coaty.Snapshot"
    case component = "coaty.Component"
    
    // Core type matching for dynamic coaty applications.
    // TODO: Add missing core types.
    case core_CoatyObject = "CoatyObject"
    case core_Task = "Task"
    case core_Snapshot = "Snapshot"
    
    public func getType() -> AnyObject.Type {
        switch self {
        case .coatyObject:
            return CoatyObject.self
        case .component:
            return Component.self
        case .snapshot:
            // TODO: This does _not_ work. For now we decided to let the application programmer
            // implement the mapping. We might decide to drop the CoatyObjectFamily entirely.
            return Snapshot<CoatyObjectFamily>.self
        case .user:
            return User.self
        case .device:
            return Device.self
        case .annotation:
            return Annotation.self
        case .ioSource:
            return IoSource.self
        case .ioActor:
            return IoActor.self
        case .location:
            return Location.self
        case .task:
            return Task.self
        case .log:
            return Log.self
        
        // Core type matching for dynamic coaty applications.
        case .core_Task:
            return Task.self
        case .core_CoatyObject:
            return CoatyObject.self
        case .core_Snapshot:
            return Snapshot<CoatyObjectFamily>.self
    
        default:
            return CoatyObject.self
        }
    }
}
