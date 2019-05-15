//
//  Controller.swift
//  CoatySwift
//

import Foundation
import RxSwift

/// An IoC container that uses constructor dependency injection to
/// create container components and to resolve dependencies.
/// This container defines the entry and exit points for any Coaty application
/// providing lifecycle management for its components.
open class Controller<Family: ObjectFamily> {
    
    /// This is the communicationManager for this particular controller.
    private (set) public var communicationManager: CommunicationManager<Family>
    
    /// This is the factory for this particular controller that is used to
    /// create CommunicationEvents.
    private (set) public var eventFactory: EventFactory<Family>
    private (set) public var runtime: Runtime
    private (set) public var options: ControllerOptions?
    private (set) public var controllerType: String
    private (set) public var identity: Component
    
    /// This disposebag holds references to all of your subscriptions. It is standard in RxSwift
    /// to call `.disposed(by: self.disposeBag)` at the end of every subscription.
    public var disposeBag = DisposeBag()
    
    required public init(runtime: Runtime,
                  options: ControllerOptions?,
                  communicationManager: CommunicationManager<Family>,
                  eventFactory: EventFactory<Family>,
                  controllerType: String) {
        self.runtime = runtime
        self.options = options ?? ControllerOptions()
        self.communicationManager = communicationManager
        self.eventFactory = eventFactory
        self.controllerType = controllerType
        
        // Create default identity.
        self.identity = Component(name: self.controllerType,
                                  objectType: "\(COATY_PREFIX)\(CoreType.Component.rawValue)",
                                  objectId: .init())
        
        identity.parentObjectId = self.communicationManager.identity!.objectId
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
    open func onContainerResolved(container: Container<Family>) {}
    
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
 
        try? self.communicationManager.publishAdvertise(advertiseEvent: event,
                                                        eventTarget: self.identity)
        
    }
    
    deinit {
        onDispose()
    }
}
