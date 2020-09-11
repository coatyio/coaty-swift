//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoActorController.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// A class related to an IoActor:
/// CoatyJS uses tuples (named arrays, passed by reference), but since tuples are pass by value in Swift, it makes more sens to utilize a class here.
/// - the IO actor object
/// - subject for state
/// - subject for update values
/// Generic parameter of the last BehaviourSubject needs to be optional, because in ensureRegistered it must be nillable
internal class IoActorItems {
    var e0: IoActor
    var e1: BehaviorSubject<Bool>
    var e2: BehaviorSubject<AnyCodable?>
    
    init(_ e0: IoActor, _ e1: BehaviorSubject<Bool>, _ e2: BehaviorSubject<AnyCodable?>) {
        self.e0 = e0
        self.e1 = e1
        self.e2 = e2
    }
}

/// Provides convenience methods for observing IO values and for
/// monitoring changes in the association state of specific IO actors.
open class IoActorController: Controller {
    
    // MARK: - Attributes.
    
    // Key: CoatyUUID, Value: IoActorItems
    private var actorItems: NSMutableDictionary = .init()
    
    // MARK: - Overridden Controller lifecycle methods.
    
    override open func onInit() {
        super.onInit()
        self.actorItems = .init()
    }

    override open func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()

        // Establish new observable for IO state and initialize
        // subject for IO association state from the
        // communication manager.
        try? reregisterAll()
    }

    override open func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()

        // IO state and IO value subscriptions are automatically unsubscribed.
    }

    // MARK: - Convenience methods.

    /// Listen to IO values for the given IO actor. The returned observable
    /// always emits the last value received for the given IO actor. When
    /// subscribed, the current value (or undefined if none exists yet) is
    /// emitted immediately.
    ///
    /// Due to this behavior the cached value of the observable will also be
    /// emitted after reassociation. If this is not desired use
    /// `self.communicationManager.observeIoValue` instead. This method doesn't
    /// cache any previously emitted value.
    ///
    /// - Remark: Note that subscriptions on the observable returned **must** be
    /// manually unsubscribed by the application; they are not automatically
    /// unsubscribed when communication manager is stopped.
    ///
    /// - Parameter actor: an IO actor object
    /// - Returns: an observable emitting IO values for the given actor
    public func observeIoValue(actor: IoActor) -> Observable<AnyCodable?> {
        let valueSubject = self.ensureRegistered(actor: actor)
        return valueSubject.e2.asObservable()
    }

    /// Gets the lastest IO value emitted to the given IO actor or `undefined` if
    /// none exists yet.
    ///
    /// - Parameter actor: an IO actor object
    /// - Returns: the latest IO value for the given actor if one exists
    public func getIoValue(actor: IoActor) throws -> AnyCodable? {
        let valueSubject = self.ensureRegistered(actor: actor)
        return try valueSubject.e2.value()
    }

    /// Listen to associations or disassociations for the given IO actor.
    /// The returned observable emits distinct boolean values until changed, i.e
    /// true when the first association is made and false, when the last
    /// association becomes disassociated.
    /// When subscribed, the current association state is emitted immediately.
    ///
    /// - Remark: Note that subscriptions on the observable returned **must** be
    /// manually unsubscribed by the application; they are not automatically
    /// unsubscribed when communication manager is stopped.
    ///
    /// - Parameter actor: an IO actor object
    public func observeAssociation(actor: IoActor) -> Observable<Bool> {
        let association = self.ensureRegistered(actor: actor)
        return association.e1.asObservable()
    }

    /// Determines whether the given IO actor is currently associated.
    public func isAssociated(actor: IoActor) throws -> Bool {
        let association = self.ensureRegistered(actor: actor)
        return try association.e1.value()
    }

    // MARK: - Private functions.

    private func reregisterAll() throws {
        try self.actorItems.forEach { _, value in
            /// Force typecast is safe, since actorItems only stores values of type IoActorItems
            let item = value as! IoActorItems
            let actor = item.e0
            let ioState = self.communicationManager.observeIoState(ioPoint: actor)
            let ioValue = self.communicationManager.observeIoValue(ioActor: actor)
            _ = ioState.subscribe(onNext: { event in
                try? self.onIoStateChanged(actorId: actor.objectId, event: event)
            })
            _ = ioValue.map({ any -> AnyCodable in
                return AnyCodable(any)
            }).subscribe(onNext: { value in self.onIoValueChanged(actorId: actor.objectId, value: value) })

            // Keep subject that may be in use by the application code.
            let value = try ioState.value().eventData
            item.e1.onNext(value.hasAssociations())
        }
    }

    private func ensureRegistered(actor: IoActor) -> IoActorItems {
        let actorId = actor.objectId
        var item: IoActorItems?
        item = self.actorItems[actorId.string] as? IoActorItems
        if item == nil {
            let ioState = self.communicationManager.observeIoState(ioPoint: actor)
            let ioValue = self.communicationManager.observeIoValue(ioActor: actor)
            _ = ioState.subscribe(onNext: { event in
                try? self.onIoStateChanged(actorId: actorId, event: event)
            })
            _ = ioValue.map({ any -> AnyCodable in
                return AnyCodable(any)
            }).subscribe(onNext: { value in
                self.onIoValueChanged(actorId: actorId, value: value)
            })

            let initialValue = try! ioState.value().eventData.hasAssociations()
            
            item = IoActorItems(
                actor,
                BehaviorSubject<Bool>.init(value: initialValue),
                BehaviorSubject<AnyCodable?>.init(value: nil)
            )
            self.actorItems[actorId.string] = item
        }

        /// Force unwrapping is safe, since item is guaranteed to be non nil at this point.
        return item!
    }

    private func onIoStateChanged(actorId: CoatyUUID, event: IoStateEvent) throws {
        guard let item = self.actorItems[actorId.string] as? IoActorItems else {
            return
        }

        if (try item.e1.value()) != event.eventData.hasAssociations() {
            item.e1.onNext(event.eventData.hasAssociations())
        }
    }

    private func onIoValueChanged(actorId: CoatyUUID, value: AnyCodable) {
        guard let item = self.actorItems[actorId.string] as? IoActorItems else {
            return
        }

        item.e2.onNext(value)
    }
}
