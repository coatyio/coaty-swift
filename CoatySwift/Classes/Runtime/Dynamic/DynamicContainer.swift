//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DynamicContainer.swift
//  CoatySwift
//

import Foundation
import RxSwift
import XCGLogger

/// - __Experimental__: An IoC container that uses constructor dependency injection to
/// create container components and to resolve dependencies for __dynamic Coaty__.
/// This container defines the entry and exit points for any Coaty application
/// providing lifecycle management for its components.
public class DynamicContainer {
    
    // MARK: Attributes.
    
    private (set) public var runtime: Runtime?
    private (set) public var communicationManager: DynamicCommunicationManager?
    private (set) public var eventFactory: DynamicEventFactory?
    private var controllers = [String: DynamicController]()
    private var isShutdown = false
    private var operatingState: Observable<OperatingState>?
    
    /// A dispatch queue handling controller synchronisation issues.
    private var queue: DispatchQueue!
    /// A queue ID needed to guarantee each container gets one dedicated queue __only__.
    private var queueID = "coatyswift.containerQueue." + UUID().uuidString
    
    private var communicationState: Observable<CommunicationState>?
    
    public static func resolve(components: DynamicComponents,
                               configuration: Configuration)  -> DynamicContainer {
        
        // Adjust logging level for CoatySwift.
        LogManager.logLevel = LogManager.getLogLevel(logLevel: configuration.common.logLevel)
        
        let container = DynamicContainer()
        
        // Add container specific dispatch queue.
        container.queue = DispatchQueue(label: container.queueID)
        
        container.resolveComponents(components, configuration)
        return container
    }
    
    /// Dynamically registers and resolves the given controller class
    /// with the specified controller config options.
    /// The request is silently ignored if the container has already
    /// been shut down.
    ///
    /// - Parameters:
    ///     - name: the name of the controller class (must match the controller name
    ///             specified in controller config options)
    ///     - controllerType: the class type of the controller
    ///     - config: the controller's configuration options
    public func registerController(name: String, controllerType: DynamicController.Type, config: ControllerConfig) throws {
        try queue.sync {
            if isShutdown {
                return
            }
            
            guard let runtime = self.runtime,
                let communicationManager = self.communicationManager else {
                    LogManager.log.error("Runtime or CommunicationManager was not initialized.")
                    throw CoatySwiftError.InvalidConfiguration("Runtime or CommunicationManager was not initialized.")
            }
            
            if self.controllers[name] != nil {
                LogManager.log.error("Controller with given name already exists.")
                throw CoatySwiftError.InvalidConfiguration("Controller with given name already exists.")
            }
            
            let controller = resolveController(name: name,
                                               controllerType: controllerType,
                                               runtime: runtime,
                                               communicationManager: communicationManager,
                                               controllerOptions: config.controllerOptions[name])
            self.controllers[name] = controller
            
            controller.onContainerResolved(container: self)
            
            // Trigger onCommunicationManagerStarting() method.
            _ = communicationManager.getOperatingState().subscribe {
                if let state = $0.element, (state == .starting || state == .started) {
                    self.dispatchOperatingState(state: .starting, ctrl: controller)
                }
            }
        }
    }
    
    /// Gets the registered controller of the given name.
    /// Returns nil if the controller class type is not registered.
    /// - Parameters:
    ///     - name: the name of the controller
    public func getController(name: String) -> DynamicController? {
        return self.controllers[name]
    }
    
    /// Creates a new array with the results of calling the provided callback
    /// function once for each registered controller classType/classInstance
    /// pair.
    /// - Parameters:
    ///     - f: function that produces an element of the new array
    public func mapControllers<T>(_ f: (String, DynamicController) -> T) -> [T] {
        var mapResult = [T]()
        controllers.forEach { (name, controller) in
            let result = f(name, controller)
            mapResult.append(result)
        }
        
        return mapResult
    }
    
    /// The exit point for a Coaty applicaton.
    /// Releases all registered container components and its associated system resources.
    /// This container should no longer be used afterwards.
    public func shutdown() {
        if self.isShutdown {
            return
        }
        
        self.isShutdown = true
        self.releaseComponents()
    }
    
    private func resolveController(name: String,
                                   controllerType: DynamicController.Type,
                                   runtime: Runtime,
                                   communicationManager: DynamicCommunicationManager,
                                   controllerOptions: ControllerOptions?) -> DynamicController {
        let controller = controllerType.init(runtime: runtime,
                                             options: controllerOptions,
                                             communicationManager: communicationManager,
                                             controllerType: name)
        controller.onInit()
        return controller
    }
    
    private func resolveComponents(_ components: DynamicComponents,
                                   _ configuration: Configuration) {
        let runtime = Runtime(commonOptions: configuration.common, databaseOptions: configuration.databases)
        self.runtime = runtime
        
        // Create CommunicationManager.
        let communicationManager = DynamicCommunicationManager(runtime: runtime, communicationOptions: configuration.communication)
        self.communicationManager = communicationManager
        
        // Create EventFactory.
        let eventFactory = EventFactory<CoatyObjectFamily>(communicationManager.identity)
        self.eventFactory = eventFactory

        self.operatingState = communicationManager.operatingState.asObservable()
        self.communicationState = communicationManager.communicationState.asObservable()
        
        components.controllers?.forEach { (name, controllerType) in
            let options = configuration.controllers?.controllerOptions[name]
            let controller = resolveController(name: name,
                                               controllerType: controllerType,
                                               runtime: runtime,
                                               communicationManager: communicationManager,
                                               controllerOptions: options)
            self.controllers[name] = controller
        }
        
        // Then call initialization method of each controller.
        controllers.forEach { (name, controller) in
            controller.onContainerResolved(container: self)
        }
        
        // Observe operating state and dispatch to registered controllers.
        _ = operatingState?.subscribe { (operatingStateEvent) in
            self.controllers.forEach { (name, controller) in
                if let state = operatingStateEvent.element {
                    self.dispatchOperatingState(state: state, ctrl: controller)
                }
            }
        }
        
        // Finally start communication manager if auto-connect option is set.
        if (configuration.communication.shouldAutoStart) {
            communicationManager.start()
        }
        
    }
    
    private func releaseComponents() {
        // Dispose Communication Manager first to trigger operating state changes
        communicationManager?.onDispose()
        self.controllers.forEach { (name, controller) in
            controller.onDispose()
        }
        
        self.controllers = [String: DynamicController]()
        self.communicationManager = nil
        self.runtime = nil
    }
    
    private func dispatchOperatingState(state: OperatingState, ctrl: DynamicController) {
        switch state {
        case OperatingState.starting:
            ctrl.onCommunicationManagerStarting()
        case OperatingState.stopping:
            ctrl.onCommunicationManagerStopping()
        default:
            ()
        }
    }
}
