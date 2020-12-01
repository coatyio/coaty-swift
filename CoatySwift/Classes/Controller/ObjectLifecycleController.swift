//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ObjectLifecycleController.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// Represents changes in the objects kept for lifecycle management by the
/// `ObjectLifecycleController`. Changes are provided by the properties `added`,
/// `removed`, or `changed` where exactly one is set and the others are not
/// defined.
public struct ObjectLifecycleInfo {
    /// Array of objects which have been newly advertised or discovered
    /// (optional). The value is not defined if no additions occured.
    public var added: [CoatyObject]?
    
    /// Array of objects which have been readvertised or rediscovered with
    /// different object properties (optional). The value is not defined if no
    /// changes occured.
    public var changed: [CoatyObject]?
    
    /// Array of objects which have been deadvertised (optional). The value is
    /// not defined if no removals occured.
    public var removed: [CoatyObject]?
}

/// Keeps track of agents or specific Coaty objects in a Coaty network by
/// monitoring agent identities or custom object types.
///
/// This controller observes advertisements and deadvertisements of such objects
/// and discovers them. Changes are emitted on corresponding observables that
/// applications can subscribe to.
///
/// You can use this controller either standalone by adding it to the container
/// components or extend your custom controller class from this controller class.
///
/// If you want to keep track of custom object types (not agent identities), you
/// have to implement the remote side of the distributed object lifecycle
/// management explicitely, i.e. advertise/readvertise/deadvertise your custom
/// objects and observe/resolve corresponding Discover events. To facilitate
/// this, this controller provides convenience methods:
/// `advertiseDiscoverableObject`, `readvertiseDiscoverableObject`, and
/// `deadvertiseDiscoverableObject`.
///
/// Usually, a custom object should have the object ID of its agent identity,
/// i.e. `Container.identity`, set as its `parentObjectId` in order to be
/// automatically deadvertised when the agent terminates abnormally. You can
/// automate this by passing `true` to the optional parameter
/// `shouldSetParentObjectId` of method `advertiseDiscoverableObject` (`true` is
/// also the default parameter value).
open class ObjectLifecycleController: Controller {

    // - MARK: Public methods
    
    /// Observes advertisements, deadvertisments and initial discoveries of
    /// objects of the given core type. To track agent identity objects, specify
    /// core type `Identity`.
    ///
    /// Specify an optional filter predicate to be applied to trackable objects.
    /// If the predicate function returns `true`, the object is being tracked;
    /// otherwise the object is not tracked. If no predicate is specified, all
    /// objects corresponding to the given core type are tracked.
    ///
    /// - Remark: Subscriptions to the returned observable are automatically
    /// unsubscribed when the communication manager is stopped.
    ///
    /// - Parameters:
    ///     - coreType: the core type of objects to be tracked
    ///     - objectFilter: a predicate for filtering objects to be tracked
    ///     (optional)
    ///
    /// - Returns: an observable emitting changes concerning tracked objects of the
    /// given core type
    public func observeObjectLifecycleInfoByCoreType(coreType: CoreType,
                                                     objectFilter: ((CoatyObject) -> Bool)?) -> Observable<ObjectLifecycleInfo>{
        return self._observeObjectLifecycleInfo(coreType: coreType, objectType: nil, objectFilter: objectFilter)
    }
    
    /// Observes advertisements, deadvertisments and initial discoveries of
    /// objects of the given object type.
    ///
    /// Specify an optional filter predicate to be applied to trackable objects.
    /// If the predicate function returns `true`, the object is being tracked;
    /// otherwise the object is not tracked. If no predicate is specified, all
    /// objects corresponding to the given core type are tracked.
    ///
    /// - Remark: Subscriptions to the returned observable are automatically
    /// unsubscribed when the communication manager is stopped.
    ///
    /// - Parameters:
    ///     - objectType: the object type of objects to be tracked
    ///     - objectFilter: a predicate for filtering objects to be tracked
    ///     (optional)
    ///
    /// - Returns: an observable emitting changes concerning tracked objects of the
    /// given object type
    public func observeObjectLifecycleInfoByObjectType(with objectType: String,
                                                       objectFilter: ((CoatyObject) -> Bool)?) -> Observable<ObjectLifecycleInfo> {
        return self._observeObjectLifecycleInfo(coreType: nil, objectType: objectType, objectFilter: objectFilter)
    }
    
    /// Advertises the given Coaty object and makes it discoverable either by its
    /// `objectType` or `objectId`.
    ///
    /// The optional `shouldSetParentObjectId` parameter determines whether the
    /// parent object ID of the given object should be set to the agent
    /// identity's object ID (default is `true`). This is required if you want to
    /// observe the object's lifecycle info by method
    /// `observeObjectLifecycleInfoByObjectType` and to get notified when the
    /// advertising agent terminates abnormally.
    ///
    /// The returned subscription should be unsubscribed when the object is
    /// deadvertised explicitely in your application code (see method
    /// `deadvertiseDiscoverableObject`). It will be automatically unsubscribed
    /// when the communication manager is stopped.
    ///
    /// - Parameters:
    ///     - object: a CoatyObject that is advertised and discoverable
    ///     - shouldSetParentObjectId: determines whether the parent object ID of
    ///     the given object should be set to the agent identity's object ID (default
    ///     is `true`)
    ///
    /// - Returns: the subscription (of type Disposable) on a DiscoverEvent observable
    /// that should be disposed (unsubscribed) if no longer needed
    public func advertiseDiscoverableObject(object: CoatyObject,
                                            shouldSetParentObjectId: Bool = true) -> Disposable {
        if shouldSetParentObjectId {
            object.parentObjectId = self.container.identity?.objectId
        }
        try? self.communicationManager.publishAdvertise(AdvertiseEvent.with(object: object))
        return self.communicationManager
            .observeDiscover()
            .filter({ event in
                (event.data.isDiscoveringTypes() &&
                    event.data.isObjectTypeCompatible(objectType: object.objectType)) ||
                (event.data.isDiscoveringObjectId() &&
                    event.data.objectId == object.objectId)
            })
            .subscribe(onNext: { event in
                event.resolve(resolveEvent: ResolveEvent.with(object: object))
            })
    }
    
