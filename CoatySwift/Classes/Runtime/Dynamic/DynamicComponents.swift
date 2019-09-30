//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DynamicComponents.swift
//  CoatySwift
//

import Foundation

/// - __Experimental__: Defines the application-specific container components to be registered
/// with a dynamic Coaty Container.
///
/// The configuration options for the container component classes
/// are specified in the `controllers` options of a Configuration object.
public class DynamicComponents {
    
    /// Application-specific controller classes to be registered
    /// with the runtime container. The configuration options for a
    /// controller class listed here are specified in the controller
    /// configuration under a key that matches the given name of the
    /// controller class.
    public var controllers: [String: DynamicController.Type]?
    
    public init(controllers: [String: DynamicController.Type]) {
        self.controllers = controllers
    }
}
