//
//  Controller.swift
//  CoatySwift
//

import Foundation

/// An IoC container that uses constructor dependency injection to
/// create container components and to resolve dependencies.
/// This container defines the entry and exit points for any Coaty application
/// providing lifecycle management for its components.
open class Controller {
    
    private(set) public var runtime: Runtime
    private(set) public var options: ControllerOptions?
    private(set) public var controllerType: String
    private(set) public var identity: Component
    private var anyComManager: AnyCommunicationManager
    
    /// - Note: This method will crash in case the specified Object Family is NOT correctly set.
    /// - Returns: The Communication Manager for this particular Controller. This method is the only
    /// way of accessing the Communication Manager, and a reference to the Communication Manager
    /// should be stored inside the Controller subclass, preferably in a class variable.
    public func getCommunicationManager<Family: ObjectFamily>() -> CommunicationManager<Family> {
        return anyComManager as! CommunicationManager<Family>
    }
    
    required public init(runtime: Runtime,
                  options: ControllerOptions?,
                  communicationManager: AnyCommunicationManager,
                  controllerType: String) {
        self.runtime = runtime
        self.options = options ?? ControllerOptions()
        self.anyComManager = communicationManager
        self.controllerType = controllerType
        
        // Create default identity.
        self.identity = Component(name: self.controllerType,
                                  objectType: "\(COATY_PREFIX)\(CoreType.Component.rawValue)",
                                  objectId: .init())
        
        identity.parentObjectId = self.anyComManager.identity!.objectId
        self.initializeIdentity(identity: identity)
        
    }
    
    /// Called when the controller instance has been instantiated.
    /// This method is called immediately after the base controller
    /// constructor. The base implementation does nothing.
    ///
    /// Use this method to perform initializations in your custom
    /// controller class instead of defining a constructor.
    /// The method is called immediately after the controller instance
    /// has been created. Although the base implementation does nothing it is good
    /// practice to call super.onInit() in your override method; especially if your
    /// custom controller class extends from another custom controller class
    /// and not from the base `Controller` class directly.
    open func onInit() {}
    
    /// Called by the Coaty container after it has resolved and created all
    /// controller instances within the container. Implement initialization side
    /// effects here. The base implementation does nothing.
    ///
    /// - Parameters: the Coaty container of this controller.
    open func onContainerResolved(container: Container) {}
    
    /// Called when the communication manager is about to start or restart.
    /// Implement side effects here. Ensure that super.onCommunicationManagerStarting
    /// is called in your override. The base implementation advertises
    /// its identity if requested by the controller option property `shouldAdvertiseIdentity`
    /// (if this property is not specified, the identity is advertised by default).
    open func onCommunicationManagerStarting() {
        if let options = self.options, options.shouldAdvertiseIdentity {
            self.advertiseIdentity()
        }
    }
    
    /// Called when the communication manager is about to stop.
    /// Implement side effects here. Ensure that
    /// super.onCommunicationManagerStopping is called in your override.
    /// The base implementation does nothing.
    open func onCommunicationManagerStopping() {}
    
    /// Called by the Coaty container when this instance should be disposed.
    /// Implement cleanup side effects here. The base implementation does nothing.
    open func onDispose() {
    }
    
    /// Initialize identity object properties for a concrete controller subclass
    /// based on the specified default identity object.
    ///
    /// Do not call this method in your application code, it is called by the
    /// framework. To retrieve the identity of a controller use
    /// its `identity` getter.
    ///
    /// You can overwrite this method to initalize the identity with a custom name
    /// or additional application-specific properties. Alternatively, you can
    /// set or add custom property-value pairs by specifying them in the `identity`
    /// property of the controller configuration options `ControllerOptions`.
    /// If you specify identity properties in both ways, the ones specified
    /// in the configuration options take precedence.
    ///
    /// @param identity the default identity object for a controller instance
    open func initializeIdentity(identity: Component) {}
    
    private func advertiseIdentity() {
        let event = AdvertiseEvent<CoatyObjectFamily>.withObject(eventSource: self.identity,
                                              object: self.identity)
        
        try? self.anyComManager.publishAdvertise(advertiseEvent: event,
                                                        eventTarget: self.identity)
    }
}
