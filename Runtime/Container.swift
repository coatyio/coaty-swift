//
//  Container.swift
//  CoatySwift
//

import Foundation
import RxSwift



/**
 * Defines the application-specific container components to be registered
 * with a Coaty Container.
 *
 * The configuration options for the container component classes
 * are specified in the `controllers` options of a Configuration object.
 */
public class Components {
    
    /**
     * Application-specific controller classes to be registered
     * with the runtime container. The configuration options for a
     * controller class listed here are specified in the controller
     * configuration under a key that matches the given name of the
     * controller class.
     */
    public var controllers: [String: Controller.Type]?
}

/**
 * An IoC container that uses constructor dependency injection to
 * create container components and to resolve dependencies.
 * This container defines the entry and exit points for any Coaty application
 * providing lifecycle management for its components.
 */
public class Container {
    
    private var runtime: Runtime?
    private var comManager: CommunicationManager?
    private var controllers = [String: Controller]()
    private var isShutdown = false
    private var operatingState: Observable<OperatingState>
    
    /**
     * Creates and bootstraps a Coaty container by registering and resolving
     * the given components and configuration options.
     * @param components the components to set up within this container
     * @param configuration the configuration options for the components
     * @param configTransformer a function to transform the given configuration (optional)
     * @returns a Container for the given components
     * @throws if configuration is falsy.
     */
    
    private init(comManager: CommunicationManager? = nil, isShutdown: Bool) {
        self.comManager = comManager
        self.isShutdown = isShutdown
        self.operatingState = ((comManager?.operatingState)?.asObservable())!
    }
    
    // TODO: Missing config transformer dependency.
    public static func resolve(components: Components,
                               configuration: Configuration
                               /* configTransformer: */)  -> Container {
      
        let container = Container(comManager: nil, isShutdown: false)
        
        container.resolveComponents(components, configuration)
        
        return container
    }
    

    /*
    
    /**
     * Asynchronously creates and bootstraps a Coaty container by registering and
     * resolving the given components and configuration options.
     * Use this method if configuration should be retrieved asnychronously
     * (e.g. via HTTP) by one of the predefined runtime configuration providers
     * (see runtime-angular, runtime-node).
     * The promise returned will be rejected if the configuration could not be
     * retrieved or has a falsy value.
     * @param components the components to set up within this container
     * @param configuration a promise for the configuration options
     * @param configTransformer a function to transform the retrieved configuration (optional)
     * @returns a promise on a Container for the given components
     */
    static resolveAsync(
    components: Components,
    configuration: Promise<Configuration>,
    configTransformer?: (config: Configuration) => Configuration,
    ): Promise<Container> {
    return new Promise<Container>((resolve, reject) => {
    configuration.then(
    config => {
    resolve(Container.resolve(components, config, configTransformer));
    },
    reason => {
    reject(new Error(`Couldn't fetch async configuration: ${reason}`));
    });
    });
    }
    
    /**
     * Dynamically registers and resolves the given controller class
     * with the specified controller config options.
     * The request is silently ignored if the container has already
     * been shut down.
     *
     * @param className the name of the controller class (must match the controller name specified in controller config options)
     * @param classType the class type of the controller
     * @param config the controller's configuration options
     * @returns the resolved controller instance or `undefined` if no controller could be resolved
     */
    registerController<T extends IController>(
    className: string,
    classType: IControllerStatic<T>,
    config: ControllerConfig) {
    
    if (this._isShutdown) {
    return;
    }
    
    const ctrl = this._resolveController(className, classType, this._runtime, config, this._comManager);
    if (ctrl) {
    ctrl.onContainerResolved(this);
    this._comManager.observeOperatingState()
    .subscribe(opState => {
    if (opState === OperatingState.Started ||
    opState === OperatingState.Starting) {
    this._dispatchOperatingState(OperatingState.Starting, ctrl);
    }
    })
    .unsubscribe();
    }
    return ctrl as T;
    }
    
    /**
     * Gets the runtime object of this container.
     */
    getRuntime() {
    return this._runtime;
    }
    
    /**
     * Gets the communication manager of this container.
     */
    getCommunicationManager() {
    return this._comManager;
    }
    
    /**
     * Gets the registered controller of the given class type.
     * Returns undefined if the controller class type is not registered.
     * @param classType the class type of the controller
     */
    getController<T extends IController>(classType: IControllerStatic<T>): T {
    return this._controllers && this._controllers.get(classType) as T;
    }
    
    /**
     * Creates a new array with the results of calling the provided callback
     * function once for each registered controller classType/classInstance
     * pair.
     * @param callback function that produces an element of the new array
     */
    mapControllers<T>(callback: (classType: IControllerStatic<IController>, controller: IController) => T) {
    const results: T[] = [];
    this._controllers && this._controllers.forEach((value, index) => results.push(callback(index, value)));
    return results;
    }
    
    /**
     * The exit point for a Coaty applicaton.
     * Releases all registered container components and its associated system resources.
     * This container should no longer be used afterwards.
     */
    shutdown() {
    if (this._isShutdown) {
    // Fail-safe
    return;
    }
    this._isShutdown = true;
    this._releaseComponents();
    }*/
    
    private func resolveComponents(_ components: Components, _ configuration: Configuration) {
        let runtime = Runtime()
        self.runtime = runtime
        
        // TODO: Fix force unwrap.
        let host = configuration.communication.brokerOptions!.host
        let port = configuration.communication.brokerOptions!.port
        let comManager = CommunicationManager(host: host, port: Int(port))
    
        components.controllers?.forEach { (name, controllerType) in
            let options = configuration.controllers?.controllerOptions[name]
            let controller = controllerType.init(runtime: runtime,
                                                 options: options,
                                                 communicationManager: comManager,
                                                 controllerType: name)
            controller.onInit()
            self.controllers[name] = controller
        }
        
        // Then call initialization method of each controller.
        controllers.forEach { (name, controller) in
            controller.onContainerResolved(container: self)
        }
        
        // Observe operating state and dispatch to registered controllers.
        operatingState.subscribe { (operatingStateEvent) in
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
            break
        }
    }
}

