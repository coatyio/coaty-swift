//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationManager.swift
//  CoatySwift
//
//

import CocoaMQTT
import Foundation
import RxSwift

/// Provides a set of predefined communication events to transfer Coaty objects
/// between distributed Coaty agents based on the publish-subscribe API of a
/// `CommunicationClient`.
public class CommunicationManager {
    internal enum MessagePayload {
        case stringPayload(String)
        case bytesArrayPayload([UInt8])
    }
    
    // MARK: - Logger.

    internal let log = LogManager.log

    // MARK: - Properties.

    /// Dispose bag for observable subscriptions to be disposed when client ends.
    internal var disposeBag = DisposeBag()
    private var isDisposed = false

    /// Gets the namespace for communication as specified in the configuration
    /// options. Returns the default namespace used, if no namespace has been
    /// specified in configuration options.
    private (set) public var namespace: String

    internal var communicationOptions: CommunicationOptions
    internal var commonOptions: CommonOptions?
    private var subscriptions = [String: Int]()
    
    // Container identity for public and internal use.
    public var identity: Identity

    /// The operating state of the communication manager.
    internal var operatingState: BehaviorSubject<OperatingState> = BehaviorSubject(value: .stopped)

    /// Convenience getter for the communication state of the underlying communication client.
    internal var communicationState: BehaviorSubject<CommunicationState> {
        return client.communicationState
    }

    /// Holds deferred subscriptions while the communication manager is offline.
    private var deferredSubscriptions = Set<String>()

    /// Holds deferred publications (topic, payload) while the communication manager is offline.
    private var deferredPublications = [(String, MessagePayload)]()

    /// Ids of all advertised components that should be deadvertised on disconnection.
    internal var deadvertiseIds = [CoatyUUID]()

    /// A dispatchqueue that handles synchronisation issues when accessing
    /// deferred publications and subscriptions.
    private var queue = DispatchQueue(label: "com.coatyswift.comQueue")

    /// The communication client that offers the required publisher-subscriber API.
    internal var client: CommunicationClient!
    
    // MARK: IORouting properties.
    
    /// IO state observables for own IO sources and actors (mapped by IO point ID).
    /// Key: CoatyUUID, Value: IoStateItem
    internal var observedIoStateItems: NSMutableDictionary = .init()
    
    /// IO value observables for own IO actors (mapped by IO actor ID).
    /// Key: CoatyUUID, Value: PublishSubject(Any)
    internal var observedIoValueItems: NSMutableDictionary = .init()
    
    /// Own IO sources with associating route, actor ids, and updateRate (mapped
    /// by IO source ID).
    /// Key: CoatyUUID, Value: IoSourceItem
    internal var ioSourceItems: NSMutableDictionary = .init()
    
    /// Own IO actors with associated source ids (mapped by associating route).
    /// Key: String, Value: NSMutableDictionary of type: Key: CoatyUUID, Value: NSMutableArray (holding CoatyUUID values)
    internal var ioActorItems: NSMutableDictionary = .init()
    
    /// Observable on which IoValue events are emitted.
    internal var ioValueObservable: Observable<(String, [UInt8])>? = nil
    
    /// Associated IONodes.
    internal var ioNodes: [IoNode] = []

    // MARK: - Initializers.

    public init(identity: Identity,
                communicationOptions: CommunicationOptions,
                commonOptions: CommonOptions?) {
        self.identity = identity
        self.communicationOptions = communicationOptions
        self.commonOptions = commonOptions
        self.namespace = communicationOptions.namespace ?? DEFAULT_NAMESPACE
        try! initializeNamespace()
        
        let mqttClientOptions = self.communicationOptions.mqttClientOptions!
        initializeMQTTClientId(mqttClientOptions)

        client = CocoaMQTTClient(mqttClientOptions: mqttClientOptions, delegate: self)
        
        setupOperatingStateLogging()
        setupCommunicationStateLogging()
        setupOnConnectHandler()
        
        try! self._initIoNodes()
        
        if self.communicationOptions.shouldAutoStart && !mqttClientOptions.shouldTryMDNSDiscovery {
            self.didReceiveStart()
        }
    }

