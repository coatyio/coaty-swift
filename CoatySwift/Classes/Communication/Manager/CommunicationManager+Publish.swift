//
//  CommunicationManager+Publish.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {

    // MARK: - One way events.
    
    /// Advertises the identity of a CommunicationManager.
    public func advertiseIdentityOrDevice(eventTarget: Component) throws {
        guard let identity = self.identity else {
            log.error("CommunicationManager identity not set.")
            return
        }
        
        let advertiseIdentityEvent = AdvertiseEvent.withObject(eventSource: identity,
                                                               object: identity,
                                                               privateData: nil)
        
        try publishAdvertise(advertiseEvent: advertiseIdentityEvent, eventTarget: identity)
    }
    
    /// Notify subscribers that an advertised object has been deadvertised.
    ///
    /// - Parameter deadvertiseEvent: the Deadvertise event to be published
    public func publishDeadvertise<S: Deadvertise,T: DeadvertiseEvent<S>>(deadvertiseEvent: T) throws {
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Deadvertise,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: deadvertiseEvent.eventUserId
                                                                    ?? EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: deadvertiseEvent.eventSource,
                                                                  messageToken: UUID().uuidString)
        
        self.publish(topic: topic, message: deadvertiseEvent.json)
    }
    
    // MARK: - Two way events.
    
    /// Publish updates and receive Complete events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Update event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishUpdate<V: CompleteEvent<Family>>(event: UpdateEvent<Family>) throws -> Observable<V> {
        let updateMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Update,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: event.eventSource,
                                                                  messageToken: updateMessageToken)
        
        publish(topic: topic, message: event.json)
        
        
        let completeTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Complete,
                                                                            eventTypeFilter: nil,
                                                                            associatedUserId: nil,
                                                                            sourceObject: nil,
                                                                            messageToken: updateMessageToken)
        // FIXME: Only subscribe to topic if not already subscribed...
        subscribe(topic: completeTopic)
        
        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isComplete)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == updateMessageToken
            })
            .map({ (message) -> V in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
        return createSelfCleaningObservable(observable: observable, topic: completeTopic)
    }

    /// Publish a channel event.
    ///
    /// - Parameter event: the Channel event to be published
    public func publishChannel(event: ChannelEvent<Family>) throws {
        guard let channelId = event.channelId else {
            throw CoatySwiftError.InvalidArgument("Could not publish because ChannelID missing.")
        }
        
        let publishTopic = try Topic.createTopicStringByLevelsForPublish(eventType: .Channel,
                                                                         eventTypeFilter: channelId,
                                                                         associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                         sourceObject: event.eventSource,
                                                                         messageToken: UUID.init().uuidString)
        
        publish(topic: publishTopic, message: event.json)
        
    }
    
    /// Find discoverable objects and receive Resolve events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Discover event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishDiscover<V: ResolveEvent<Family>>(event: DiscoverEvent<Family>) throws -> Observable<V> {
        let discoverMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Discover,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: event.eventSource,
                                                                  messageToken: discoverMessageToken)
        publish(topic: topic, message: event.json)
        
        let resolveTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Resolve,
                                                                           eventTypeFilter: nil,
                                                                           associatedUserId: nil,
                                                                           sourceObject: nil,
                                                                           messageToken: discoverMessageToken)
        subscribe(topic: resolveTopic)
        
        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isResolve)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == discoverMessageToken
            })
            .map({ (message) -> V in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                
                return PayloadCoder.decode(payload)!
            })
        
        return createSelfCleaningObservable(observable: observable, topic: resolveTopic)
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
    public func publishQuery<V: RetrieveEvent<Family>>(event: QueryEvent<Family>) throws -> Observable<V> {
        let queryMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Query,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: event.eventSource,
                                                                  messageToken: queryMessageToken)
        
        let retrieveTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Retrieve,
                                                                           eventTypeFilter: nil,
                                                                           associatedUserId: nil,
                                                                           sourceObject: nil,
                                                                           messageToken: queryMessageToken)
        
        // First, subscribe for potential answers, then publish the query.
        subscribe(topic: retrieveTopic)
        publish(topic: topic, message: event.json)
        
        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isRetrieve)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == queryMessageToken
            })
            .map({ (message) -> V in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                
                return PayloadCoder.decode(payload)!
            })
        
        return createSelfCleaningObservable(observable: observable, topic: retrieveTopic)
    }
    
    /// Publishes a complete after an update event. Not accessible by the
    /// application programmer, it is just a convenience method for reacting upon a update.
    ///
    /// - Parameters:
    ///   - identity: the identity of the controller.
    ///   - event: the complete event that should be sent out.
    ///   - messageToken: the message token associated with the update-complete request.
    internal func publishComplete(identity: Component,
                                                  event: CompleteEvent<Family>,
                                                  messageToken: String) throws {
        
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Complete,
                                                              eventTypeFilter: nil,
                                                              associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                              sourceObject: identity,
                                                              messageToken: messageToken)
        publish(topic: topic, message: event.json)
    }
    
    /// Publishes a resolve after a discover event. Not accessible by the
    /// application programmer, it is just a convenience method for reacting upon a discover.
    ///
    /// - Parameters:
    ///   - identity: the identity of the controller.
    ///   - event: the resolve event that should be sent out.
    ///   - messageToken: the message token associated with the discover-resolve request.
    internal func publishResolve(identity: Component,
                                                       event: ResolveEvent<Family>,
                                                       messageToken: String) throws {
        
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Resolve,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: identity,
                                                                  messageToken: messageToken)
        publish(topic: topic, message: event.json)
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
    ///
    /// - Parameter event: the Call event to be published.
    /// - Returns: a hot observable of associated Return events.
    public func publishCall<V: ReturnEvent<Family>>(event: CallEvent<Family>) throws -> Observable<V> {
        
        let publishMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Call,
                                                                  eventTypeFilter: event.operation,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: event.eventSource,
                                                                  messageToken: publishMessageToken)
        
        publish(topic: topic, message: event.json)
        
        
        let returnTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Return,
                                                                            eventTypeFilter: nil,
                                                                            associatedUserId: nil,
                                                                            sourceObject: nil,
                                                                            messageToken: publishMessageToken)
        // FIXME: Only subscribe to topic if not already subscribed...
        subscribe(topic: returnTopic)
        
        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isReturn)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == publishMessageToken
            })
            .map({ (message) -> V in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
        return createSelfCleaningObservable(observable: observable, topic: returnTopic)
    }
    
    /// Publishes a return after a call event. Not accessible by the
    /// application programmer, it is just a convenience method for reacting upon a call.
    ///
    /// - Parameters:
    ///   - identity: the identity of the controller.
    ///   - event: the return event that should be sent out.
    ///   - messageToken: the message token associated with the call-return request.
    internal func publishReturn(identity: Component,
                                                       event: ReturnEvent<Family>,
                                                       messageToken: String) throws {
        
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Return,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: EMPTY_ASSOCIATED_USER_ID,
                                                                  sourceObject: identity,
                                                                  messageToken: messageToken)
        publish(topic: topic, message: event.json)
    }

}
