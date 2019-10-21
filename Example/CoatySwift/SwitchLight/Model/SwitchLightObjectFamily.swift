//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  SwitchLightObjectFamily.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

enum SwitchLightOperations: String {
    case lightControlOperation = "coaty.examples.remoteops.switchLight"
}

/// If you wish to receive CommunicationEvents that hold your personal,
/// customized CoatyObjects (e.g. objects that extend the basic CoatyObject
/// class, such as the `Light`) you have to create your own class family that
/// holds references to these custom objectTypes. This way, CoatySwift can infer
/// the types of your objects properly when decoding messages.
/// - NOTE: If you wish to see another example for an ObjectFamily, please see
///   `CoatyObjectFamily` in the CoatySwift framework. The `CoatyObjectFamily`
///   represents a standard implementation using the built-in CoatyObject types.
enum SwitchLightObjectFamily: String, ObjectFamily {
    case light = "coaty.examples.remoteops.Light"
    case lightContext = "coaty.examples.remoteops.LightContext"
    case lightStatus = "coaty.examples.remoteops.LightStatus"
    
    func getType() -> AnyObject.Type {
        switch self {
        case .light:
            return Light.self
        case .lightStatus:
            return LightStatus.self
        case .lightContext:
            return LightContext.self
        }
    }
}


