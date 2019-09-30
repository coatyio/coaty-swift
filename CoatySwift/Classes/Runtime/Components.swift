//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Components.swift
//  CoatySwift
//
import Foundation

/// Defines the application-specific container components to be registered
/// with a Coaty Container.
///
/// The configuration options for the container component classes
/// are specified in the `controllers` options of a Configuration object.
public class Components<Family: ObjectFamily> {
    
    /// Application-specific controller classes to be registered
    /// with the runtime container. The configuration options for a
    /// controller class listed here are specified in the controller
    /// configuration under a key that matches the given name of the
    /// controller class.
    public var controllers: [String: Controller<Family>.Type]?
    
    public init(controllers: [String: Controller<Family>.Type]) {
        self.controllers = controllers
    }
}