    /// Readvertises the given Coaty object, usually after some properties have
    /// changed. The object reference should have been advertised before once
    /// using the method `advertiseDiscoverableObject`.
    ///
    /// - Parameter object: a CoatyObject that should be advertised again after
    /// properties have changed
    public func readvertiseDiscoverableObject(object: CoatyObject) {
        try? self.communicationManager.publishAdvertise(AdvertiseEvent.with(object: object))
    }
    
    /// Deadvertises the given Coaty object and unsubscribes the given
    /// subscription resulting from a corresponding invocation of method
    /// `advertiseDiscoverableObject`.
    ///
    /// Note that if you want to keep a Coaty object for the whole lifetime of
    /// its agent you don't necessarily need to invoke this method explicitely.
    /// Deadvertise events are published automatically by or on behalf of an
    /// agent whenever its communication manager is stopped or when the agent
    /// terminates abnormally.
    ///
    /// - Parameters:
    ///     - object: a CoatyObject to be deadvertised
    ///     - discoverableSubscription: subscription on DiscoverEvent to be
    ///     unsubscribed
    public func deadvertiseDiscoverableObject(object: CoatyObject,
                                              discoverableSubscription: Disposable) {
        // Stop observing Discover events that have been set up in
        // advertiseDiscoverableObject.
        discoverableSubscription.dispose()
        self.communicationManager.publishDeadvertise(DeadvertiseEvent.with(objectIds: [object.objectId]))
    }
    
    // - MARK: Private methods
    
    private func _observeObjectLifecycleInfo(coreType coreTypeParameter: CoreType?,
                                             objectType: String?,
                                             objectFilter: ((CoatyObject) -> Bool)?) -> Observable<ObjectLifecycleInfo> {
        // Used because Swift does not allow function parameters mutation
        // and this parameter is not used again in the calling function
        var coreType: CoreType?
        
        if coreTypeParameter == nil && objectType == nil {
            coreType = CoreType.Identity
        }
        
        if coreType != nil && objectType != nil {
            fatalError("Must not specify both coreType and objectType")
        }
        
        var registry: [String: CoatyObject] = [:]
        
        let discovered = self.communicationManager
            // Note that the Discover event will also resolve the identity of this agent itself!
            .publishDiscover(coreType != nil ?
                                DiscoverEvent.with(coreTypes: [coreType!]) :
                                DiscoverEvent.with(objectTypes: [objectType!]))
        
        let advertised = coreType != nil ?
            self.communicationManager.observeAdvertise(withCoreType: coreType!) :
            try! self.communicationManager.observeAdvertise(withObjectType: objectType!)
        
        let deadvertised = self.communicationManager.observeDeadvertise()
        
        
        let discoveredObservable = discovered
            .map({ event in event.data.object })
            .filter({ obj in
                return obj != nil && (objectFilter != nil ? objectFilter!(obj!) : true)
            })
            .map({ obj in self._addToRegistry(with: &registry, with: obj!) })
            .filter({ info in info != nil })
            .map({ info in info! })
        
        let advertisedObservable = advertised
            .map({ event in event.data.object })
            .filter({ obj in
                return objectFilter != nil ? objectFilter!(obj) : true
            })
            .map({ obj in self._addToRegistry(with: &registry, with: obj) })
            .filter({ info in info != nil })
            .map({ info in info! })
        
        let deadvertisedObservable = deadvertised
            .map({ event in self._removeFromRegistry(with: &registry, with: event.data.objectIds) })
            .filter({ info in info != nil })
            .map({ info in info! })
        
        // All subscribers share the same source so that side effecting
        // operators will be executed only once per emission.
        return Observable.of(discoveredObservable,
                             advertisedObservable,
                             deadvertisedObservable)
            .merge()
    }
    
    private func _addToRegistry(with registry: inout [String: CoatyObject],
                                with object: CoatyObject) -> ObjectLifecycleInfo? {
        guard let robj = registry[object.objectId.string] else {
            registry[object.objectId.string] = object
            return ObjectLifecycleInfo(added: [object])
        }
        
        registry[object.objectId.string] = object
        
        if (robj === object) {
            return nil
        } else {
            return ObjectLifecycleInfo(changed: [object])
        }
    }
    
    private func _removeFromRegistry(with registry: inout [String:CoatyObject],
                                     with objectIds: [CoatyUUID]) -> ObjectLifecycleInfo? {
        var removed: [CoatyObject] = []
        
        objectIds.forEach{ objectId in
            self._updateRegistryOnRemove(with: &registry, objectId: objectId, removed: &removed)
        }
        
        if removed.isEmpty {
            return nil
        } else {
            return ObjectLifecycleInfo(removed: removed)
        }
    }
    
    private func _updateRegistryOnRemove(with registry: inout [String: CoatyObject], objectId: CoatyUUID, removed: inout [CoatyObject]) {
        let obj = registry[objectId.string]
        
        // Cleanup: check if objects are registered that have a parent object
        // referencing the object to be removed. These objects must be also
        // unregistered.
        registry.forEach { _, o in
            if o.parentObjectId == objectId {
                registry.removeValue(forKey: o.objectId.string)
                removed.append(o)
            }
        }
        
        if let obj = obj {
            // Unregister the target object to be removed.
            registry.removeValue(forKey: objectId.string)
            removed.append(obj)
        }
    }
}