    // MARK: - Manager lifecycle methods.

    /// Starts this communication manager with the communication options
    /// specified in the configuration. This is a noop if the communication
    /// manager has already been started.
    public func start() {
        guard try! self.operatingState.value() != OperatingState.started else {
            return
        }
        startClient()
    }

    /// Stops dispatching and emitting communication events and disconnects from
    /// the communication infrastructure.
    ///
    /// To continue processing with this communication manager sometime later,
    /// invoke `start()`.
    public func stop() {
        endClient()
    }

    /// Unsubscribe and disconnect from the communication binding.
    public func onDispose() {
        if isDisposed {
            return
        }

        isDisposed = true

        endClient()
    }

    /// Starts the client gracefully and tries to connect to the broker.
    private func startClient() {
        // Reinitialize potentially changed options in case of a restart.
        let mqttClientOptions = self.communicationOptions.mqttClientOptions!
        initializeMQTTClientId(mqttClientOptions)
        try! initializeNamespace()
        try! _initIoNodes()
        initializeDeadvertisements()
        
        // Listen to Associate events published by IO Routers.
        _observeAssociate()
        // Listen to Discover events for IoNodes.
        observeDiscoverIoNodes()
        // Listen to Discover events for Identity.
        observeDiscoverIdentity()
        
        let lastWill = self.getLastWill()
        self.client.connect(lastWillTopic: lastWill.topic, lastWillMessage: lastWill.msg)
        updateOperatingState(.started)
    }

    /// Gracefully ends the client.
    /// - NOTE: This triggers explicit identity deadvertisements.
    private func endClient() {
        // Gracefully send deadvertise messages to others.
        // NOTE: This does not change or adjust the last will.
        deadvertiseIdentity()

        self.unobserveIoStateAndValue()
        
        self.disposeBag = DisposeBag()
        self.client.disconnect()
        self.deferredSubscriptions = Set<String>()
        self.deferredPublications = []
        self.deadvertiseIds = []
        self.subscriptions = [:]
        updateOperatingState(.stopped)
    }

    // MARK: - Setup methods.

    private func initializeMQTTClientId(_ mqttClientOptions: MQTTClientOptions) {
        // Assign a valid client id according to MQTT Spec 3.1:
        // The Server MUST allow ClientIds which are between 1 and 23 UTF-8 encoded 
        // bytes in length, and that contain only the characters
        // "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".
        // The Server MAY allow ClientId’s that contain more than 23 encoded bytes.
        // The Server MAY allow ClientId’s that contain characters not included in the list given above. 
        let id = self.identity.objectId.string;
        mqttClientOptions.clientId = "Coaty" + String(id.replacingOccurrences(of: "-", with: "").prefix(18))
    }

    private func initializeNamespace() throws {
        var ns = self.communicationOptions.namespace
        
        if ns == "" || ns == nil {
            ns = DEFAULT_NAMESPACE
        }
        
        guard CommunicationTopic.isValidEventTypeFilter(filter: ns!) else {
            throw CoatySwiftError.InvalidConfiguration("CommunicationOptions.namespace contains invalid characters")
        }
        
        self.namespace = ns!
    }

    private func initializeDeadvertisements() {
        // Make sure the identity is added to the deadvertiseIds array in order to
        // send out a correct last will message.
        deadvertiseIds.append(self.identity.objectId)
        
        // Deadvertise IO nodes when unjoining.
        self.ioNodes.forEach { ioNode in
            deadvertiseIds.append(ioNode.objectId)
        }
    }

