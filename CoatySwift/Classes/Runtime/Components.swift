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
public class Components {
    
    /// Application-specific controller classes to be registered
    /// with the runtime container. The configuration options for a
    /// controller class listed here are specified in the controller
    /// configuration under a key that matches the key under which
    /// the controller type is registered here.
    public var controllers: [String: Controller.Type]?
    
    /// Create a new instance of Components.
    public init(controllers: [String: Controller.Type]) {
        self.controllers = controllers
    }
}
