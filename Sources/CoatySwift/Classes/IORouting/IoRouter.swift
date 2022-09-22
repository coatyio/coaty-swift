//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoRouter.swift
//  CoatySwift
//
//

import Foundation

/// Base IO router class for context-driven routing of IO values.
///
/// This router implements the base logic of routing. It observes IO nodes that
/// are associated with the router's IO context and manages routes for the IO
/// sources and actors of these nodes.
///
/// This router implements a basic routing algorithm where all compatible pairs
/// of IO sources and IO actors are associated. An IO source and an IO actor are
/// compatible if both define equal value types in equal data formats. You
/// can define your own custom compatibility check on value types in a subclass
/// by overriding the `areValueTypesCompatible` method.
///
/// To implement context-specific routing strategies extend this class and
/// implement the methods marked with the fatal error: "This method must be overridden"
///
/// Note that this router makes its IO context available for discovery (by core
/// type, object type, or object Id) and listens for Update-Complete events on
/// its IO context, triggering `onIoContextChanged` automatically.
///
/// This base router class requires the following controller options:
///  - `ioContext`: the IO context for which this router is managing routes
///   (mandatory) Otherwise a fatalError is thrown
public class IoRouter: Controller {
    
    // MARK: - Attributes.
    
    internal var ioContext: IoContext!
    /// Key: CoatyUUID, Value: IoNode
    internal var managedIoNodes: NSMutableDictionary = .init()
    /// Key: CoatyUUID, Value: (String, Bool)
    internal var sourceRoutes: NSMutableDictionary = .init()
    
    // MARK: - Overridden Controller lifecycle methods.
    
    public override func onInit() {
        super.onInit()
        
        guard let ioContext = self.options?.extra["ioContext"] as? IoContext else {
            fatalError("no IO context configured for IO router: specify an IoContext object in controller option 'ioContext'")
        }
        
        self.ioContext = ioContext
        self.ioContext.parentObjectId = self.container.identity?.objectId
        self.managedIoNodes = .init()
        self.sourceRoutes = .init()
    }
    
    public override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        
        // Starts this IO router. The router now listens for Advertise and
        // Deadvertise events of IO nodes and issues an initial Discover event
        // for IO nodes.
        //
        // Additionally, it makes its IO context available by advertising and
        // for discovery (by core type or object Id) and listens for
        // Update-Complete events on the context, triggering
        // `onIoContextChanged`.
        //
        // After starting the `onStarted` method is invoked.
        self.observeAdvertisedIoNode()
        self.observeDeadvertisedIoNodes()
        self.discoverIoNodes()
        self.observeDiscoverIoContext()
        self.observeUpdateIoContext()
        
