//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ThingSensorObservationObserverController.swift
//  CoatySwift
//

import Foundation
import RxSwift

// MARK: - ThingSensorObservationObserverController.

/// A convenience controller that observes things and associated sensor and
/// observation objects, combining the functionality of `ThingObserverController`
/// and `SensorObserverController`.
///
/// This controller is designed to be used by a client that wants to easily
/// handle sensor-related events as well as sensor observations.
open class ThingSensorObservationObserverController: ThingObserverController {
    
    // MARK: - Class properties.
    private var _sensorObserverController: SensorObserverController?
    private var _thingOnlineSubscription: Disposable?
    private var _thingOfflineSubscription: Disposable?
    private var _sensorSubscriptions: [String: [Disposable]] = .init()
    private var _observationSubscriptions: [String: Disposable] = .init()
    private var _registeredSensors: [String: Sensor] = .init()
    private var _registeredSensorsChangeInfo$: BehaviorSubject<RegisteredSensorsChangeInfo>?
    private var _sensorObservation$ = PublishSubject<SensorObservationSubjectElement>.init()
    private var _thingFilter: ((Thing) -> Bool)?
    private var _sensorFilter: ((Sensor, Thing) -> Bool)?
    
    // MARK: - Overridden lifecycle methods.
    open override func onInit() {
        super.onInit()
        
        self._registeredSensors = .init()
        self._registeredSensorsChangeInfo$ = BehaviorSubject<RegisteredSensorsChangeInfo>
            .init(value: RegisteredSensorsChangeInfo(added: [],
                                                     removed: [],
                                                     changed: [],
                                                     total: []))
        let newControllerName = "SensorObserverController_\(CoatyUUID().string)"
        do {
            try self.container.registerController(name: newControllerName,
                                                  controllerType: SensorObserverController.self,
                                                  controllerOptions: ControllerOptions())
        } catch _ {
            fatalError("SensorObserverController could not be registered")
        }
        
        self._sensorObserverController = self.container.getController(name: newControllerName) as? SensorObserverController
    }
    
