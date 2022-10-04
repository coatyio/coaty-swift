//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Container.swift
//  CoatySwift
//

import Foundation
import RxSwift
import XCGLogger

/// An IoC container that uses constructor dependency injection to create
/// container components and to resolve dependencies. This container defines the
/// entry and exit points for any Coaty application providing lifecycle
/// management for its components.
public class Container {
    
    // MARK: Attributes.
    
    /// Gets the identity object of this container.
    /// The identity can be initialized in the common configuration option
    /// `agentIdentity`.
    private (set) public var identity: Identity?

    /// Gets the runtime object of this container.
    private (set) public var runtime: Runtime?

    /// Gets the communication manager of this container.
    private (set) public var communicationManager: CommunicationManager?

    private var controllers = [String: Controller]()
    private var isShutdown = false
    private var operatingState: Observable<OperatingState>?
    private var operatingStateSubscription: Disposable?
    
    /// A dispatch queue handling controller synchronisation issues.
    private var queue: DispatchQueue!

    /// A queue ID needed to guarantee each container gets one dedicated queue __only__.
    private var queueID = "coatyswift.containerQueue." + UUID().uuidString

    /// Creates and bootstraps a Coaty container by registering and resolving the given components
    /// and configuratiuon options.
    ///
    /// - Parameters:
    ///   - components: the components to set up within this container
    ///   - configuration: the configuration options for the components
    public static func resolve(components: Components,
                               configuration: Configuration)  -> Container {
        
        // Adjust logging level for CoatySwift.
        LogManager.logLevel = LogManager.getLogLevel(logLevel: configuration.common?.logLevel ?? CoatySwiftLogLevel.error)

        let container = Container()
        
        // Add container specific dispatch queue.
        container.queue = DispatchQueue(label: container.queueID)
        
        // Ensure all Coaty core object types are registered.
        CoreType.registerCoreObjectTypes()
        
        // Ensure all SensorThings object types are registered.
        CoreType.registerSensorThingsTypes()
        
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
    ///     - controllerOptions: the controller's configuration options
    public func registerController(name: String, controllerType: Controller.Type, controllerOptions: ControllerOptions) throws {
        try queue.sync {
            if isShutdown {
                return
            }
            
            guard let _ = self.runtime,
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
                                               controllerOptions: controllerOptions)
            self.controllers[name] = controller
            
            controller.onInit()
            
            // Trigger onCommunicationManagerStarting() method.
            _ = communicationManager.getOperatingState().take(1).subscribe {
                if let state = $0.element, (state == .started) {
                    self.dispatchOperatingState(state: .started, ctrl: controller)
                }
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
                                   controllerOptions: ControllerOptions?) -> Controller {
        let controller = controllerType.init(container: self,
                                             options: controllerOptions,
                                             controllerType: name)
        return controller
    }
    
    private func registerCustomObjectTypes(_ components: Components) {
        for objectType in components.objectTypes {
            _ = objectType.objectType
        }
    }
    
    private func resolveComponents(_ components: Components,
                                   _ configuration: Configuration) {
        self.registerCustomObjectTypes(components)

        let identity = createIdentity(options: configuration.common?.agentIdentity)
        self.identity = identity
        let runtime = Runtime(commonOptions: configuration.common, databaseOptions: configuration.databases)
        self.runtime = runtime
        
        // Create CommunicationManager.
        let communicationManager = CommunicationManager(identity: self.identity!, communicationOptions: configuration.communication, commonOptions: configuration.common)
        self.communicationManager = communicationManager
        self.operatingState = communicationManager.operatingState.asObservable()

        // Create all controllers.
        components.controllers.forEach { (name, controllerType) in
            let options = configuration.controllers?.controllerOptions[name]
            let controller = resolveController(name: name,
                                               controllerType: controllerType,
                                               controllerOptions: options)
            self.controllers[name] = controller
        }
        
        // Finally call initialization lifecycle method of each controller.
        self.controllers.forEach { (name, controller) in
            controller.onInit()
        }
        
        var isInitialOperatingState = true;
        
        // Observe operating state and dispatch to registered controllers.
        self.operatingStateSubscription = operatingState?.subscribe { (operatingStateEvent) in
            if isInitialOperatingState {
                // Do not dispatch initial `stopped` state.
                isInitialOperatingState = false
                if operatingStateEvent.element == .stopped {
                    return
                }
            }
            self.controllers.forEach { (name, controller) in
                if let state = operatingStateEvent.element {
                    self.dispatchOperatingState(state: state, ctrl: controller)
                }
            }
        }

    }
    
    private func releaseComponents() {
        // Dispose Communication Manager first to trigger operating state changes
        communicationManager?.onDispose()
        self.controllers.forEach { (name, controller) in
            controller.onDispose()
        }

        self.operatingStateSubscription?.dispose();
        self.operatingStateSubscription = nil;
        self.controllers = [String: Controller]()
        self.communicationManager = nil
        self.runtime = nil
        self.identity = nil;
    }
    
    private func dispatchOperatingState(state: OperatingState, ctrl: Controller) {
        switch state {
        case OperatingState.started:
            ctrl.onCommunicationManagerStarting()
        case OperatingState.stopped:
            ctrl.onCommunicationManagerStopping()
        }
    }

    private func createIdentity(options: [String: Any]?) -> Identity {
        let identity = Identity(name: "Coaty Agent")

        // Merge property values from CommonOptions.agentIdentity option
        // ignoring coreType and objectType properties.
        if options != nil {
            for (key, value) in options! {
                switch key {
                    case "name":
                        identity.name = value as! String
                    case "objectId":
                        identity.objectId = value as! CoatyUUID
                    case "externalId":
                        identity.externalId = value as? String
                    case "parentObjectId":
                        identity.parentObjectId = value as? CoatyUUID
                    case "locationId":
                        identity.locationId = value as? CoatyUUID
                    case "isDeactivated":
                        identity.isDeactivated = value as? Bool
                    default:
                        break
                }
            }
        }

        return identity
    }
}
