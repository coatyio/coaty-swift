//
//  CustomCoatyObjectFamily.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift


/// TODO: Add me.
enum CustomCoatyObjectFamily: String, ClassFamily {
    case demoMessage = "org.example.coaty.demo-message"
    
    func getType() -> AnyObject.Type {
        switch self {
        case .demoMessage:
            return DemoObject.self
        }
    }
}
