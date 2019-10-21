//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationManager+Publish.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {
    
    // MARK: - One way events.
    
    /// Publish a value on the given topic. Used to interoperate
    /// with external MQTT clients that subscribe on the given topic.
    ///
    /// The topic is an MQTT publication topic,
    /// i.e. a non-empty string that must not contain the following
    /// characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`.
    ///
    /// - Parameters:
    ///   - topic: the topic on which to publish the given payload
    ///   - value: a payload string or Uint8Array (Buffer in Node.js) to be published on the given topic
    public func publishRaw(topic: String, value: String) throws {
        if topic.count == 0 ||
           topic.contains("\u{0000}") ||
           topic.contains("#") ||
           topic.contains("+") {
            throw CoatySwiftError.InvalidArgument("Could not publish raw: invalid topic name.")
        }

        self.publish(topic: topic, message: value)
    }
    
    /// Publishes a given advertise event.
    ///
    /// - Parameters:
    ///     - advertiseEvent: The event that should be advertised.
    public func publishAdvertise<Family: ObjectFamily,T: AdvertiseEvent<Family>>(advertiseEvent: T) throws {
        
        let topicForObjectType = try CommunicationTopic
            .createTopicStringByLevelsForPublish( eventType: .Advertise,
                                                  eventTypeFilter: advertiseEvent.data.object.objectType,
                                                  associatedUserId: associatedUser?.objectId.string,
                                                  sourceObject: advertiseEvent.source!,
                                                  messageToken: CoatyUUID().string)
        
        let topicForCoreType = try CommunicationTopic
            .createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                 eventTypeFilter: advertiseEvent.data.object.coreType.rawValue,
                                                 associatedUserId: associatedUser?.objectId.string,
                                                 sourceObject: advertiseEvent.source!,
                                                 messageToken: CoatyUUID().string)
        
        // Save advertises for Components or Devices.
        if advertiseEvent.data.object.coreType == .Component ||
            advertiseEvent.data.object.coreType == .Device {
            
            // Add if not existing already in deadvertiseIds.
            if !deadvertiseIds.contains(advertiseEvent.data.object.objectId) {
                deadvertiseIds.append(advertiseEvent.data.object.objectId)
            }
        }
        
        // Publish the advertise for core AND object type.
        //
        // TODO: Optimization: Publish event with object type filter to satisfy object type observers
        // unless the advertised object is a core object with a core object type.
        // In this (exotic) case, core object type observers subscribe on the core type
        // followed by a local filter operation to filter out unwanted objects
        // (see `observeAdvertise`).
        publish(topic: topicForCoreType, message: advertiseEvent.json)
        publish(topic: topicForObjectType, message: advertiseEvent.json)
    }
    
    /// Notify subscribers that an advertised object has been deadvertised.
    ///
    /// - Parameter deadvertiseEvent: the Deadvertise event to be published
    public func publishDeadvertise(deadvertiseEvent: DeadvertiseEvent<Family>) throws {
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Deadvertise,
                                                                  associatedUserId: associatedUser?.objectId.string,
                                                                  sourceObject: deadvertiseEvent.source!,
                                                                  messageToken: CoatyUUID().string)
        
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
        let updateMessageToken = CoatyUUID().string
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Update,
                                                                  associatedUserId: associatedUser?.objectId.string,
                                                                  sourceObject: event.source!,
                                                                  messageToken: updateMessageToken)
  
        let completeTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Complete,
                                                                                         messageToken: updateMessageToken)
    
        var observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != event.sourceId
            })
            .filter(isComplete)
            .filter { rawMessageWithTopic -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == updateMessageToken
            }
            .compactMap { message -> V? in
                let (topic, payload) = message
                
                guard let completeEvent: V = PayloadCoder.decode(payload)! else {
                    LogManager.log.warning("could not parse completeEvent")
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: completeEvent.data) else {
                    return nil
                }

                completeEvent.sourceId = topic.sourceObjectId;
                completeEvent.userId = topic.associatedUserId;
                
                return completeEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: completeTopic)

        subscribe(topic: completeTopic)
        publish(topic: topic, message: event.json)
        
        return observable
    }

    /// Publish a channel event.
    ///
    /// - Parameter event: the Channel event to be published
    public func publishChannel(event: ChannelEvent<Family>) throws {
        guard let channelId = event.channelId else {
            throw CoatySwiftError.InvalidArgument("Could not publish because ChannelID missing.")
        }
        
        let publishTopic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Channel,
                                                                         eventTypeFilter: channelId,
                                                                         associatedUserId: associatedUser?.objectId.string,
                                                                         sourceObject: event.source!,
                                                                         messageToken: CoatyUUID().string)
        
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
        let discoverMessageToken = CoatyUUID().string
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Discover,
                                                                  associatedUserId: associatedUser?.objectId.string,
                                                                  sourceObject: event.source!,
                                                                  messageToken: discoverMessageToken)
        
        let resolveTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Resolve,
                                                                                        messageToken: discoverMessageToken)
        
        var observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != event.sourceId
            })
            .filter(isResolve)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == discoverMessageToken
            })
            .compactMap{ message -> V? in
                let (topic, payload) = message
                
                guard let resolveEvent: V = PayloadCoder.decode(payload)! else {
                    LogManager.log.warning("could not parse resolveEvent")
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: resolveEvent.data) else {
                    return nil
                }

                resolveEvent.sourceId = topic.sourceObjectId;
                resolveEvent.userId = topic.associatedUserId;
                
                return resolveEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: resolveTopic)

        subscribe(topic: resolveTopic)
        publish(topic: topic, message: event.json)
 
        return observable
    }
    
    /// Find queryable objects and receive Retrieve events for them
    /// emitted by the hot observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
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
        let queryMessageToken = CoatyUUID().string
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Query,
                                                                  associatedUserId: associatedUser?.objectId.string,
                                                                  sourceObject: event.source!,
                                                                  messageToken: queryMessageToken)
        
        let retrieveTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Retrieve,
                                                                                         messageToken: queryMessageToken)
                
        var observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != event.sourceId
            })
            .filter(isRetrieve)
            .filter { rawMessageWithTopic -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == queryMessageToken
            }
            .compactMap { (message) -> V? in
                let (topic, payload) = message
                
                guard let retrieveEvent: V = PayloadCoder.decode(payload)! else {
                    LogManager.log.warning("could not parse retrieveEvent")
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: retrieveEvent.data) else {
                    return nil
                }

                retrieveEvent.sourceId = topic.sourceObjectId;
                retrieveEvent.userId = topic.associatedUserId;
                
                return retrieveEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: retrieveTopic)

        subscribe(topic: retrieveTopic)
        publish(topic: topic, message: event.json)

        return observable
    }
    
    /// Publishes a complete in response to an update event. Not accessible by
    /// the application programmer, it is just a convenience method for reacting
    /// upon an update.
    ///
    /// - Parameters:
    ///   - identity: the identity of the responder.
    ///   - event: the complete event that should be sent out.
    ///   - messageToken: the message token associated with the update-complete
    ///     request.
    internal func publishComplete(identity: Component,
                                  event: CompleteEvent<Family>,
                                  messageToken: String) throws {
        
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Complete,
                                                              associatedUserId: associatedUser?.objectId.string,
                                                              sourceObject: identity,
                                                              messageToken: messageToken)
        publish(topic: topic, message: event.json)
    }
    
    /// Publishes a resolve in response to a discover event. Not accessible by
    /// the application programmer, it is just a convenience method for reacting
    /// upon a discover.
    ///
    /// - Parameters:
    ///   - identity: the identity of the responder.
    ///   - event: the resolve event that should be sent out.
    ///   - messageToken: the message token associated with the discover-resolve
    ///     request.
    internal func publishResolve(identity: Component,
                                                       event: ResolveEvent<Family>,
                                                       messageToken: String) throws {
        
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Resolve,
                                                                  associatedUserId: associatedUser?.objectId.string,
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
        
        let callMessageToken = CoatyUUID().string
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Call,
                                                                               eventTypeFilter: event.operation,
                                                                               associatedUserId: associatedUser?.objectId.string,
                                                                               sourceObject: event.source!,
                                                                               messageToken: callMessageToken)
        
        let returnTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Return,
                                                                                       messageToken: callMessageToken)
        
        var observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != event.sourceId
            })
            .filter(isReturn)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to message token.
                let (topic, _) = rawMessageWithTopic
                return topic.messageToken == callMessageToken
            })
            .compactMap { (message) -> V? in
                let (topic, payload) = message
                
                guard let returnEvent: V = PayloadCoder.decode(payload)! else {
                    LogManager.log.warning("could not parse returnEvent")
                    return nil
                }

                returnEvent.sourceId = topic.sourceObjectId;
                returnEvent.userId = topic.associatedUserId;
                
                return returnEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: returnTopic)

        subscribe(topic: returnTopic)
        publish(topic: topic, message: event.json)

        return observable
    }
    
    /// Publishes a return in response to a call event. Not accessible by the
    /// application programmer, it is just a convenience method for reacting
    /// upon a call.
    ///
    /// - Parameters:
    ///   - identity: the identity of the responder.
    ///   - event: the return event that should be sent out.
    ///   - messageToken: the message token associated with the call-return
    ///     request.
    internal func publishReturn(identity: Component,
                                event: ReturnEvent<Family>,
                                messageToken: String) throws {
        
        let topic = try CommunicationTopic.createTopicStringByLevelsForPublish(eventType: .Return,
                                                                  associatedUserId: associatedUser?.objectId.string,
                                                                  sourceObject: identity,
                                                                  messageToken: messageToken)
        publish(topic: topic, message: event.json)
    }

}