    open override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        self._observeThings()
    }
    
    open override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        self._sensorSubscriptions.values.forEach { subs in
            subs.forEach { sub in
                sub.dispose()
            }
        }
        self._sensorSubscriptions.removeAll()
        self._observationSubscriptions.values.forEach { sub in
            sub.dispose()
        }
        self._observationSubscriptions.removeAll()
        self._thingOnlineSubscription?.dispose()
        self._thingOfflineSubscription?.dispose()
        self._registeredSensorsChangeInfo$!.onNext(RegisteredSensorsChangeInfo(added: [],
                                                                               removed: Array(self._registeredSensors.values),
                                                                               changed: [],
                                                                               total: []))
        self._registeredSensors.removeAll()
    }
    
    // MARK: - Getters and setters.
    /// Gets an Observable emitting information about changes in the currently
    /// registered sensors.
    ///
    /// Registered sensor objects are augmented by a property `thing` which
    /// references the associated `Thing` object.
    ///
    /// Emitted sensor objects are read-only. If you need to modify one, e.g. to
    /// delete the `thing` property, clone the object first.
    var registeredSensorsChangeInfo$: BehaviorSubject<RegisteredSensorsChangeInfo>? {
        get {
            return self._registeredSensorsChangeInfo$
        }
    }

    /// Gets an Observable emitting incoming observations on registered sensors.
    var sensorObservation$: PublishSubject<SensorObservationSubjectElement> {
        get {
            return self._sensorObservation$
        }
    }

    /// Sets a filter predicate that determines whether an observed thing is
    /// relevant and should be registered with the controller.
    ///
    /// The filter predicate should return `true` if the passed-in thing is
    /// relevant; `false` otherwise.
    ///
    /// By default, all observed things are considered relevant.
    ///
    /// - Parameter thingFilter: a filter predicate for things
    var thingFilter: ((Thing) -> Bool)? {
        /// NOTE: Variable with a setter must also have a getter
        get {
            return self._thingFilter
        }
        set {
            self._thingFilter = newValue
        }
    }

    /// Sets a filter predicate that determines whether an observed sensor is
    /// relevant and should be registered with the controller.
    ///
    /// The filter predicate should return `true` if the passed-in sensor is
    /// relevant; `false` otherwise.
    ///
    /// By default, all observed sensors of all relevant things are considered
    /// relevant.
    ///
    /// - Parameter sensorFilter: a filter predicate for sensors
    var sensorFilter: ((Sensor, Thing) -> Bool)? {
        /// NOTE: Variable with a setter must also have a getter
        get {
            return self._sensorFilter
        }
        set {
            self._sensorFilter = newValue
        }
    }
    
    // MARK: - Private and Internal methods.
    private func _observeThings() {
        self._thingOnlineSubscription = Observable.of(self.discoverThings(),
                                                      try! self.observeAdvertisedThings())
            .merge()
            .subscribe(onNext: { thing in
                self._onThingReceived(thing)
        })
        
        self._thingOfflineSubscription = self.communicationManager.observeDeadvertise().subscribe(onNext: { event in
            event.data.objectIds.forEach { id in
                self._onDeadvertised(id.string)
            }
        })
    }

    private func _onThingReceived(_ thing: Thing) {
        if let filter = self._thingFilter, !filter(thing) {
            return
        }
        
        let advertiseObservable = try? self._sensorObserverController?
            .observeAdvertisedSensors()
            .filter({ sensor -> Bool in
                sensor.parentObjectId == thing.objectId
        })
        
        let querySensorOfThingObservable = self._sensorObserverController?.querySensorsOfThings(thingId: thing.objectId).concatMap({ sensors in
            return Observable<Sensor>.from(sensors)
        })
        
        let merged = Observable.merge(advertiseObservable!,
                                      querySensorOfThingObservable!)
        
        let subscription = merged.subscribe { sensor in
            self._onSensorReceived(sensor, thing)
        }
        
        if self._sensorSubscriptions.keys.contains(thing.objectId.string) {
            self._sensorSubscriptions[thing.objectId.string]?.append(subscription)
        } else {
            self._sensorSubscriptions[thing.objectId.string] = [subscription]
        }
    }
    
    private func _onSensorReceived(_ sensor: Sensor, _ thing: Thing) {
        if let sensorFilter = self._sensorFilter, !sensorFilter(sensor, thing) {
            return
        }
        sensor.custom["thing"] = thing
        let isRegistered = self._registeredSensors.keys.contains(sensor.objectId.string)
        self._registeredSensors[sensor.objectId.string] = sensor
        self._registeredSensorsChangeInfo$?.onNext(
            RegisteredSensorsChangeInfo(added: isRegistered ? [] : [sensor],
                                        removed: [],
                                        changed: isRegistered ? [sensor] : [],
                                        total: Array(self._registeredSensors.values)))
        if self._observationSubscriptions.keys.contains(sensor.objectId.string) {
            self._observationSubscriptions[sensor.objectId.string]?.dispose()
        }
        self._observationSubscriptions[sensor.objectId.string] = self._observeObservations(sensor)
    }
    
    private func _observeObservations(_ sensor: Sensor) -> Disposable {
        return try! (self._sensorObserverController?
            .observeChanneledObservations(sensorId: sensor.objectId)
            .subscribe(onNext: { observation in
                self._sensorObservation$.onNext(SensorObservationSubjectElement.init(obs: observation,
                                                                                     sensor: sensor))
                _ = 1
            }))!
    }
    
    private func _onDeadvertised(_ objectId: String) {
        // Clean up associated sensors and sensor observations
        var removedThingsIds = Set<CoatyUUID>()
        var removedSensors: [Sensor] = []
        self._registeredSensors.forEach { (id, sensor) in
            if let thing = sensor.custom["thing"] as? Thing, thing.parentObjectId!.string == objectId {
                removedThingsIds.insert(thing.objectId)
                self._observationSubscriptions[id]?.dispose()
                self._observationSubscriptions.removeValue(forKey: id)
                removedSensors.append(sensor)
                self._registeredSensors.removeValue(forKey: id)
            }
        }
        removedThingsIds.forEach { id in
            self._sensorSubscriptions[id.string]?.forEach({ sub in
                sub.dispose()
            })
            self._sensorSubscriptions.removeValue(forKey: id.string)
        }
        if removedSensors.isEmpty {
            return
        }
        self._registeredSensorsChangeInfo$?.onNext(
            RegisteredSensorsChangeInfo(added: [],
                                        removed: removedSensors,
                                        changed: [],
                                        total: Array(self._registeredSensors.values)))
    }
    
    
}

// MARK: - RegisteredSensorsChangeInfo.

/// Represents change information when sensors are registered or deregistered.
public struct RegisteredSensorsChangeInfo {
    
    /// New sensors that have been added.
    public let added: [Sensor]
    
    /// Previously added sensors that have been removed.
    public let removed: [Sensor]
    
    /// Existing sensors that have been readvertised (some properties might have changed).
    public let changed: [Sensor]
    
    /// The current sensors after changes have been applied.
    public let total: [Sensor]
}

/// Used by the _sensorObservation$ property of ThingSensorObservationObserverController class.
internal struct SensorObservationSubjectElement {
    let obs: Observation
    let sensor: Sensor
}
