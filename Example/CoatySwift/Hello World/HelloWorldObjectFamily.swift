//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  HelloWorldCoatyObjectFamily.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift

/// If you wish to receive CommunicationEvents that hold your personal,
/// customized CoatyObjects (e.g. objects that extend the basic CoatyObject
/// class, such as the `HelloWorldTask`) you have to create your own class
/// family that holds references to these custom objectTypes. This way,
/// CoatySwift can infer the types of your objects properly when decoding
/// messages.
/// - NOTE: If you wish to see another example for an ObjectFamily, please see
///   `CoatyObjectFamily` in the CoatySwift framework. The `CoatyObjectFamily`
///   represents a standard implementation using the built-in CoatyObject types.
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
            // A snapshot object may contain different objects. Therefore, we have to make sure to
            // customize the snapshots with the ObjectFamily for our application. The default fallback
            // only supports the core types.
            return Snapshot<HelloWorldObjectFamily>.self
        }
    }

}
