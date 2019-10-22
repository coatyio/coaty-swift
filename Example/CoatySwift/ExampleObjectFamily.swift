//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleObjectFamily.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift

enum ExampleObjectFamily: String, ObjectFamily {
    case exampleObject = "io.coaty.hello-coaty.example-object"
    
    func getType() -> AnyObject.Type {
        switch self {
        case .exampleObject:
            return ExampleObject.self
        }
    }
}
