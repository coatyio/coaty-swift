//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CM+Publish.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {
    
    // MARK: - One way events.
    
    /// Publish a value on the given topic. Used to interoperate with external
    /// clients that subscribe on the given topic.
    ///
    /// The topic is an MQTT publication topic, i.e. a non-empty string that
    /// must not contain the following characters: `NULL (U+0000)`, `#
    /// (U+0023)`, `+ (U+002B)`.
    ///
    /// - Parameters:
    ///   - topic: the topic on which to publish the given payload
    ///   - value: a payload string to be published on the given topic
    /// - Throws: if topic name is invalid
    @available(*, deprecated)
    public func publishRaw(topic: String, value: String) throws {
        guard CommunicationTopic.isValidPublicationTopic(topic) else {
            throw CoatySwiftError.InvalidArgument("Could not publish raw: invalid topic name.")
        }

        publish(topic: topic, message: value)
    }
    
    /// Publish a value on the given topic. Used to interoperate with external
    /// clients that subscribe on the given topic.
    ///
    /// The topic is an MQTT publication topic, i.e. a non-empty string that
    /// must not contain the following characters: `NULL (U+0000)`, `#
    /// (U+0023)`, `+ (U+002B)`.
    ///
    /// - Parameters:
    ///   - topic: the topic on which to publish the given payload
    ///   - withString: a payload string to be published on the given topic
    /// - Throws: if topic name is invalid
    public func publishRaw(topic: String, withString value: String) throws {
        guard CommunicationTopic.isValidPublicationTopic(topic) else {
            throw CoatySwiftError.InvalidArgument("Could not publish raw: invalid topic name.")
        }

        publish(topic: topic, message: value)
    }
    
    /// Publish a value on the given topic. Used to interoperate with external
    /// clients that subscribe on the given topic.
    ///
    /// The topic is an MQTT publication topic, i.e. a non-empty string that
    /// must not contain the following characters: `NULL (U+0000)`, `#
    /// (U+0023)`, `+ (U+002B)`.
    ///
    /// - Parameters:
    ///   - topic: the topic on which to publish the given payload
    ///   - withBinary: a payload bytes array to be published on the given topic
    /// - Throws: if topic name is invalid
    public func publishRaw(topic: String, withBinary value: [UInt8]) throws {
        guard CommunicationTopic.isValidPublicationTopic(topic) else {
            throw CoatySwiftError.InvalidArgument("Could not publish raw: invalid topic name.")
        }

        publish(topic: topic, message: value)
    }
    
    /// Advertise an object.
    ///
    /// - Parameters:
    ///     - advertiseEvent:  the Advertise event to be published
    public func publishAdvertise(_ event: AdvertiseEvent) {

        let coreType = event.data.object.coreType
        let objectType = event.data.object.objectType

        event.sourceId = self.identity.objectId
        
        // Publish the Advertise event with core type filter to satisfy core type observers.
        let topicForCoreType = CommunicationTopic
                .createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                     sourceId: event.sourceId!,
                                                     eventType: .Advertise,
                                                     eventTypeFilter: coreType.rawValue)
        
        publish(topic: topicForCoreType, message: event.json)

        // Publish event with object type filter to satisfy object type
        // observers unless the advertised object is a core object with a core
        // object type. In this case, object type observers subscribe on the
        // core type followed by a local filter operation to filter out unwanted
        // objects (see `observeAdvertise`).
        if (coreType.objectType != objectType) {
            let topicForObjectType = CommunicationTopic
                .createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                     sourceId: event.sourceId!,
                                                     eventType: .Advertise,
                                                     eventTypeFilter: EVENT_TYPE_FILTER_SEPARATOR + objectType)
            publish(topic: topicForObjectType, message: event.json)
        }

        // Ensure a Deadvertise event is emitted for an advertised Identity and IoNode.
        if event.data.object.coreType == .Identity || event.data.object.coreType == .IoNode {
            
            // Add if not existing already in deadvertiseIds.
            if !deadvertiseIds.contains(event.data.object.objectId) {
                deadvertiseIds.append(event.data.object.objectId)
            }
        }

    }
    
    /// Notify subscribers that an advertised object has been deadvertised.
    ///
    /// - Parameter deadvertiseEvent: the Deadvertise event to be published
    public func publishDeadvertise(_ event: DeadvertiseEvent) {
        event.sourceId = self.identity.objectId
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                               sourceId: event.sourceId!,
                                                                               eventType: .Deadvertise)

        publish(topic: topic, message: event.json)
    }

    /// Publish a Channel event.
    ///
    /// - Parameter event: the Channel event to be published
    public func publishChannel(_ event: ChannelEvent) {
        event.sourceId = self.identity.objectId
        let publishTopic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                                  sourceId: event.sourceId!,
                                                                                  eventType: .Channel,
                                                                                  eventTypeFilter: event.channelId)
        publish(topic: publishTopic, message: event.json)
    }
    
    // MARK: - Two way events.
    
    /// Request or propose an update of the specified object and receive
    /// accomplishments.
    ///
    /// Note that after all initial subscribers have unsubscribed from the returned observable
    /// no more response events will be emitted on the observable and an error event will
    /// be emitted on resubscription.
    ///
    /// - TODO: Implement the lazy publishing behavior (not until the first subscription)
    /// - Parameters:
    ///     - event: the Update event to be published
    /// - Returns: an observable on which associated Complete events are emitted
    public func publishUpdate(_ event: UpdateEvent) -> Observable<CompleteEvent> {
        
        let coreType = event.data.object.coreType
        let objectType = event.data.object.objectType
        let correlationId = CoatyUUID().string

        event.sourceId = self.identity.objectId
  
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let completeTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Complete,
                                                                                     namespace: namespace,
                                                                                     correlationId: correlationId)
        var observable = self.messagesFor(.Complete)
            .filter { message -> Bool in
                // Filter messages according to message token.
                let (topic, _) = message
                return topic.correlationId == correlationId
            }
            .compactMap { message -> CompleteEvent? in
                let (topic, payload) = message
                
                guard let completeEvent: CompleteEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: completeEvent.data) else {
                    return nil
                }

                completeEvent.type = .Complete
                completeEvent.sourceId = topic.sourceId;
                
                return completeEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: completeTopic)

        subscribe(topic: completeTopic)

        // Publish event with core type filter to satisfy core type observers.
        let topicForCoreType = CommunicationTopic
            .createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                 sourceId: event.sourceId!,
                                                 eventType: .Update,
                                                 eventTypeFilter: coreType.rawValue,
                                                 correlationId: correlationId)
        publish(topic: topicForCoreType, message: event.json)

        // Publish event with object type filter to satisfy object type
        // observers unless the updated object is a core object with a core
        // object type. In this case, object type observers subscribe on the
        // core type followed by a local filter operation to filter out unwanted
        // objects (see `observeUpdate`).
        if (coreType.objectType != objectType) {
            let topicForObjectType = CommunicationTopic
                .createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                     sourceId: event.sourceId!,
                                                     eventType: .Update,
                                                     eventTypeFilter: EVENT_TYPE_FILTER_SEPARATOR + objectType,
                                                     correlationId: correlationId)
            publish(topic: topicForObjectType, message: event.json)
        }
        
        return observable
    }

    /// Publishes a complete in response to an Update event. Not accessible by
    /// the application programmer, it is just a convenience method for reacting
    /// upon an update.
    ///
    /// - Parameters:
    ///   - event: the Complete event that should be sent out.
    ///   - correlationId: the correlation Id of the Update request.
    internal func publishComplete(event: CompleteEvent,
                                  correlationId: String) -> Void {
        event.sourceId = self.identity.objectId
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Complete,
                                                                           correlationId: correlationId)
        publish(topic: topic, message: event.json)
    }
    
    /// Find discoverable objects and receive Resolve events for them.
    ///
    /// Note that after all initial subscribers have unsubscribed from the returned observable
    /// no more response events will be emitted on the observable and an error event will
    /// be emitted on resubscription.
    ///
    /// - TODO: Implement the lazy publishing behavior (not until the first subscription)
    /// - Parameters:
    ///     - event: the Discover event to be published.
    /// - Returns: an observable on which associated Resolve events are emitted
    public func publishDiscover(_ event: DiscoverEvent) -> Observable<ResolveEvent> {
        event.sourceId = self.identity.objectId
        let correlationId = CoatyUUID().string
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Discover,
                                                                           correlationId: correlationId)
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let resolveTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Resolve,
                                                                                    namespace: namespace,
                                                                                    correlationId: correlationId)
        
        var observable = self.messagesFor(.Resolve)
            .filter { message -> Bool in
                // Filter messages according to message token.
                let (topic, _) = message
                return topic.correlationId == correlationId
            }
            .compactMap { message -> ResolveEvent? in
                let (topic, payload) = message
                
                guard let resolveEvent: ResolveEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: resolveEvent.data) else {
                    return nil
                }
                
                resolveEvent.type = .Resolve
                resolveEvent.sourceId = topic.sourceId;
                
                return resolveEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: resolveTopic)

        subscribe(topic: resolveTopic)
        publish(topic: topic, message: event.json)
 
        return observable
    }

    /// Publishes a resolve in response to a Discover event. Not accessible by
    /// the application programmer, it is just a convenience method for reacting
    /// upon a discover.
    ///
    /// - Parameters:
    ///   - event: the Resolve event that should be sent out.
    ///   - correlationId: the correlation Id of the Discover request.
    internal func publishResolve(event: ResolveEvent,
                                 correlationId: String) {
        event.sourceId = self.identity.objectId
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Resolve,
                                                                           correlationId: correlationId)
        publish(topic: topic, message: event.json)
    }
    
    /// Find queryable objects and receive Retrieve events for them.
    ///
    /// Note that after all initial subscribers have unsubscribed from the returned observable
    /// no more response events will be emitted on the observable and an error event will
    /// be emitted on resubscription.
    ///
    /// - TODO: Implement the lazy publishing behavior (not until the first subscription)
    /// - Parameters:
    ///     - event: the Query event to be published
    /// - Returns: an observable on which associated Retrieve events are emitted.
    public func publishQuery(_ event: QueryEvent) -> Observable<RetrieveEvent> {
        event.sourceId = self.identity.objectId
        let correlationId = CoatyUUID().string
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Query,
                                                                           correlationId: correlationId)
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let retrieveTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Retrieve,
                                                                                     namespace: namespace,
                                                                                     correlationId: correlationId)
                
        var observable = self.messagesFor(.Retrieve)
            .filter { message -> Bool in
                // Filter messages according to message token.
                let (topic, _) = message
                return topic.correlationId == correlationId
            }
            .compactMap { message -> RetrieveEvent? in
                let (topic, payload) = message
                
                guard let retrieveEvent: RetrieveEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                guard event.ensureValidResponseParameters(eventData: retrieveEvent.data) else {
                    return nil
                }

                retrieveEvent.type = .Retrieve
                retrieveEvent.sourceId = topic.sourceId;
                
                return retrieveEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: retrieveTopic)

        subscribe(topic: retrieveTopic)
        publish(topic: topic, message: event.json)

        return observable
    }
    
    /// Publish a Call event to perform a remote operation and receive results
    /// emitted by the observable returned.
    ///
    /// Note that after all initial subscribers have unsubscribed from the returned observable
    /// no more response events will be emitted on the observable and an error event will
    /// be emitted on resubscription.
    ///
    /// - Parameter event: the Call event to be published.
    /// - Returns: an observable of associated Return events.
    public func publishCall(_ event: CallEvent) -> Observable<ReturnEvent> {
        event.sourceId = self.identity.objectId
        let correlationId = CoatyUUID().string
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Call,
                                                                           eventTypeFilter: event.operation,
                                                                           correlationId: correlationId)
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let returnTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Return,
                                                                                   namespace: namespace,
                                                                                   correlationId: correlationId)
        
        var observable = self.messagesFor(.Return)
            .filter { message -> Bool in
                // Filter messages according to message token.
                let (topic, _) = message
                return topic.correlationId == correlationId
            }
            .compactMap { message -> ReturnEvent? in
                let (topic, payload) = message
                
                guard let returnEvent: ReturnEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                returnEvent.type = .Return
                returnEvent.sourceId = topic.sourceId;
                
                return returnEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: returnTopic)

        subscribe(topic: returnTopic)
        publish(topic: topic, message: event.json)

        return observable
    }
    
    /// Publishes a retrieve in response to a Query event. Not accessible by
    /// the application programmer, it is just a convenience method for reacting
    /// upon a query.
    ///
    /// - Parameters:
    ///   - event: the Retrieve event that should be sent out.
    internal func publishRetrieve(event: RetrieveEvent,
                                  correlationId: String) {
        event.sourceId = self.identity.objectId
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Retrieve,
                                                                           correlationId: correlationId)
        
        publish(topic: topic, message: event.json)
    }
    
    /// Publishes a return in response to a call event. Not accessible by the
    /// application programmer, it is just a convenience method for reacting
    /// upon a call.
    ///
    /// - Parameters:
    ///   - event: the return event that should be sent out.
    ///   - correlationId: the correlation Id of the Call request.
    internal func publishReturn(event: ReturnEvent,
                                correlationId: String) {
        event.sourceId = self.identity.objectId
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: event.sourceId!,
                                                                           eventType: .Return,
                                                                           correlationId: correlationId)
        publish(topic: topic, message: event.json)
    }
    
    // MARK: - IO Routing
    
    /// Publish the given IoValue event.
    ///
    /// No publication is performed if the event's IO source is currently not
    /// associated with any IO actor.
    ///
    /// - Parameter event: the IoValue event for publishing
    public func publishIoValue(event: IoValueEvent) {
        let items = self.ioSourceItems[event.ioSource!.objectId.string] as? IoSourceItem
        if let items = items {
            event.topic = items.associatingRoute
            event.sourceId = self.identity.objectId
            self.publish(topic: event.topic!, message: event.json)
        }
    }
    
    /// Called by an IO router to associate or disassociate an IO source with an
    /// IO actor.
    ///
    /// - Parameter event: the Associate event to be published
    internal func publishAssociate(event: AssociateEvent) throws {
        guard let eventTypeFilter = event.ioContextName, CommunicationTopic.isValidEventTypeFilter(filter: eventTypeFilter) else {
            throw CoatySwiftError.InvalidArgument("Associate: Invalid eventTypeFilter")
        }
        
        let topic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                           sourceId: self.identity.objectId,
                                                                           eventType: .Associate,
                                                                           eventTypeFilter: eventTypeFilter)
        
        self.publish(topic: topic, message: event.json)
    }
}
