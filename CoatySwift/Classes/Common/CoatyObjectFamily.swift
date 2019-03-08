//
//  CoatyObjectFamily.swift
//  CoatySwift
//
//

import Foundation

/// CoatyObjectFamily defines the objectType to Class mapping for all Coaty default objects.
/// - TODO: Add remaining cases for the mapping.
/// - TODO: Make me private? Maybe it is required to stay public.
public enum CoatyObjectFamily: String, ClassFamily {
    case coatyObject = "coaty.CoatyObject"
    case user = "coaty.User"
    case device = "coaty.Device"
    case annotation = "coaty.Annotation"
    case task = "coaty.Task"
    case ioSource = "coaty.IoSource"
    case ioActor = "coaty.IoActor"
    case config = "coaty.Config"
    case log = "coaty.Log"
    case location = "coaty.Location"
    case snapshot = "coaty.Snapshot"
    case component = "coaty.Component"
    
    public func getType() -> AnyObject.Type {
        switch self {
        case .coatyObject:
            return CoatyObject.self
        case .component:
            return Component.self
        default:
            // TODO: Add remaining cases.
            return CoatyObject.self
        }
    }
}