    /// Setup for the handler method that is invoked when the communication state of the client changes to online.
    private func setupOnConnectHandler() {
        _  = self.communicationState
            .filter { $0 == .online }
            .subscribe { _ in

                self.advertiseIdentity()
                self.advertiseIoNodes()

                // Publish possible deferred subscriptions and publications.
                _ = self.queue.sync {
                    self.deferredSubscriptions.forEach { topic in
                        self.client.subscribe(topic)
                    }

                    self.deferredPublications.forEach { publication in
                        let topic = publication.0
                        let payload = publication.1
                        switch payload {
                        case .bytesArrayPayload(let bytesArray):
                            self.client.publish(topic, message: bytesArray)
                        case .stringPayload(let string):
                            self.client.publish(topic, message: string)
                        }
                    }

                    self.deferredPublications = []
                }

            }
    }

    private func setupOperatingStateLogging() {
        _ = self.operatingState.subscribe(onNext: { state in
            self.log.debug("Operating State: \(String(describing: state))")
        })
    }

    private func setupCommunicationStateLogging() {
        _ = self.communicationState.subscribe(onNext: { state in
            self.log.info("Communication State: \(String(describing: state))")
        })
    }

    /// Gets last will message to be published when the connection terminates
    /// abnormally.
    private func getLastWill() -> (topic: String, msg: String) {
        let lastWillTopic = CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                                   sourceId: self.identity.objectId,
                                                                                   eventType: .Deadvertise)
        let deadvertiseEvent = DeadvertiseEvent.with(objectIds: deadvertiseIds)

        deadvertiseEvent.sourceId = self.identity.objectId

