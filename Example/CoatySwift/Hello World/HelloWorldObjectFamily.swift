//
//  HelloWorldCoatyObjectFamily.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift

/// TODO: Update documentation.
/// If you wish to receive CommunicationEvents that hold your personal, customized CoatyObjects
/// (e.g. objects that extend the basic CoatyObject class, such as the `HelloWorldTask` you have
/// to create your own class family that holds references to these custom objectTypes.
/// This way, CoatySwift can infer the types of your objects properly when
/// decoding messages.
/// - NOTE: If you wish to see another example for a ClassFamily, please see `CoatyObjectFamily`
/// in the CoatySwift framework.
enum HelloWorldObjectFamily: String, ObjectFamily {
    
    /// This is the objectType for a custom CoatyObject.
    case helloWorldTask = "com.helloworld.Task"
    case snapshot = "coaty.Snapshot"
    
    /// Define the mapping between objectType and your custom CoatyObject class type.
    /// For every objectType enum case you need a corresponding Swift class matching.
    func getType() -> AnyObject.Type {
        switch self {
        case .helloWorldTask:
            return HelloWorldTask.self
        case .snapshot:
            return Snapshot<HelloWorldObjectFamily>.self
        }
    }
    
    
}
