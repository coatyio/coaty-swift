// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
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

/// - TODO: Comment.
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