        return (lastWillTopic,  deadvertiseEvent.json)
    }

    // MARK: - Identity and IoNodes lifecycle management.

    private func advertiseIdentity() {
        // Advertise identity once.
        // (cp. CommunicationManager.observeDiscoverIdentity)
        try! publishAdvertise(AdvertiseEvent.with(object: self.identity))
    }
    
    private func advertiseIoNodes() {
        // Advertise IO nodes when joining (cp. _observeDiscoverIoNodes).
        self.ioNodes.forEach { ioNode in
            try? self.publishAdvertise(AdvertiseEvent.with(object: ioNode))
        }
    }

    private func deadvertiseIdentity() {
        publishDeadvertise(DeadvertiseEvent.with(objectIds: deadvertiseIds))
    }

    private func observeDiscoverIdentity() {
        observeDiscover()
            .filter({ (event) -> Bool in
                (event.data.isDiscoveringTypes() && event.data.isCoreTypeCompatible(.Identity)) ||
                (event.data.isDiscoveringObjectId() && event.data.objectId == self.identity.objectId)
            })
            .subscribe(onNext: { event in
                let resolveEvent = ResolveEvent.with(object: self.identity)
                event.resolve(resolveEvent: resolveEvent)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Communication methods.

    /// Subscribe defers subscriptions until the communication manager comes online.
    ///
    /// - Parameter topic: topic name.
    internal func subscribe(topic: String) {
        _ = queue.sync {
            self.deferredSubscriptions.insert(topic)

            // Subscribe if the client is online.
            if try! self.communicationState.value() == .online {
                // Do NOT clean up deferredSubscriptions since we may
                // need them for reconnects. Update subscription count
                // map. Do NOT subscribe the same topic filter multiple
                // times to avoid receiving multiple events on this
                // topic.
                if let count = self.subscriptions[topic] {
                    self.subscriptions[topic] = count + 1
                } else {
                    self.subscriptions[topic] = 1
                    self.client.subscribe(topic) 
                }
            }
        }
    }

    internal func unsubscribe(topic: String) {
        _ = queue.sync {
            if let count = self.subscriptions[topic] {
                if count == 1 {
                    client.unsubscribe(topic)
                    self.subscriptions.removeValue(forKey: topic)
                    self.deferredSubscriptions.remove(topic)
                } else {
                    self.subscriptions[topic] = count - 1
                }
            }
        }
    }

    /// Publish defers publications until the communication manager comes online.
    ///
    /// - Parameters:
    ///   - topic: the publication topic.
    ///   - message: the payload message as String.
    internal func publish(topic: String, message: String) {
        _ = queue.sync {
            if try! self.communicationState.value() == .offline {
                self.deferredPublications.append((topic, MessagePayload.stringPayload(message)))
            } else {
                // Attempt to publish. If we are disconnecting, this will fail silently.
                client.publish(topic, message: message)
            }
        }
    }
    
    /// Publish defers publications until the communication manager comes online.
    ///
    /// - Parameters:
    ///   - topic: the publication topic.
    ///   - message: the payload message as Bytes array.
    internal func publish(topic: String, message: [UInt8]) {
        _ = queue.sync {
            if try! self.communicationState.value() == .offline {
                self.deferredPublications.append((topic, MessagePayload.bytesArrayPayload(message)))
            } else {
                // Attempt to publish. If we are disconnecting, this will fail silently.
                client.publish(topic, message: message)
            }
        }
    }

    /// Convenience setter for the operating state.
    private func updateOperatingState(_ state: OperatingState) {
        self.operatingState.onNext(state)
    }
    
    // MARK: - IO Routing
    
    private func _initIoNodes() throws {
        // Set up IO Nodes.
        if let ioNodesConfig = self.commonOptions?.ioContextNodes, !ioNodesConfig.isEmpty {
            self.ioNodes = try ioNodesConfig.keys.filter({ contextName -> Bool in
                if CommunicationTopic.isValidEventTypeFilter(filter: contextName) {
                    return true
                } else {
                    throw CoatySwiftError.InvalidConfiguration("ioContextName \(contextName) in ioContextNodes contains invalid characters")
                }
            }).map({ contextName -> IoNode in
                // Force unwrapping is safe.
                let ioNodeConfig = ioNodesConfig[contextName]!
                
                return IoNode(coreType: .IoNode,
                              objectType: CoreType.IoNode.objectType,
                              objectId: .init(),
                              name: contextName,
                              ioSources: ioNodeConfig.ioSources ?? [],
                              ioActors: ioNodeConfig.ioActors ?? [],
                              characteristics: ioNodeConfig.characteristics)
            }).filter({ node -> Bool in
                node.ioSources.count > 0 || node.ioActors.count > 0
            })
        }
    }
    
    /// Gets the IO node for the given IO context name, as configured in the
    /// configuration common options.
    ///
    /// Returns `nil` if no IO node is configured for the context name.
    public func getIoNodeByContext(contextName: String) -> IoNode? {
        return self.ioNodes.first { ioNode -> Bool in
            return ioNode.name == contextName
        }
    }
    
    /// Creates a new IO route for routing IO values of the given IO source to associated IO
    /// actors.
    ///
    /// This method is called by IO routers to associate IO sources with IO actors. An IO
    /// source publishes IO values on this route; an associated IO actor observes this route
    /// to receive these values.
    ///
    /// - Parameter ioSource: the IO source object
    /// - Returns: an associating topic for routing IO values
    public func createIoRoute(ioSource: IoSource) -> String {
        return CommunicationTopic.createTopicStringByLevelsForPublish(namespace: self.namespace,
                                                                      sourceId: ioSource.objectId,
                                                                      eventType: .IoValue)
    }

    internal func findIoPointById(objectId: CoatyUUID) -> IoPoint? {
        for ioNode in self.ioNodes {
            if let source = (ioNode.ioSources.first { $0.objectId == objectId }) {
                return source
            } else if let actor = (ioNode.ioActors.first { $0.objectId == objectId }) {
                return actor
            }
        }
        return nil
    }
    
    internal func handleAssociate(event: AssociateEvent) {
        let ioSourceId = event.data.ioSourceId
        let ioActorId = event.data.ioActorId
        let ioActor = self.findIoPointById(objectId: ioActorId) as? IoActor
        let isIoSourceAssociated = self.findIoPointById(objectId: ioSourceId) != nil
        let isIoActorAssociated = ioActor != nil

        if !isIoSourceAssociated && !isIoActorAssociated {
            return
        }

        let ioRoute = event.data.associatingRoute

        // Update own IO source associations
        if isIoSourceAssociated {
            self.updateIoSourceItems(ioSourceId: ioSourceId, ioActorId: ioActorId, ioRoute: ioRoute, updateRate: event.data.updateRate)
        }

        // Update own IO actor associations
        if isIoActorAssociated {
            if let ioRoute = ioRoute {
                self.associateIoActorItems(ioSourceId: ioSourceId, ioActor: ioActor!, ioRoute: ioRoute, isExternalRoute: event.data.isExternalRoute!)
            } else {
                self.disassociateIoActorItems(ioSourceId: ioSourceId, ioActorId: ioActorId, currentIoRoute: nil, newIoRoute: nil)
            }
        }

        // Dispatch IO state events to associated observables
        if isIoSourceAssociated {
            if let item = self.observedIoStateItems[ioSourceId.string] as? IoStateItem {
                let items = self.ioSourceItems[ioSourceId.string] as? IoSourceItem
                
                let hasAssociations = (items != nil) && (items!.actorIds.count != 0)
                let updateRate: Int? = (items != nil) ? items!.updateRate : nil
                
                item.dispatchNext(message: IoStateEvent.with(hasAssociations: hasAssociations,
                                                             updateRate: updateRate))
            }
        }

        if isIoActorAssociated {
            if let item = self.observedIoStateItems[ioActorId.string] as? IoStateItem {
                var actorIds: NSMutableDictionary?
                if let ioRoute = ioRoute {
                    actorIds = self.ioActorItems[ioRoute] as? NSMutableDictionary
                }
                
                item.dispatchNext(message: IoStateEvent.with(hasAssociations:
                    actorIds != nil &&
                    actorIds![ioActorId.string] != nil &&
                    (actorIds![ioActorId.string] as! NSMutableArray).count > 0)
                )
            }
        }
    }
    
    private func updateIoSourceItems(ioSourceId: CoatyUUID, ioActorId: CoatyUUID, ioRoute: String?, updateRate: Int?) {
        if let ioRoute = ioRoute {
            if self.ioSourceItems[ioSourceId.string] == nil {
                let items = IoSourceItem(associatingRoute: ioRoute,
                                         actorsIds: [ioActorId],
                                         updateRate: updateRate)
                self.ioSourceItems[ioSourceId.string] = items
            } else if let items = self.ioSourceItems[ioSourceId.string] as? IoSourceItem {
                if items.associatingRoute == ioRoute {
                    if items.actorIds.firstIndex(of: ioActorId) == nil {
                        items.actorIds.append(ioActorId)
                    }
                } else {
                    // Disassociate current IO actors due to a route change.
                    let previousRoute = items.associatingRoute
                    items.associatingRoute = ioRoute
                    items.actorIds.forEach { actorId in
                        self.disassociateIoActorItems(ioSourceId: ioSourceId, ioActorId: actorId, currentIoRoute: previousRoute, newIoRoute: nil)
                    }
                    items.actorIds = [ioActorId]
                }
                items.updateRate = updateRate
            }
        } else {
            if let items = self.ioSourceItems[ioSourceId.string] as? IoSourceItem {
                let i = items.actorIds.firstIndex(of: ioActorId)
                if let i = i {
                    items.actorIds.remove(at: i)
                }
                items.updateRate = updateRate
                if items.actorIds.isEmpty {
                    self.ioSourceItems.removeObject(forKey: ioSourceId.string)
                }
            }
        }
    }
    
    private func associateIoActorItems(ioSourceId: CoatyUUID, ioActor: IoActor, ioRoute: String, isExternalRoute: Bool) {
        let ioActorId = ioActor.objectId
        
        // Disassociate any active association for the given IO source and IO actor.
        self.disassociateIoActorItems(ioSourceId: ioSourceId, ioActorId: ioActorId, currentIoRoute: nil, newIoRoute: ioRoute)
        
        let items = self.ioActorItems[ioRoute] as? NSMutableDictionary
        if items == nil {
            let newItems = NSMutableDictionary()
            let mutableArray = NSMutableArray(array: [ioSourceId])
            newItems[ioActorId.string] = mutableArray
            self.ioActorItems[ioRoute] = newItems
            self.subscribe(topic: ioRoute)
        } else if let items = items {
            let sourceIds = items[ioActorId.string] as? [CoatyUUID]
            if sourceIds == nil {
                let mutableArray = NSMutableArray(array: [ioSourceId])
                items[ioActorId.string] = mutableArray
            } else if var sourceIds = sourceIds {
                if sourceIds.firstIndex(of: ioSourceId) == nil {
                    sourceIds.append(ioSourceId)
                }
            }
        }
    }
    
    private func disassociateIoActorItems(ioSourceId: CoatyUUID,
                                          ioActorId: CoatyUUID,
                                          currentIoRoute: String?,
                                          newIoRoute: String?) {
        var ioRoutesToUnsubscribe: [String] = []
        let handler = { (items: NSMutableDictionary, route: String) in
            if let newIoRoute = newIoRoute, newIoRoute == route {
                return
            }
            let sourceIds = items[ioActorId.string] as? NSMutableArray
            if let sourceIds = sourceIds {
                let element = sourceIds.first { elem -> Bool in
                    if let elem = elem as? CoatyUUID, elem == ioSourceId {
                        return true
                    } else {
                        return false
                    }
                }
                
                if let element = element {
                    sourceIds.remove(element)
                }
                if sourceIds.count == 0 {
                    items.removeObject(forKey: ioActorId.string)
                }
                if items.count == 0 {
                    ioRoutesToUnsubscribe.append(route)
                }
            }
        }
        
        if let currentIoRoute = currentIoRoute {
            if let items = self.ioActorItems[currentIoRoute] as? NSMutableDictionary {
                handler(items, currentIoRoute)
            }
        } else {
            self.ioActorItems.forEach { key, value in
                guard let items = value as? NSMutableDictionary, let key = key as? String else {
                    return
                }
                handler(items, key)
            }
        }
        
        ioRoutesToUnsubscribe.forEach { route in
            self.ioActorItems.removeObject(forKey: route)
            self.unsubscribe(topic: route)
        }
    }
    
    private func unobserveIoStateAndValue() {
        // Dispatch IO state events to all IO state observers.
        self.observedIoStateItems.forEach { _, value in
            let item = value as! IoStateItem
            item.dispatchNext(message: IoStateEvent.with(hasAssociations: false, updateRate: nil))
            
            // Ensure subscriptions on IO state observables are unsubscribed automatically.
            item.dispatchComplete()
        }
        
        // Clean up the current IO routes of all IO actors.
        self.ioActorItems.forEach { key, _ in
            let ioRoute = key as! String
            self.unsubscribe(topic: ioRoute)
        }
        
        // Ensure subscriptions on IO value item observables are unsubscribed automatically.
        self.observedIoValueItems.forEach { _, value in
            let item = value as! PublishSubject<Any>
            item.onCompleted()
        }
        
        // Reset ioValueObservable for restart.
        self.ioValueObservable = nil
    }
}

extension CommunicationManager: Startable {

    /// Auto start communication manager (caused by shouldAutoStart option or
    /// bonjour discovery).
    func didReceiveStart() {
        self.start();
    }
}

class IoStateItem {
    var subject: BehaviorSubject<IoStateEvent>
    
    init(initialValue: IoStateEvent) {
        self.subject = BehaviorSubject<IoStateEvent>.init(value: initialValue)
    }
    
    func dispatchNext(message: IoStateEvent) {
        self.subject.onNext(message)
    }
    
    func dispatchComplete() {
        self.subject.onCompleted()
    }
    
    func dispatchError(error: Swift.Error) {
        self.subject.onError(error)
    }
}

/// Convenience class use by class attribute `IoSourceItems`
internal class IoSourceItem {
    var associatingRoute: String
    
    var actorIds: [CoatyUUID]
    
    var updateRate: Int?
    
    init(associatingRoute: String,
         actorsIds: [CoatyUUID],
         updateRate: Int?) {
        self.associatingRoute = associatingRoute
        self.actorIds = actorsIds
        self.updateRate = updateRate
    }
}
