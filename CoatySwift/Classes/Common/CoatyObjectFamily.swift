//
//  CoatyObjectFamily.swift
//  CoatySwift
//
//

import Foundation

/// - TODO: Comment me.
/// - TODO: Make me private.
public enum CoatyObjectFamily: String, ClassFamily {
    
    /*
    case User
    case Device
    case Annotation
    case Task
    case IoSource
    case IoActor
    case Config
    case Log
    case Location
    case Snapshot*/
    
    // TODO: add all cases.
    case component = "coaty.Component"
    case coatyObject = "coaty.CoatyObject"
    
    public func getType() -> AnyObject.Type {
        switch self {
        case .component:
            return Component.self
        case .coatyObject:
            return CoatyObject.self
        }
    }
}
