//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Components.swift
//  CoatySwift
//
import Foundation

/// Defines the application-specific container components to be registered
/// with a Coaty Container.
public class Components {
    
    /// Application-specific controller classes to be registered
    /// with the runtime container under the given key.
    public var controllers: [String: Controller.Type]
    
    /// All _custom_, i.e. application-specific Coaty object types
    /// for which Swift class definitions are defined in the application.
    public var objectTypes: [CoatyObject.Type]
    
    /// Create a new instance of Components.
    ///
    /// Register your application-specific Coaty controller types and object types here.
    ///
    /// - Note: The configuration options for
    /// controller classes given here are specified in the controller
    /// configuration under a key that equals the key under which
    /// the controller type is registered here.
    ///
    /// - Note: Only register your custom object types; there is no need to register Coaty
    /// _core_ object types, as they are registered implicitly.
    ///
    /// - Parameters:
    ///     - controllers: Application-specific Coaty controller classes to be registered with the runtime container under the given key.
    ///     - objectTypes: Application-specific Coaty object type classes which are defined in the application.
    public init(controllers: [String: Controller.Type], objectTypes: [CoatyObject.Type]) {
        self.controllers = controllers
        self.objectTypes = objectTypes
    }
}
