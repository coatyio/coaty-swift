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
    private func observeAdvertise<S: CoatyObject, T: AdvertiseEvent<S>>(topic: String,
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
        mqtt!.subscribe(topic)
        
        return rawMessages.map(convertToTupleFormat)
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
        
    }
    
    /// Observes advertises with a particular coreType.
    ///
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - coreType: coreType core type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted coreType.
    public func observeAdvertiseWithCoreType<S: CoatyObject,
        T: AdvertiseEvent<S>>(eventTarget: Component,
                              coreType: CoreType) throws -> Observable<T> {
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                    eventTypeFilter: coreType.rawValue)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                                             eventTarget: eventTarget,
                                                             coreType: coreType,
                                                             objectType: nil)
        return observable
    }
    
    /// Observes advertises with a particular objectType.
    /// - Parameters:
    ///     - eventTarget: eventTarget target for which Advertise events should be emitted.
    ///     - objectType: objectType object type of objects to be observed.
    /// - Returns: An observable emitting the advertise events, that have the wanted objectType.
    public func observeAdvertiseWithObjectType<S: CoatyObject,
        T: AdvertiseEvent<S>>(eventTarget: Component,
                              objectType: String) throws -> Observable<T> {
        let topic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise, eventTypeFilter: objectType)
        let observable: Observable<T> = try observeAdvertise(topic: topic,
                                                             eventTarget: eventTarget,
                                                             coreType: nil,
                                                             objectType: objectType)
        return observable
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
    public func observeChannel<Family: ClassFamily, T: ChannelEvent<Family>>(eventTarget: Component,
                                                                             channelId: String) throws -> Observable<T> {
        
        // TODO: Unsure about associatedUserId parameters. Is it really assigneeUserId?
        let channelTopic = try Topic.createTopicStringByLevelsForChannel(channelId: channelId,
                                                                         associatedUserId: eventTarget
                                                                            .assigneeUserId?.uuidString,
                                                                         sourceObject: nil,
                                                                         messageToken: nil)
        // TODO: Make sure to only subscribe to topic once...
        mqtt?.subscribe(channelTopic)
        
        return rawMessages.map(convertToTupleFormat)
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
    public func observeDeadvertise(eventTarget: Component) throws -> Observable<DeadvertiseEvent<Deadvertise>> {
        let channelTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Deadvertise)
        
        mqtt?.subscribe(channelTopic)
        
        return rawMessages.map(convertToTupleFormat)
            .filter({ (rawMessageTopic) -> Bool in
                let (topic, _) = rawMessageTopic
                return topic.eventType == .Deadvertise
            })
            .map({ (message) -> DeadvertiseEvent<Deadvertise> in
                let (_, payload) = message
                
                // FIXME: Remove force unwrap.
                return PayloadCoder.decode(payload)!
            })
    }
    
}
