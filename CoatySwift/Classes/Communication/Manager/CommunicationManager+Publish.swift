//
//  CommunicationManager+Publish.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {
    
    /// Publishes a given advertise event.
    ///
    /// - Parameters:
    ///     - advertiseEvent: The event that should be advertised.
    public func publishAdvertise<S: CoatyObject,T: AdvertiseEvent<S>>(advertiseEvent: T,
                                                                      eventTarget: Component) throws {
        
        let topicForObjectType = try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                                               eventTypeFilter: advertiseEvent.eventData.object.objectType,
                                                                               associatedUserId: "-",
                                                                               sourceObject: advertiseEvent.eventSource,
                                                                               messageToken: UUID.init().uuidString)
        let topicForCoreType = try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                                             eventTypeFilter: advertiseEvent.eventData.object.coreType.rawValue,
                                                                             associatedUserId: "-",
                                                                             sourceObject: advertiseEvent.eventSource,
                                                                             messageToken: UUID.init().uuidString)
        
        // Save advertises for Components or Devices.
        if advertiseEvent.eventData.object.coreType == .Component ||
            advertiseEvent.eventData.object.coreType == .Device {
            
            // Add if not existing already in deadvertiseIds.
            if !deadvertiseIds.contains(advertiseEvent.eventData.object.objectId) {
                deadvertiseIds.append(advertiseEvent.eventData.object.objectId)
            }
        }
        
        // Publish the advertise for core AND object type.
        publish(topic: topicForCoreType, message: advertiseEvent.json)
        publish(topic: topicForObjectType, message: advertiseEvent.json)
    }
    
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
    
    /// Find discoverable objects and receive Resolve events for them emitted by the hot
    /// observable returned.
    ///
    /// - TODO: Implement the lazy behavior.
    /// - Parameters:
    ///     - event: the Discover event to be published.
    /// - Returns: a hot observable on which associated Resolve events are emitted.
    public func publishDiscover<S: Discover,
        T: DiscoverEvent<S>,
        U: ObjectFamily,
        V: ResolveEvent<U>>(event: T) throws -> Observable<V> {
        let discoverMessageToken = UUID.init().uuidString
        let topic = try Topic.createTopicStringByLevelsForPublish(eventType: .Discover,
                                                                  eventTypeFilter: nil,
                                                                  associatedUserId: nil,
                                                                  sourceObject: event.eventSource,
                                                                  messageToken: discoverMessageToken)
        publish(topic: topic, message: event.json)
        
        // FIXME: Subscribe to resolve topic.
        let resolveTopic = try Topic.createTopicStringByLevelsForSubscribe(eventType: .Resolve,
                                                                           eventTypeFilter: nil,
                                                                           associatedUserId: nil,
                                                                           sourceObject: nil,
                                                                           messageToken: discoverMessageToken)
        subscribe(topic: resolveTopic)
        
        return rawMessages.map(convertToTupleFormat)
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
}
