//
//  Container.swift
//  CoatySwift
//

import Foundation
import RxSwift

/// An IoC container that uses constructor dependency injection to
/// create container components and to resolve dependencies.
/// This container defines the entry and exit points for any Coaty application
/// providing lifecycle management for its components.
public class Container {
    
    // MARK: Attributes.
    
    private (set) public var runtime: Runtime?
    private (set) public var comManager: AnyCommunicationManager?
    private var controllers = [String: Controller]()
    private var isShutdown = false
    private var operatingState: Observable<OperatingState>?
    
    // FIXME: Currently we're using our communication state observable to find out whether
    // we can subscribe / publish or not.
    // HOWEVER: IT SHOULD BE OPERATING STATE BASED.
    private var communicationState: Observable<CommunicationState>?
    
    /// Creates and bootstraps a Coaty container by registering and resolving
    /// the given components and configuration options.
    ///
    /// - NOTE: Currently we do not rely on this initializer. It may be possible to remove it.
    /// - Parameters:
    ///     - components the components to set up within this container
    ///     - configuration the configuration options for the components
    /*private init(comManager: CommunicationManager? = nil, isShutdown: Bool) {
        self.comManager = comManager
        self.isShutdown = isShutdown
        self.operatingState = ((comManager?.operatingState)?.asObservable())!
    }*/
    
    // TODO: Missing config transformer dependency.
    public static func resolve<Family: ObjectFamily>(components: Components,
                               configuration: Configuration,
                               objectFamily: Family.Type
                               /* configTransformer: */)  -> Container {
      
        let container = Container()
        container.resolveComponents(components, configuration, objectFamily)
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
    public func registerController(name: String, controllerType: Controller.Type, config: ControllerConfig) {
        if isShutdown {
            return
        }
        
        guard let runtime = self.runtime, let comManager = self.comManager else {
            LogManager.log.error("Runtime or CommunicationManager was not initialized.")
            return
        }
        let controller = resolveController(name: name,
                                           controllerType: controllerType,
                                           runtime: runtime,
                                           comManager: comManager,
                                           controllerOptions: config.controllerOptions[name])
        self.controllers[name] = controller
        
        controller.onContainerResolved(container: self)

        // Trigger onCommunicationManagerStarting() method.
        _ = comManager.getOperatingState().subscribe {
            if let state = $0.element, (state == .starting || state == .started) {
                self.dispatchOperatingState(state: .starting, ctrl: controller)
            }
        }
    }
    
    /// Gets the registered controller of the given name.
    /// Returns nil if the controller class type is not registered.
    /// - Parameters:
    ///     - name: the name of the controller
    public func getController<C: Controller>(name: String) -> C? {
        return self.controllers[name] as? C
    }
    
    /// Creates a new array with the results of calling the provided callback
    /// function once for each registered controller classType/classInstance
    /// pair.
    /// - Parameters:
    ///     - f: function that produces an element of the new array
    public func mapControllers<T>(_ f: (String, Controller) -> T) -> [T] {
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
                                   controllerType: Controller.Type,
                                   runtime: Runtime,
                                   comManager: AnyCommunicationManager,
                                   controllerOptions: ControllerOptions?) -> Controller {
        let controller = controllerType.init(runtime: runtime,
                                             options: controllerOptions,
                                             communicationManager: comManager,
                                             controllerType: name)
        controller.onInit()
        return controller
    }
    
    private func resolveComponents<Family: ObjectFamily>(_ components: Components,
                                                         _ configuration: Configuration,
                                                         _ family: Family.Type) {
        let runtime = Runtime(commonOptions: configuration.common, databaseOptions: configuration.databases)
        self.runtime = runtime
        
        // TODO: Fix force unwrap.
        let host = configuration.communication.brokerOptions!.host
        let port = configuration.communication.brokerOptions!.port
        let comManager = CommunicationManager<Family>(host: host, port: Int(port))
        self.comManager = comManager
        self.operatingState = comManager.operatingState.asObservable()
        self.communicationState = comManager.communicationState.asObservable()

        components.controllers?.forEach { (name, controllerType) in
            let options = configuration.controllers?.controllerOptions[name]
            let controller = resolveController(name: name,
                                               controllerType: controllerType,
                                               runtime: runtime,
                                               comManager: comManager,
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
            comManager.start()
        }

    }
    
    private func releaseComponents() {
        // Dispose Communication Manager first to trigger operating state changes
        comManager?.onDispose()
        self.controllers.forEach { (name, controller) in
            controller.onDispose()
        }

        self.controllers = [String: Controller]()
        self.comManager = nil
        self.runtime = nil
    }
    
    private func dispatchOperatingState(state: OperatingState, ctrl: Controller) {
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

/// Defines the application-specific container components to be registered
/// with a Coaty Container.
///
/// - TODO: Move to separate file.
/// The configuration options for the container component classes
/// are specified in the `controllers` options of a Configuration object.
public class Components {
    
    /// Application-specific controller classes to be registered
    /// with the runtime container. The configuration options for a
    /// controller class listed here are specified in the controller
    /// configuration under a key that matches the given name of the
    /// controller class.
    public var controllers: [String: Controller.Type]?
    
    public init(controllers: [String: Controller.Type]) {
        self.controllers = controllers
    }
}
