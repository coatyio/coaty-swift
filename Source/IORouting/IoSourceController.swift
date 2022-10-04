//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoSourceController.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// A class related to an IoSource:
/// CoatyJS uses tuples (named arrays, passed by reference), but since tuples are pass by value in Swift, it makes more sens to utilize a class here.
/// - the IO source object
/// - state subscription
/// - subject for updateRate
/// - subject for association state
/// - subject for pushing IO values
/// - subscription for observable that emits update values
internal class IoSourceItems {
    var e0: IoSource
    var e1: Disposable?
    var e2: BehaviorSubject<Int?>
    var e3: BehaviorSubject<Bool>
    var e4: PublishSubject<Any>
    var e5: Disposable?
    
    init(_ e0: IoSource,
         _ e1: Disposable?,
         _ e2: BehaviorSubject<Int?>,
         _ e3: BehaviorSubject<Bool>,
         _ e4: PublishSubject<Any>,
         _ e5: Disposable?) {
        self.e0 = e0
        self.e1 = e1
        self.e2 = e2
        self.e3 = e3
        self.e4 = e4
        self.e5 = e5
    }
}

/// Provides data transfer rate controlled publishing of IO values for
/// IO sources and monitoring of changes in the association state of IO sources.
///
/// This controller respects the backpressure strategy of an IO source in order to
/// cope with IO values that are more rapidly produced than specified in the
/// recommended update rate.
open class IoSourceController: Controller {
    
    // MARK: - Attributes.
    
    private var sourceItems: [CoatyUUID: IoSourceItems] = [:]
    
    // MARK: - Overridden Controller lifecycle methods.
    
    open override func onInit() {
        super.onInit()
        self.sourceItems = [:]
    }
    