        self.onStarted()
        try? self.onIoContextChanged()
    }
    
    public override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        
        // Stops this IO router. Subclasses should disassociate all current
        // associations in the `onStopped` method.
        self.onStopped()
        
        // Clear both dictionaries.
        self.managedIoNodes = .init()
        self.sourceRoutes = .init()
    }
    
    // MARK: - Methods requiring overriding.
    
    /// Called by the IO router base implementation when an IO node is being
    /// managed.
    ///
    /// To be implemented by concrete subclasses.
    internal func onIoNodeManaged(node: IoNode) {
        fatalError("This method must be overridden.")
    }
    
    /// Called by the IO router base implementation when currently managed IO
    /// nodes are going to be unmanaged.
    ///
    /// To be implemented by concrete subclasses.
    internal func onIoNodesUnmanaged(nodes: [IoNode]) {
        fatalError("This method must be overridden.")
    }
    
    // MARK: - Class methods.
    
    /// Finds a managed IO node that matches the given predicate.
    ///
    /// - Returns: nil if no such IO node exists.
    ///
    /// - Parameter predicate: a function returning true if an IO node matches; false
    /// otherwise.
    func findManagedIoNode(predicate: (_ node: IoNode) -> Bool) -> IoNode? {
        var foundNode: IoNode? = nil
        self.managedIoNodes.forEach { _, value in
            let node = value as! IoNode
            if foundNode == nil && predicate(node) {
                foundNode = node
            }
        }
        return foundNode
    }
    
    /// Called by this IO router when its IO context has changed.
    ///
    /// The base method just advertises the changed IO context object.
    ///
    /// Overwrite this method in your router subclass to reevaluate all
    /// associations between IO sources and IO actors currently held by this
    /// router.
    ///
    /// Ensure to invoke `super.onIoContextChanged` so that the changed IO
    /// context is (re)advertised.
    internal func onIoContextChanged() throws {
        self.communicationManager.publishAdvertise(try AdvertiseEvent.with(object: self.ioContext))
    }
    
    /// Associates the given IO source and actor by publishing an Associate
    /// event.
    ///
    /// - Parameters:
    ///     - source: an IO source object.
    ///     - actor: an IO actor object
    ///     - updateRate: the recommended update rate (in milliseconds)
    internal func associate(source: IoSource, actor: IoActor, updateRate: Int) throws {
        // Ensure that an IO source publishes IO values to all associated IO
        // actors on a unique and common route.
        var route = self.sourceRoutes[source.objectId.string] as? (String, Bool)
        if route == nil {
            if let sourceExternalRoute = source.externalRoute {
                route = (sourceExternalRoute, true)
            } else {
                route = (self.communicationManager.createIoRoute(ioSource: source), false)
            }
            self.sourceRoutes[source.objectId.string] = route!
        }
        try self.communicationManager.publishAssociate(event: AssociateEvent.with(ioContextName: self.ioContext.name,
                                                                                  ioSourceId: source.objectId,
                                                                                  ioActorId: actor.objectId,
                                                                                  associatingRoute: route!.0,
                                                                                  isExternalRoute: route!.1,
                                                                                  updateRate: updateRate))
    }
    
    /// Disassociates the given IO source and actor by publishing an Associate
    /// event with an undefined route.
    ///
    /// - Parameters:
    ///     - source: an IO source object
    ///     - actor: an IO actor object
    internal func disassociate(source: IoSource, actor: IoActor) throws {
        try self.communicationManager.publishAssociate(event: AssociateEvent.with(ioContextName: self.ioContext.name,
                                                                                  ioSourceId: source.objectId,
                                                                                  ioActorId: actor.objectId,
                                                                                  associatingRoute: nil))
    }
    
    /// Checks whether the value types and value data formats of the given IO
    /// source and actor match.
    ///
    /// This is a precondition for associating IO source and actor.
    ///
    /// The base implementation returns true, if the given source value type is
    /// identical to the given actor value type **and** both value data formats
    /// (either raw binary or JSON) match; otherwise false.
    ///
    /// Override this base implementation if you need a custom value type
    /// compatibility check in your router.
    ///
    /// - Parameters:
    ///     - source an IO source object
    ///     - actor an IO actor object
    internal func areValueTypesCompatible(source: IoSource, actor: IoActor) -> Bool {
        return source.valueType == actor.valueType && source.useRawIoValues == actor.useRawIoValues
    }
    
    /// Override this method to perform side effects when this router is
    /// started.
    ///
    /// This method does nothing.
    internal func onStarted() { }
    
    /// Override this method to perform side effects when this router is
    /// stopped.
    ///
    /// This method does nothing.
    ///
    /// Subclasses should disassociate all current associations in this method.
    internal func onStopped() { }
    
    private func observeAdvertisedIoNode() {
        _ = self.communicationManager.observeAdvertise(withCoreType: .IoNode)
                .filter { event -> Bool in
                    return event.data.object.name == self.ioContext.name
                }.subscribe(onNext: { event in
                    self.ioNodeAdvertised(node: event.data.object as! IoNode)
                })
    }
    
    private func observeDeadvertisedIoNodes() {
        _ = self.communicationManager
            .observeDeadvertise()
            .subscribe(onNext: { event in self.ioNodesDeadvertised(objectIds: event.data.objectIds) })
    }
    
    private func ioNodeAdvertised(node: IoNode) {
        let isDeadvertise = node.ioSources.count == 0 && node.ioActors.count == 0
        
        self.ioNodesDeadvertised(objectIds: [node.objectId], readvertisedNode: isDeadvertise ? nil : node)
        if isDeadvertise {
            return
        }
        self.managedIoNodes[node.objectId.string] = node
        self.onIoNodeManaged(node: node)
    }
    
    private func ioNodesDeadvertised(objectIds: [CoatyUUID], readvertisedNode: IoNode? = nil) {
        var deregisteredNodes: [IoNode] = []
        
        objectIds.forEach { id in
            if let deregisteredNode = self.managedIoNodes[id.string] as? IoNode {
                self.managedIoNodes.removeObject(forKey: id)
                deregisteredNode.ioSources.forEach { point in
                    // Ensure source topics are preserved for IO sources that
                    // also exist in a rediscovered or readvertised IO node.
                    if readvertisedNode == nil || (readvertisedNode?.ioSources.first(where: { p -> Bool in p.objectId == point.objectId }) == nil) {
                        self.sourceRoutes.removeObject(forKey: point.objectId.string)
                    }
                }
                if readvertisedNode == nil {
                    deregisteredNodes.append(deregisteredNode)
                }
            }
        }
        
        if deregisteredNodes.count > 0 {
            self.onIoNodesUnmanaged(nodes: deregisteredNodes)
        }
    }
    
    private func discoverIoNodes() {
        _ = self.communicationManager.publishDiscover(DiscoverEvent.with(coreTypes: [.IoNode]))
            .filter { event -> Bool in
                event.data.object != nil && event.data.object!.name == self.ioContext.name
            }.subscribe(onNext: { event in
                self.ioNodeAdvertised(node: event.data.object as! IoNode)
            })
    }
    
    private func observeDiscoverIoContext() {
        _ = self.communicationManager
            .observeDiscover()
            .filter { event -> Bool in
                return (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(self.ioContext.coreType)) ||
                    (event.data.isDiscoveringTypes() && event.data.isObjectTypeCompatible(objectType: self.ioContext.objectType)) ||
                    (event.data.isDiscoveringObjectId() && event.data.objectId! == self.ioContext.objectId)
        }.subscribe(onNext: { event in
            event.resolve(resolveEvent: ResolveEvent.with(object: self.ioContext))
        })
    }
    
    private func observeUpdateIoContext() {
        _ = self.communicationManager.observeUpdate(withCoreType: self.ioContext.coreType)
            .filter { update -> Bool in
                update.data.object.objectId == self.ioContext.objectId
            }.subscribe(onNext: { update in
                self.ioContext = (update.data.object as! IoContext)
                self.ioContext.parentObjectId = self.container.identity?.objectId
                try? self.onIoContextChanged()
                update.complete(completeEvent: CompleteEvent.with(object: self.ioContext))
            })
    }
}
