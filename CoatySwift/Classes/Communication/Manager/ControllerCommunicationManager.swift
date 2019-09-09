// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ControllerCommunicationManager.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

public class ControllerCommunicationManager<Family: ObjectFamily> {
    
    private var controllerIdentity: Component
    private var cm: CommunicationManager<Family>
    public var identity: Component {
        return self.cm.identity
    }
    
    init(identity: Component, communicationManager: CommunicationManager<Family>) {
        self.controllerIdentity = identity
        self.cm = communicationManager
    }
    
    // MARK: - Observe events.
    
    /// Observes raw MQTT communication on a given subscription topic (=topicFilter).
    /// - Parameters:
    ///   - topicFilter: the subscription topic
    /// - Returns: a hot observable emitting any incoming messages as tuples containing the actual topic
    /// and the payload as a UInt8 Array.
    public func observeRaw(topicFilter: String) -> Observable<(String, [UInt8])>{
        return cm.observeRaw(eventTarget: self.controllerIdentity, topicFilter: topicFilter)
    }

    /// Observes advertises with a particular coreType.
    ///
    /// - Parameters:
    ///     - withCoreType: coreType core type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted coreType.
    public func observeAdvertise<T: AdvertiseEvent<Family>>(withCoreType coreType: CoreType) throws -> Observable<T> {
        
        return try cm.observeAdvertiseWithCoreType(eventTarget:self.controllerIdentity, coreType: coreType)
        
    }
    
    /// Observes advertises with a particular objectType.
    /// - Parameters:
    ///     - withObjectType: objectType object type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted objectType.
    public func observeAdvertise<T: AdvertiseEvent<Family>>(withObjectType objectType: String) throws -> Observable<T> {
        return try cm.observeAdvertiseWithObjectType(eventTarget: self.controllerIdentity, objectType: objectType)
    }
    
    
    /// Observe Channel events for the given target and the given
    /// channel identifier emitted by the hot observable returned.
    ///
    /// - TODO: The channel identifier must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - TODO: Channel events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    //// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///   - channelId: a channel identifier
    /// - Returns: a hot observable emitting incoming Channel events.
    public func observeChannel<T: ChannelEvent<Family>>(channelId: String) throws -> Observable<T> {
        return try cm.observeChannel(eventTarget: self.controllerIdentity, channelId: channelId)
    }
    
    /// Observe Deadvertise events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Deadvertise events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Returns:  a hot observable emitting incoming Deadvertise events
    public func observeDeadvertise() throws -> Observable<DeadvertiseEvent> {
        return try cm.observeDeadvertise(eventTarget: self.controllerIdentity)
      }
    
    /// Observe Update events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Update events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Returns: a hot observable emitting incoming Update events.
    public func observeUpdate<T: UpdateEvent<Family>>() throws -> Observable<T> {
        return try cm.observeUpdate(eventTarget: self.controllerIdentity)
    }
    
    /// Observe Discover events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Discover events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Returns: a hot observable emitting incoming Discover events.
    public func observeDiscover<T: DiscoverEvent<Family>>() throws -> Observable<T> {
        return try cm.observeDiscover(eventTarget: self.controllerIdentity)
    }
    
    /// - TODO: Missing documentation!
    public func observeCall<T: CallEvent<Family>>(operationId: String) throws -> Observable<T> {
        return try cm.observeCall(eventTarget: self.controllerIdentity, operationId: operationId)
    }
    
    /// Observe communication state changes by the hot observable returned.
    /// When subscribed the observable immediately emits the current
    /// communication state.
    public func observeCommunicationState() -> Observable<CommunicationState> {
        return cm.observeCommunicationState()
    }
    
    // MARK: - Publish events.
    
    // MARK: - One way events.
    
    /// Publish a value on the given topic. Used to interoperate
    /// with external MQTT clients that subscribe on the given topic.
    ///
    /// - TODO: The topic is an MQTT publication topic, i.e. a non-empty string
    /// that must not contain the following characters: `NULL (U+0000)`,
    /// `# (U+0023)`, `+ (U+002B)`.
    ///
    /// - Parameters:
    ///   - topic: the topic on which to publish the given payload
    ///   - value: a payload string or Uint8Array (Buffer in Node.js) to be published on the given topic
    public func publishRaw(topic: String, value: String) {
        cm.publish(topic: topic, message: value)
    }
    
    /// Publishes a given advertise event.
    ///
    /// - Parameters:
    ///     - event: The event that should be advertised.
    public func publishAdvertise<Family: ObjectFamily,T: AdvertiseEvent<Family>>(_ event: T) throws {
        try cm.publishAdvertise(advertiseEvent: event, eventTarget: self.controllerIdentity)
    }
    
    /// Advertises the identity of a CommunicationManager.
    public func advertiseIdentityOrDevice() throws {
        try cm.advertiseIdentityOrDevice(eventTarget: self.controllerIdentity)
    }
    
    /// Notify subscribers that an advertised object has been deadvertised.
    ///
    /// - Parameter event: the Deadvertise event to be published
    public func publishDeadvertise(_ event: DeadvertiseEvent) throws {
        try cm.publishDeadvertise(deadvertiseEvent: event)
    }
    
    // MARK: - Two way events.
    
    /// Publish updates and receive Complete events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Update event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishUpdate<V: CompleteEvent<Family>>(_ event: UpdateEvent<Family>) throws -> Observable<V> {
        return try cm.publishUpdate(event: event)
    }
    
    /// Publish a channel event.
    ///
    /// - Parameter event: the Channel event to be published
    public func publishChannel(_ event: ChannelEvent<Family>) throws {
        return try cm.publishChannel(event: event)
    }
    
    /// Find discoverable objects and receive Resolve events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Discover event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishDiscover<V: ResolveEvent<Family>>(_ event: DiscoverEvent<Family>) throws -> Observable<V> {
       return try cm.publishDiscover(event: event)
    }
    
    /// Find queryable objects and receive Retrieve events for them
    /// emitted by the hot observable returned.
    ///
    /// - TODO: Note that the Query event is lazily published when the
    /// first observer subscribes to the observable.
    ///
    /// Since the observable never emits a completed or error event,
    /// a subscriber should unsubscribe when the observable is no longer needed
    /// to release system resources and to avoid memory leaks. After all initial
    /// subscribers have unsubscribed no more response events will be emitted
    /// on the observable and an error will be thrown on resubscription.
    ///
    /// - Parameters:
    ///     - event: the Query event to be published
    /// - Returns: a hot observable on which associated Retrieve events are emitted.
    public func publishQuery<V: RetrieveEvent<Family>>(_ event: QueryEvent<Family>) throws -> Observable<V> {
        return try cm.publishQuery(event: event)
    }
    
    /// Publish a Call event to perform a remote operation and receive results
    /// emitted by the hot observable returned.
    ///
    /// Note that the Call event is lazily published when the
    /// first observer subscribes to the observable.
    ///
    /// Since the observable never emits a completed or error event,
    /// a subscriber should unsubscribe when the observable is no longer needed
    /// to release system resources and to avoid memory leaks. After all initial
    /// subscribers have unsubscribed no more response events will be emitted
    /// on the observable and an error will be thrown on resubscription.
    /// - TODO: AssociatedUserId currently not correctly implemented.
    ///
    /// - Parameter event: the Call event to be published.
    /// - Returns: a hot observable of associated Return events.
    public func publishCall<V: ReturnEvent<Family>>(_ event: CallEvent<Family>) throws -> Observable<V> {
        return try cm.publishCall(event: event)
    }
    
}