    open override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        
        // Establish new observable for IO state and initialize
        // subjects for IO values and IO association state from the
        // communication manager.
        self.reregisterAll()
    }
    
    open override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        
        // The current observable for IO state is no longer served by the
        // communication manager so it can be unsubscribed.
        self.deregisterAll()
    }
    
    // MARK: - Convenience methods.
    
    /// Schedule the given IO value for publishing on the given IO source.
    /// Values to be pulished may be throttled or sampled according to
    /// the backpressure strategy and the recommended update rate of the IO source.
    ///
    /// If the given IO source is not associated currently,
    /// no publishing takes place. The given IO value is discarded.
    ///
    /// - Parameters:
    ///     - source: an IO source object
    ///     - value: an IO value of the given type
    /// - Warning: If a published value is a reference type (e.g. Object) and if it gets
    /// mutated after publishing but before being sent to other actors (e.g. with Throttle strategy),
    /// the value received by the associated actor will also reflect the mutated state.
    /// This function does not guarantee that the published values stay immutable.
    public func publish(source: IoSource, value: Any) {
        let item = self.ensureRegistered(source: source)
        let association = item.e3
        let updateSubject = item.e4
        
        if let result = try? association.value(), !result {
            return
        }
        
        updateSubject.onNext(value)
    }

    /// Listen to update rate changes for the given IO source.
    /// The returned observable emits distinct rate values until changed.
    /// When the last association becomes disassociated, undefined is emitted.
    /// When subscribed, the current update rate is emitted immediately.
    ///
    /// - Parameter source: an IO source object
    public func observeUpdateRate(source: IoSource) -> Observable<Int?> {
        let item = self.ensureRegistered(source: source)
        let updateRate = item.e2
        return updateRate.asObservable()
    }
    
    /// Listen to associations or disassociations for the given IO source.
    /// The returned observable emits distinct boolean values until changed, i.e
    /// true when the first association is made and false, when the last
    /// association becomes disassociated.
    /// When subscribed, the current association state is emitted immediately.
    ///
    /// - Parameter source: an IO source object
    public func observeAssociation(source: IoSource) -> Observable<Bool> {
        let item = self.ensureRegistered(source: source)
        let association = item.e3
        return association.asObservable()
    }
    
    /// Determines whether the given IO source is currently associated.
    public func isAssociated(source: IoSource) -> Bool {
        let item = self.ensureRegistered(source: source)
        let association = item.e3
        return try! association.value()
    }
    
    // MARK: - Private functions.
    
    private func reregisterAll() {
        self.sourceItems.forEach { key, item in
            let source = item.e0
            let ioState = self.communicationManager.observeIoState(ioPoint: source)

            item.e1 = ioState.subscribe(onNext: { event in self.onIoStateChanged(sourceId: source.objectId, event: event) })
            
            // Keep subject that may be in use by the application code.
            item.e2.onNext(try! ioState.value().eventData.updateRate()!)
            item.e3.onNext(try! ioState.value().eventData.hasAssociations())
            
            self.updateUpdateRateObservable(item: item)
        }
    }
    
    private func deregisterAll() {
        self.sourceItems.forEach { key, item in
            item.e1?.dispose()
            item.e1 = nil
            item.e5?.dispose()
            item.e5 = nil
        }
    }
    
    private func ensureRegistered(source: IoSource) -> IoSourceItems {
        let sourceId = source.objectId
        var item = self.sourceItems[sourceId]
        if item == nil {
            let ioState = self.communicationManager.observeIoState(ioPoint: source)
            item = IoSourceItems(
                source,
                ioState.subscribe(onNext: { event in self.onIoStateChanged(sourceId: sourceId, event: event) }),
                BehaviorSubject<Int?>.init(value: try! ioState.value().eventData.updateRate()),
                BehaviorSubject<Bool>.init(value: try! ioState.value().eventData.hasAssociations()),
                PublishSubject<Any>.init(),
                nil
            )
            self.sourceItems[sourceId] = item
            self.updateUpdateRateObservable(item: item!)
        }
        
        /// At this point we are sure that `item` is a non nil value, so a force unwrap is safe
        return item!
    }
    
    private func onIoStateChanged(sourceId: CoatyUUID, event: IoStateEvent) {
        let item = self.sourceItems[sourceId]
        
        if item == nil {
            return
        }
        
        var needsUpdate = false
        
        if try! item!.e3.value() != event.eventData.hasAssociations() {
            item!.e3.onNext(event.eventData.hasAssociations())
            needsUpdate = true
        }
        
        if try! item!.e2.value() != event.eventData.updateRate() {
            item!.e2.onNext(event.eventData.updateRate())
            needsUpdate = true
        }
        
        if needsUpdate {
            self.updateUpdateRateObservable(item: item!)
        }
    }
    
    private func updateUpdateRateObservable(item: IoSourceItems) {
        let source = item.e0
        let updateRate = item.e2
        let association = item.e3
        let updateSubject = item.e4
        let updateSubscription = item.e5
        
        // Unsubscribe and discard already scheduled IO values
        updateSubscription?.dispose()
        
        if try! !association.value() {
            item.e5 = nil
            return
        }
        
        let rate = try? updateRate.value()
        var updateObs: Observable<Any>
        
        if rate == nil || rate == 0 {
            updateObs = updateSubject
        } else {
            switch source.updateStrategy ?? IoSourceBackpressureStrategy.Default {
            case .Default:
                fallthrough
            case .Sample:
                // TODO: Is this correct?
                updateObs = updateSubject.sample(Observable<Int>.interval(RxTimeInterval.milliseconds(rate!),
                                                                          scheduler: MainScheduler.instance))
                break
            case .Throttle:
                // TODO: Is this correct
                updateObs = updateSubject.debounce(RxTimeInterval.milliseconds(rate!),
                                                   scheduler: MainScheduler.instance)
                break
            case .None:
                updateObs = updateSubject
                break
            }
        }
        
        item.e5 = updateObs.subscribe(onNext: { value in
            var event: IoValueEvent
            if let raw = source.useRawIoValues, raw {
                let rawPayload = value as! [UInt8]
                event = try! IoValueEvent.with(ioSource: source, value: rawPayload, options: .init())
            } else {
                event = try! IoValueEvent.with(ioSource: source, value: AnyCodable(value), options: .init())
            }
            self.communicationManager.publishIoValue(event: event)
        })
    }
}
