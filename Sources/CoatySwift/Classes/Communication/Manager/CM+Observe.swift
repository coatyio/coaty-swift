//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CM+Observe.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {

    /// Observe communication state changes.
    ///
    /// When subscribed the observable immediately emits the current
    /// communication state.
    ///
    /// - Returns: an observable emitting communication states
    public func observeCommunicationState() -> Observable<CommunicationState> {
        return communicationState.asObservable()
    }

    // MARK: - One way events.
    
    /// Observes incoming messages on a raw subscription topic.
    ///
    /// The topic filter must be a non-empty string that does not contain
    /// the character `NULL (U+0000)`.
    ///
    /// Use this method to interoperate with external systems that publish messages on external topics.
    /// Use this method together with `publishRaw()` to transfer binary data between Coaty agents.
    ///
    /// In order to decode [UInt8] array named data into String use `String(bytes: data, encoding: .utf8)`
    ///
    /// - Parameters:
    ///   - topicFilter: the subscription topic
    /// - Returns: an observable emitting any incoming messages as tuples
    ///   containing the actual topic and the payload as a UInt8 Array
    /// - Throws: if topic filter is invalid
    public func observeRaw(topicFilter: String) throws -> Observable<(String, [UInt8])> {
        guard CommunicationTopic.isValidSubscriptionTopic(topicFilter) else {
            throw CoatySwiftError.InvalidArgument("\(topicFilter) is not a valid subscription topic")
        }
        
        self.subscribe(topic: topicFilter)
        
        return client.rawMQTTMessages.filter { (topic, payload) -> Bool in
            CommunicationTopic.matches(topic, topicFilter)
        }
    }
    
    /// This method should not be called directly, use observeAdvertise(withCoreType) method
    /// or observeAdvertise(withObjectType) method instead.
    ///
    /// - Parameters:
    ///     - topic: topic string in coaty format
    ///     - coreType: observed coreType
    ///     - objectType: observed objectType
    fileprivate func observeAdvertise(topic: String,
                                      coreType: CoreType?,
                                      objectType: String?) -> Observable<AdvertiseEvent> {
        var observable = self.messagesFor(.Advertise,
                                          objectType != nil ?
                                            EVENT_TYPE_FILTER_SEPARATOR + objectType! :
                                            coreType!.rawValue)
            .compactMap { message -> AdvertiseEvent? in
                let (topic, payload) = message
                
                guard let advertiseEvent: AdvertiseEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                advertiseEvent.type = .Advertise
                advertiseEvent.sourceId = topic.sourceId;
                
                return advertiseEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: topic)

        self.subscribe(topic: topic)

        return observable
    }
    
    /// Observe Advertise events for the given core type.
    ///
    /// - Parameters:
    ///     - coreType: coreType core type of objects to be observed
    /// - Returns: an observable emitting incoming Advertise events for the given core type
    public func observeAdvertise(withCoreType: CoreType) -> Observable<AdvertiseEvent> {
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                             eventTypeFilter: withCoreType.rawValue,
                                                                             namespace: namespace)
        return observeAdvertise(topic: topic,
                                coreType: withCoreType,
                                objectType: nil)
    }
    
    /// Observe Advertise events for the given object type.
    ///
    /// The given object type must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///     - objectType: objectType object type of objects to be observed
    /// - Returns: an observable emitting incoming Advertise events for the given object type
    /// - Throws: if object type is invalid
    public func observeAdvertise(withObjectType: String) throws -> Observable<AdvertiseEvent> {
        guard CommunicationTopic.isValidEventTypeFilter(filter: withObjectType) else {
            throw CoatySwiftError.InvalidArgument("\(withObjectType) is not a valid object type")
        }
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;

        // Optimization: in case core objects should be observed by their object
        // type, we do not subscribe on the object type filter but on the core
        // type filter instead, filtering out objects that do not satisfy the
        // core object type (see `publishAdvertise`).
        let objectCoreType = CoreType.getCoreType(forObjectType: withObjectType)
        if objectCoreType != nil {
            let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                                 eventTypeFilter: objectCoreType!.rawValue,
                                                                                 namespace: namespace)
            return observeAdvertise(topic: topic,
                                    coreType: objectCoreType!,
                                    objectType: nil)
                    .filter { (event) -> Bool in
                        return event.data.object.objectType == withObjectType
                    }
        }

        let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                             eventTypeFilter: EVENT_TYPE_FILTER_SEPARATOR + withObjectType,
                                                                             namespace: namespace)
        return observeAdvertise(topic: topic,
                                coreType: nil,
                                objectType: withObjectType)
    }

    /// Observe Deadvertise events.
    ///
    /// - Returns:  an observable emitting incoming Deadvertise events
    public func observeDeadvertise() -> Observable<DeadvertiseEvent> {
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let deadvertiseTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Deadvertise,
                                                                                        namespace: namespace)
        
        var observable =  self.messagesFor(.Deadvertise)
            .compactMap { message -> DeadvertiseEvent? in
                let (topic, payload) = message
                
                guard let deadvertiseEvent: DeadvertiseEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                deadvertiseEvent.type = .Deadvertise
                deadvertiseEvent.sourceId = topic.sourceId;
                
                return deadvertiseEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: deadvertiseTopic)

        self.subscribe(topic: deadvertiseTopic)

        return observable
    }
    
    /// Observe Channel events for the given channel identifier.
    ///
    /// The channel identifier must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///   - channelId: a channel identifier
    /// - Returns: an observable emitting incoming Channel events for the given channel identifier
    /// - Throws: if channel identifier is invalid
    public func observeChannel(channelId: String) throws -> Observable<ChannelEvent> {
        
        guard CommunicationTopic.isValidEventTypeFilter(filter: channelId) else {
            throw CoatySwiftError.InvalidArgument("\(channelId) is not a valid channel Id.")
        }
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let channelTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Channel,
                                                                                    eventTypeFilter: channelId,
                                                                                    namespace: namespace)

        var observable =  self.messagesFor(.Channel, channelId)
            .compactMap { message -> ChannelEvent? in
                let (topic, payload) = message
                
                guard let channelEvent: ChannelEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                channelEvent.type = .Channel
                channelEvent.sourceId = topic.sourceId;
                
                return channelEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: channelTopic)

        self.subscribe(topic: channelTopic)

        return observable
    }

    // MARK: - Two way events.

    /// This method should not be called directly, use observeUpdate(withCoreType:) method
    /// or observeUpdate(withObjectType:) method instead.
    ///
    /// - Parameters:
    ///     - topic: topic string in coaty format
    ///     - coreType: observed coreType
    ///     - objectType: observed objectType
    private func observeUpdate(topic: String,
                               coreType: CoreType?,
                               objectType: String?) -> Observable<UpdateEvent> {
        var observable = self.messagesFor(.Update,
                                          objectType != nil ?
                                            EVENT_TYPE_FILTER_SEPARATOR + objectType! :
                                            coreType!.rawValue)
            .compactMap { message -> UpdateEvent? in
                let (topic, payload) = message
                
                guard let updateEvent: UpdateEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                updateEvent.type = .Update
                updateEvent.sourceId = topic.sourceId;

                updateEvent.completeHandler = {(completeEvent: CompleteEvent) in
                    self.publishComplete(event: completeEvent, correlationId: topic.correlationId!)
                }
                
                return updateEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: topic)

        self.subscribe(topic: topic)

        return observable
    }

    /// Observe Update events for the given core type.
    ///
    /// - Parameters:
    ///     - coreType: coreType core type of objects to be observed
    /// - Returns: an observable emitting incoming Update events for the given core type
    public func observeUpdate(withCoreType: CoreType) -> Observable<UpdateEvent> {
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Update,
                                                                             eventTypeFilter: withCoreType.rawValue,
                                                                             namespace: namespace)
        return observeUpdate(topic: topic,
                             coreType: withCoreType,
                             objectType: nil)
    }
    
    /// Observe Update events for the given object type.
    ///
    /// The given object type must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///     - objectType: objectType object type of objects to be observed
    /// - Returns: an observable emitting incoming Update events for the given object type
    /// - Throws: if object type is invalid
    public func observeUpdate(withObjectType: String) throws -> Observable<UpdateEvent> {
        guard CommunicationTopic.isValidEventTypeFilter(filter: withObjectType) else {
            throw CoatySwiftError.InvalidArgument("\(withObjectType) is not a valid object type")
        }
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;

        // Optimization: in case core objects should be observed by their object
        // type, we do not subscribe on the object type filter but on the core
        // type filter instead, filtering out objects that do not satisfy the
        // core object type (see `publishUpdate`).
        let objectCoreType = CoreType.getCoreType(forObjectType: withObjectType)
        if objectCoreType != nil {
            let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Update,
                                                                                 eventTypeFilter: objectCoreType!.rawValue,
                                                                                 namespace: namespace)
            return observeUpdate(topic: topic,
                                coreType: objectCoreType!,
                                objectType: nil)
                    .filter { (event) -> Bool in
                        return event.data.object.objectType == withObjectType
                    }
        }

        let topic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Update,
                                                                             eventTypeFilter: EVENT_TYPE_FILTER_SEPARATOR + withObjectType,
                                                                             namespace: namespace)
        return observeUpdate(topic: topic,
                             coreType: nil,
                             objectType: withObjectType)
    }
    
    /// Observe Discover events.
    ///
    /// - Returns: an observable emitting incoming Discover events
    public func observeDiscover() -> Observable<DiscoverEvent> {
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let discoverTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Discover,
                                                                                     namespace: namespace)

        var observable = self.messagesFor(.Discover)
            .compactMap { message -> DiscoverEvent? in
                let (topic, payload) = message
                
                guard let discoverEvent: DiscoverEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                discoverEvent.type = .Discover
                discoverEvent.sourceId = topic.sourceId;
                
                discoverEvent.resolveHandler = {(resolveEvent: ResolveEvent) in
                    self.publishResolve(event: resolveEvent, correlationId: topic.correlationId!)
                }
                
                return discoverEvent
            }
        
        observable = createSelfCleaningObservable(observable: observable, topic: discoverTopic)

        self.subscribe(topic: discoverTopic)

        return observable
    }
    
    /// Observe Call events for the given operation and context object.
    ///
    /// The operation name must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// The given context object is matched against the context filter specified
    /// in incoming Call event data to determine whether the Call event should be
    /// emitted or skipped by the observable.
    ///
    /// A Call event is *not* emitted by the observable if:
    /// - context filter and context object are *both* specified and they do not
    ///   match (checked by using `ObjectMatcher.matchesFilter`), or
    /// - context filter is *not* supplied *and* context object *is* specified.
    ///
    /// In all other cases, the Call event is emitted.
    ///
    /// - NOTE: You can also invoke `observeCall` *without* context parameter
    /// and realize a custom matching logic with an RxJS `filter` operator.
    ///
    ///
    /// - Parameters:
    ///   - operationId: the name of the operation to be invoked
    ///   - context: a context object to be matched against the Call event data's context filter (optional)
    /// - Returns: an observable emitting incoming Call events
    /// whose context filter matches the given context
    /// - Throws: if operationId is invalid
    public func observeCall(operationId: String, context: CoatyObject?) throws -> Observable<CallEvent> {
        guard CommunicationTopic.isValidEventTypeFilter(filter: operationId) else {
            throw CoatySwiftError.InvalidArgument("\(operationId) is not a valid operation name.")
        }
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace;
        let callTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Call,
                                                                                 eventTypeFilter: operationId,
                                                                                 namespace: namespace)
        
        var observable = self.messagesFor(.Call, operationId)
            .compactMap { message -> CallEvent? in
                let (topic, payload) = message
                
                guard let callEvent: CallEvent = PayloadCoder.decode(payload) else {
                    return nil
                }

                callEvent.type = .Call
                callEvent.sourceId = topic.sourceId;
                
                callEvent.returnHandler = {(returnEvent: ReturnEvent) in
                    self.publishReturn(event: returnEvent, correlationId: topic.correlationId!)
                }
                
                return callEvent
        }.filter { event -> Bool in
            return event.data.matchesFilter(context: context)
        }
        
        observable = createSelfCleaningObservable(observable: observable, topic: callTopic)

        self.subscribe(topic: callTopic)

        return observable
    }
    
    /// Observe Query events.
    ///
    /// - Returns: an observable emitting incoming Query events
    public func observeQuery() throws -> Observable<QueryEvent> {
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace
        let queryTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Query,
                                                                                  namespace: namespace)
        
        var observable = self.messagesFor(.Query)
            .compactMap { message -> QueryEvent? in
                let (topic, payload) = message
                
                guard let queryEvent: QueryEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                queryEvent.type = .Query
                queryEvent.sourceId = topic.sourceId
                
                queryEvent.retrieveHandler = { (retrieveEvent: RetrieveEvent) in
                    self.publishRetrieve(event: retrieveEvent, correlationId: topic.correlationId!)
                }
                
                return queryEvent
        }
        
        observable = createSelfCleaningObservable(observable: observable, topic: queryTopic)
        
        self.subscribe(topic: queryTopic)
        
        return observable
    }
    
    // MARK: - IO Routing
    
    internal func _observeAssociate() {
        self.ioNodes.forEach { ioNode in
            _ = try? self._observeAssociate(ioNodeName: ioNode.name)
                .subscribe(onNext: { associateEvent in
                    self.handleAssociate(event: associateEvent)
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    private func _observeAssociate(ioNodeName: String) throws -> Observable<AssociateEvent> {
        guard CommunicationTopic.isValidEventTypeFilter(filter: ioNodeName) else {
            throw CoatySwiftError.InvalidArgument("\(ioNodeName) is not a valid context name.")
        }
        
        let namespace = self.communicationOptions.shouldEnableCrossNamespacing ? nil : self.namespace
        let associateTopic = CommunicationTopic.createTopicStringByLevelsForSubscribe(eventType: .Associate,
                                                                                      eventTypeFilter: ioNodeName,
                                                                                      namespace: namespace,
                                                                                      correlationId: nil)
        
        var observable = self.messagesFor(.Associate, ioNodeName)
            .compactMap { message -> AssociateEvent? in
                let (topic, payload) = message
                
                guard let associateEvent: AssociateEvent = PayloadCoder.decode(payload) else {
                    return nil
                }
                
                associateEvent.type = .Associate
                associateEvent.sourceId = topic.sourceId
                
                return associateEvent
        }
        
        observable = createSelfCleaningObservable(observable: observable, topic: associateTopic)
        
        self.subscribe(topic: associateTopic)
        
        return observable
    }
    
    internal func observeDiscoverIoNodes() {
        if self.ioNodes.isEmpty {
            return
        }
        
        _ = self.observeDiscover().filter { event -> Bool in
            event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.IoNode)
        }.subscribe(onNext: { event in
            self.ioNodes.forEach { ioNode in
                event.resolve(resolveEvent: ResolveEvent.with(object: ioNode))
            }
        })
        .disposed(by: self.disposeBag)
    }
    
    /// Observe IO state events for the given IO source or actor.
    ///
    /// When subscribed the subject immediately emits the current association
    /// state.
    ///
    /// Subscriptions to the returned subject are **automatically
    /// unsubscribed** when the communication manager is stopped, in order to
    /// release system resources and to avoid memory leaks.
    ///
    /// - Returns: a subject emitting IO state events for the given IO source or
    /// actor
    public func observeIoState(ioPoint: IoPoint) -> BehaviorSubject<IoStateEvent>{
        return self._observeIoState(ioPointId: ioPoint.objectId)
    }
    
    private func _observeIoState(ioPointId: CoatyUUID) -> BehaviorSubject<IoStateEvent> {
        if let item = self.observedIoStateItems[ioPointId.string] as? IoStateItem {
            return item.subject
        } else {
            // Compute initial IO state for the subject.
            var hasAssociations = false
            var updateRate: Int? = nil
            if let srcItems = self.ioSourceItems[ioPointId.string] as? IoSourceItem {
                hasAssociations = true
                updateRate = srcItems.updateRate
            } else {
                self.ioActorItems.forEach { _, value in
                    // Force cast is safe, since the value must be of type NSMutableDictionary
                    let sourceItems = value as! NSMutableDictionary
                    // It is not certain if sourceIds is not nil, hence an optional casting
                    let sourceIds = sourceItems[ioPointId.string] as? NSMutableArray
                    if sourceIds != nil {
                        hasAssociations = true
                        // Update rate is never delivered to IO actors.
                        updateRate = nil
                    }
                }
            }
            let item = IoStateItem(initialValue: IoStateEvent.with(hasAssociations: hasAssociations, updateRate: updateRate))
            self.observedIoStateItems[ioPointId.string] = item
            
            return item.subject
        }
    }
    
    /// Observe IO values for the given IO actor.
    ///
    /// Depending on the data format specification of the IO actor
    /// (`IoActor.useRawIoValues`), values emitted by the observable are either
    /// raw binary ([UInt8] array) or decoded as JSON objects (Any type).
    ///
    /// Subscriptions to the returned observable are **automatically
    /// unsubscribed** when the communication manager is stopped, in order to
    /// release system resources and to avoid memory leaks.
    ///
    /// - Returns: an observable emitting inbound values for the IO actor
    public func observeIoValue(ioActor: IoActor) -> Observable<Any> {
        let ioActorId = ioActor.objectId
        var item = self.observedIoValueItems[ioActorId.string] as? PublishSubject<Any>
        if item == nil {
            item = PublishSubject<Any>()
            self.observedIoValueItems[ioActorId.string] = item
        }
        
        // Handle incoming IoValues in a separate function
        self._handleIoValues()

        return item!.asObservable()
    }

    private func _handleIoValues() {
        if self.ioValueObservable == nil {
            self.ioValueObservable = Observable.merge(client.rawMQTTMessages, client.ioValueMessages)
            self.ioValueObservable!
                .subscribe(onNext: { topic, payload in
                    // Lookup registered IO actor items for the given IO route and dispatch IO value
                    // to the corresponding IO actors.
                    // items: Dictionary of CoatyUUID to [CoatyUUID]
                    if let items = self.ioActorItems[topic] as? NSMutableDictionary {
                        items.forEach { actorId, _ in
                            // Force cast is safe, since we are sure of the type of actorId.
                            let actorIdString = actorId as! String
                            let actorId = CoatyUUID(uuidString: actorIdString)!
                            if let ioValueItem = self.observedIoValueItems[actorId.string] as? PublishSubject<Any> {
                                if let ioActor = self.findIoPointById(objectId: actorId) as? IoActor {
                                    if let value = ioActor.useRawIoValues, value {
                                        ioValueItem.onNext(payload)
                                    } else {
                                        if let jsonString = NSString(bytes: payload,
                                                                     length: payload.count,
                                                                     encoding: String.Encoding.utf8.rawValue) as String? {
                                            if let anyCodable: AnyCodable = PayloadCoder.decode(jsonString) {
                                                ioValueItem.onNext(anyCodable.value)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }
}
