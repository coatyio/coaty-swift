//
//  CommunicationManager+Observe.swift
//  CoatySwift
//

import Foundation
import RxSwift


extension CommunicationManager {
    
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
        
        // TODO: Subscribe only if not already subscribed.
        self.subscribe(topic: topic)
        
        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isAdvertise)
            .filter({ (rawMessageWithTopic) -> Bool in
                
                // Filter messages according to coreType or objectType.
                let (topic, _) = rawMessageWithTopic
                if (objectType != nil) {
                    return objectType == topic.objectType
                }
                
                if (coreType != nil) {
                    return coreType == topic.coreType
                }
                
                return false
            })
            .map({ (message) -> T in
                let (_, payload) = message
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
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
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
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
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: objectType)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                              eventTarget: eventTarget,
                                              coreType: nil,
                                              objectType: objectType)
        
        return createSelfCleaningObservable(observable: observable, topic: topic)
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
    ///   - eventTarget: target for which Channel events should be emitted
    ///   - channelId: a channel identifier
    /// - Returns: a hot observable emitting incoming Channel events.
    public func observeChannel<T: ChannelEvent<Family>>(eventTarget: Component,
                                                        channelId: String) throws -> Observable<T> {
        
        // TODO: Unsure about associatedUserId parameters. Is it really assigneeUserId?
        let channelTopic = try Topic.createTopicStringByLevelsForChannel(channelId: channelId,
                                                                         associatedUserId: eventTarget
                                                                            .assigneeUserId?.uuidString,
                                                                         sourceObject: nil,
                                                                         messageToken: nil)
        // TODO: Make sure to only subscribe to topic once...
        self.subscribe(topic: channelTopic)

        let observable =  rawMessages.map(convertToTupleFormat)
            .filter(isChannel)
            .filter({ (rawMessageWithTopic) -> Bool in
                // Filter messages according to channelId.
                let (topic, _) = rawMessageWithTopic
                return topic.channelId == channelId
            })
            .map({ (message) -> T in
                let (_, payload) = message
                
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
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
        let deadvertiseTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Deadvertise)
        
        self.subscribe(topic: deadvertiseTopic)
        
        let observable =  rawMessages.map(convertToTupleFormat)
            .filter({ (rawMessageTopic) -> Bool in
                let (topic, _) = rawMessageTopic
                return topic.eventType == .Deadvertise
            })
            .map({ (message) -> DeadvertiseEvent in
                let (_, payload) = message
                
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
        
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
        let updateTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Update)
        self.subscribe(topic: updateTopic)

        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isUpdate)
            .map({ (message) -> T in
                let (coatyTopic, payload) = message
                
                // FIXME: Remove force unwrap.
                let updateEvent: T = PayloadCoder.decode(payload)!
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
        let discoverTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Discover)
        self.subscribe(topic: discoverTopic)

        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isDiscover)
            .map({ (message) -> T in
                let (coatyTopic, payload) = message
                
                // FIXME: Remove force unwrap.
                let discoverEvent: T = PayloadCoder.decode(payload)!
                discoverEvent.resolveHandler = {(resolveEvent: ResolveEvent) in
                    try? self.publishResolve(identity: eventTarget, event: resolveEvent, messageToken: coatyTopic.messageToken)
                }
                
                return discoverEvent
            })
        
        return createSelfCleaningObservable(observable: observable, topic: discoverTopic)
    }
    
    /// - TODO: Missing documentation!
    public func observeCall<T: CallEvent<Family>>(eventTarget: Component) throws -> Observable<T> {
        
        // FIXME: Prevent duplicated subscriptions.
        let callTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Call)
        
        self.subscribe(topic: callTopic)

        let observable = rawMessages.map(convertToTupleFormat)
            .filter(isCall)
            .map({ (message) -> T in
                let (coatyTopic, payload) = message
                
                // FIXME: Remove force unwrap.
                let callEvent: T = PayloadCoder.decode(payload)!
                callEvent.returnHandler = {(returnEvent: ReturnEvent) in
                    try? self.publishReturn(identity: eventTarget,
                                             event: returnEvent,
                                             messageToken: coatyTopic.messageToken)
                }
                
                return callEvent
            })
        
        return createSelfCleaningObservable(observable: observable, topic: callTopic)
    }
    
}
