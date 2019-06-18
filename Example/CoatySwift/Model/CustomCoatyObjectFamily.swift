// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CustomCoatyObjectFamily.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift


/// If you wish to receive ChannelEvents that hold your personal, customised CoatyObjects
/// (e.g. objects that extend the basic CoatyObject class, such as the `DemoMessage` object in
///  `Demo+CoatyObject`) you have to create your own class family that holds references to these
/// custom objectTypes. This way, CoatySwift can infer the types of your objects properly when
/// decoding messages received over a channel.
/// - NOTE: If you wish to see another example for a ClassFamily, please see `CoatyObjectFamily`
/// in the CoatySwift framework.
enum CustomCoatyObjectFamily: String, ObjectFamily {
    
    /// This is an exemplary objectType for your custom CoatyObject.
    case demoObject = "org.example.coaty.demo-object"

    /// Define the mapping between objectType and your custom CoatyObject class type.
    /// For every objectType enum case you need a corresponding Swift class matching.
    func getType() -> AnyObject.Type {
        switch self {
        case .demoObject:
            return DemoObject.self
        }
    }
}
