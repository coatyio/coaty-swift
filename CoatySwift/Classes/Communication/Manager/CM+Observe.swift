//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationManager+Observe.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {
    
    /// Observes raw MQTT communication on a given subscription topic (=topicFilter).
    /// - Parameters:
    ///   - eventTarget: target for which values should be emitted
    ///   - topicFilter: the subscription topic
    /// - Returns: a hot observable emitting any incoming messages as tuples containing the actual topic
    /// and the payload as a UInt8 Array.
    public func observeRaw(eventTarget: CoatyObject, topicFilter: String) -> Observable<(String, [UInt8])>{
        self.subscribe(topic: topicFilter)
        
        return client.rawMQTTMessages.filter { (topic, payload) -> Bool in
            self.isMQTTTopicMatch(topic: topic, topicFilter: topicFilter)
        }
    }
    
    /// This method should not be called directly, use observeAdvertiseWithCoreType method
    /// or observeAdvertiseWithObjectType method instead.
    ///
    /// - Parameters:
    ///     - topic: topic string in coaty format.
    ///     - eventTarget: Usually, your identity.
    ///     - coreType: observed coreType.
    ///     - objectType: observed objectType.
    private func observeAdvertise<Family: ObjectFamily, T: AdvertiseEvent<Family>>(topic: String,
                                                                        eventTarget: Component,
                                                                        coreType: CoreType?,
                                                                        objectType: String?) throws -> Observable<T> {
        
        if coreType != nil && objectType != nil {
            throw CoatySwiftError.InvalidArgument(
                "Either coreType or objectType must be specified, but not both"
            )
        }
        
        if coreType == nil && objectType == nil {
            throw CoatySwiftError.InvalidArgument("Either coreType or objectType must be specified")
        }
        
        self.subscribe(topic: topic)
        
        let observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter(isAdvertise)
            .filter { (rawMessageWithTopic) -> Bool in
                
                // Filter messages according to coreType or objectType.
                let (topic, _) = rawMessageWithTopic
                if (objectType != nil) {
                    return objectType == topic.objectType
                }
                
                if (coreType != nil) {
                    return coreType == topic.coreType
                }
                
                return false
            }
            .compactMap { (message) -> T? in
                let (_, payload) = message
                
                guard let advertiseEvent: T = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse advertiseEvent")
                    return nil
                }
                
                return advertiseEvent
            }
        
        return createSelfCleaningObservable(observable: observable, topic: topic)
    }
    
    /// Observes advertises with a particular coreType.
    ///
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - coreType: coreType core type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted coreType.
    public func observeAdvertiseWithCoreType<T: AdvertiseEvent<Family>>(eventTarget: Component,
                              coreType: CoreType) throws -> Observable<T> {
        let topic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                    eventTypeFilter: coreType.rawValue)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                                             eventTarget: eventTarget,
                                                             coreType: coreType,
                                                             objectType: nil)
        
        return createSelfCleaningObservable(observable: observable, topic: topic)
    }
    
    /// Observes advertises with a particular objectType.
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - objectType: objectType object type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted objectType.
    public func observeAdvertiseWithObjectType<T: AdvertiseEvent<Family>>(eventTarget: Component,
                              objectType: String) throws -> Observable<T> {
        let topic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: objectType)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                              eventTarget: eventTarget,
                                              coreType: nil,
                                              objectType: objectType)
        
        return createSelfCleaningObservable(observable: observable, topic: topic)
    }
    
    
    /// Observe Channel events for the given target and the given
    /// channel identifier emitted by the hot observable returned.
    ///
    /// - MISSING: Check that the channel identifier must be a non-empty
    /// string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///   - eventTarget: target for which Channel events should be emitted
    ///   - channelId: a channel identifier
    /// - Returns: a hot observable emitting incoming Channel events.
    public func observeChannel<T: ChannelEvent<Family>>(eventTarget: Component,
                                                        channelId: String) throws -> Observable<T> {
        
        if !CommunicationTopic.isValidEventTypeFilter(filter: channelId) {
            throw CoatySwiftError.InvalidArgument("\(channelId) is not a valid channel Id.")
        }
        
        // TODO: Unsure about associatedUserId parameters. Is it really assigneeUserId?
        let channelTopic = try CommunicationTopic.createTopicStringByLevelsForChannel(channelId: channelId,
                                                                         associatedUserId: eventTarget
                                                                            .assigneeUserId?.string,
                                                                         sourceObject: nil,
                                                                         messageToken: nil)
        self.subscribe(topic: channelTopic)

        let observable =  client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter(isChannel)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to channelId.
                let (topic, _) = rawMessageWithTopic
                return topic.channelId == channelId
            })
            .compactMap { message -> T? in
                let (_, payload) = message
                
                guard let channelEvent: T = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse channelEvent")
                    return nil
                }
                
                return channelEvent
            }
        
        return createSelfCleaningObservable(observable: observable, topic: channelTopic)
    }
    
    /// Observe Deadvertise events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Deadvertise events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///     - eventTarget: target for which Deadvertise events should be emitted
    /// - Returns:  a hot observable emitting incoming Deadvertise events
    public func observeDeadvertise(eventTarget: Component) throws -> Observable<DeadvertiseEvent> {
        let deadvertiseTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Deadvertise)
        
        self.subscribe(topic: deadvertiseTopic)
        
        let observable =  client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter { rawMessageTopic -> Bool in
                let (topic, _) = rawMessageTopic
                return topic.eventType == .Deadvertise
            }
            .compactMap { message -> DeadvertiseEvent? in
                let (_, payload) = message
                
                guard let deadvertiseEvent: DeadvertiseEvent = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse deadvertiseEvent")
                    return nil
                }
                
                return deadvertiseEvent
            }
        
        return createSelfCleaningObservable(observable: observable, topic: deadvertiseTopic)
    }
    
    /// Observe Update events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Update events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///    - eventTarget: target for which Update events should be emitted.
    /// - Returns: a hot observable emitting incoming Update events.
    public func observeUpdate<T: UpdateEvent<Family>>(eventTarget: Component) throws -> Observable<T> {
        
        // FIXME: Prevent duplicated subscriptions.
        let updateTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Update)
        self.subscribe(topic: updateTopic)

        let observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter(isUpdate)
            .compactMap({ (message) -> T? in
                let (coatyTopic, payload) = message
                
                guard let updateEvent: T = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse updateEvent")
                    return nil
                }
                
                updateEvent.completeHandler = {(completeEvent: CompleteEvent) in
                    try? self.publishComplete(identity: eventTarget,
                                              event: completeEvent,
                                              messageToken: coatyTopic.messageToken)
                }
                
                return updateEvent
            })
        
        return createSelfCleaningObservable(observable: observable, topic: updateTopic)
    }
    
    /// Observe Discover events for the given target emitted by the hot
    /// observable returned.
    ///
    /// Discover events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - Parameters:
    ///     - eventTarget: target for which Discover events should be emitted.
    /// - Returns: a hot observable emitting incoming Discover events.
    public func observeDiscover<T: DiscoverEvent<Family>>(eventTarget: Component) throws -> Observable<T> {
        
        // FIXME: Prevent duplicated subscriptions.
        let discoverTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Discover)
        self.subscribe(topic: discoverTopic)

        let observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter(isDiscover)
            .compactMap { (message) -> T? in
                let (coatyTopic, payload) = message
                
                guard let discoverEvent: T = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse discoverEvent")
                    return nil
                }
                
                discoverEvent.resolveHandler = {(resolveEvent: ResolveEvent) in
                    try? self.publishResolve(identity: eventTarget, event: resolveEvent, messageToken: coatyTopic.messageToken)
                }
                
                return discoverEvent
            }
        
        return createSelfCleaningObservable(observable: observable, topic: discoverTopic)
    }
    
    /// Observe Call events for the given target and the given
    /// operation name and context object, emitted by the hot observable returned.
    ///
    /// The operation name must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// The given context object is matched against the context filter specified
    /// in incoming Call event data to determine whether the Call event should be
    /// emitted or skipped by the observable. A Call event is skipped if and only
    /// if a context filter and a context object are *both* specified and they do not
    /// match (checked by using `ObjectMatcher.matchesFilter`). In all other cases,
    /// the Call event is emitted.
    ///
    /// Call events that originate from the given event target, i.e.
    /// that have been published by specifying the given event target as
    /// event source, will not be emitted by the observable returned.
    ///
    /// - MISSING: We are missing the optional context parameter.
    ///
    /// - Parameters:
    ///   - eventTarget: target for which Call events should be emitted
    ///   - operationId: the name of the operation to be invoked
    /// - Returns: a hot observable emitting incoming Call events
    /// whose context filter matches the given context
    public func observeCall<T: CallEvent<Family>>(eventTarget: Component, operationId: String) throws -> Observable<T> {
        
        // FIXME: Prevent duplicated subscriptions.
        // FIXME: A convenience method that explicitly uses the operationId as parameter would be nice.
        
        if !CommunicationTopic.isValidEventTypeFilter(filter: operationId) {
            throw CoatySwiftError.InvalidArgument("\(operationId) is not a valid parameter name.")
        }
        
        let callTopic = try CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Call,
                                                                        eventTypeFilter: operationId)
        
        self.subscribe(topic: callTopic)

        let observable = client.messages.map(convertToTupleFormat)
            .filter({ (topic, payload) -> Bool in
                return topic.sourceObjectId != eventTarget.objectId
            })
            .filter(isCall)
            .filter { (topic, string) -> Bool in
                // Match the operationId and only accept the specified ones.
                topic.callOperationId == operationId
            }
            .compactMap { message -> T? in
                let (coatyTopic, payload) = message
                
                guard let callEvent: T = PayloadCoder.decode(payload) else {
                    LogManager.log.warning("could not parse callEvent")
                    return nil
                }
                
                callEvent.returnHandler = {(returnEvent: ReturnEvent) in
                    try? self.publishReturn(identity: eventTarget,
                                             event: returnEvent,
                                             messageToken: coatyTopic.messageToken)
                }
                
                return callEvent
            }
        
        return createSelfCleaningObservable(observable: observable, topic: callTopic)
    }
    
    /// Observe communication state changes by the hot observable returned.
    /// When subscribed the observable immediately emits the current
    /// communication state.
    public func observeCommunicationState() -> Observable<CommunicationState> {
        return communicationState.asObservable()
    }
    
}
