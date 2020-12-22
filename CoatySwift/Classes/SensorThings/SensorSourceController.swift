//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  SensorSourceController.swift
//  CoatySwift
//

import Foundation
import RxSwift

// MARK: - SensorSourceController.

/// Manages a set of registered Sensors and provides a source for both Sensors
/// and Sensor-related objects.
///
/// This controller is designed to be used by a server as a counterpart of a
/// SensorObserverController.
///
/// You can either register the Sensors manually by calling registerSensor method
/// or do it automatically from the controller options by defining your Sensors
/// in a SensorDefinition array given in the `sensors` option of the controller.
///
/// SensorSourceController also takes some other options (they all default to
/// false):
/// - ignoreSensorDiscoverEvents: Ignores received discover events for registered
///   sensors.
/// - ignoreSensorQueryEvents: Ignores received query events for registered
///   sensors.
/// - skipSensorAdvertise: Does not advertise a sensor when registered.
/// - skipSensorDeadvertise: Does not deadvertise a sensor when unregistered.
open class SensorSourceController: Controller {
    
    // MARK: - Class properties.
    private var _sensors: [String: SensorContainer] = .init()
    private var _observationPublishers: [String: Disposable] = .init()
    private var _sensorValueObservables: [String: PublishSubject<Any>] = .init()
    private var _querySubscription: Disposable?
    private var _discoverSubscription: Disposable?
    
    // MARK: - Overridden lifecycle methods.
    open override func onInit() {
        super.onInit()
        if let sensors = self.options?.extra["sensors"] as? [SensorDefinition] {
            sensors.forEach { definition in
                try? self.registerSensor(sensor: definition.sensor,
                                         io: definition.io.init(parameters: definition.parameters),
                                         observationPublicationType: definition.observationPublicationType,
                                         samplingInterval: definition.samplingInterval)
            }
        }
    }
    
    open override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        self._querySubscription?.dispose()
        self._querySubscription = nil
        self._discoverSubscription?.dispose()
        self._discoverSubscription = nil
    }
    
    // MARK: - Getters.
    /// Returns all the registered sensor containers in an array.
    var registeredSensorContainers: [SensorContainer] {
        get {
            return Array(self._sensors.values);
        }
    }
    
    /// Returns all the registered Sensors in an array.
    var registeredSensors: [Sensor] {
        get {
            var sensors: [Sensor] = []
            self._sensors.values.forEach({ sensors.append($0.sensor) })
            return sensors
        }
    }
    
    // MARK: - Public methods.
    /// Determines whether a Sensor with the given objectId is registered with
    /// this controller.
    func isRegistered(sensorId: CoatyUUID) -> Bool {
        return self._sensors.keys.contains(sensorId.string)
    }
    
    /// - Returns: the sensor container associated with the given Sensor objectId.
    ///
    /// If no such container exists then `nil` is returned.
    func getSensorContainer(sensorId: CoatyUUID) -> SensorContainer? {
        return self._sensors[sensorId.string]
    }
    
    /// Returns the Sensor associated with the given Sensor objectId.
    ///
    /// If no such sensor exists then `nil` is returned.
    func getSensor(sensorId: CoatyUUID) -> Sensor? {
        let container = self._sensors[sensorId.string]
        return container?.sensor
    }
    
    /// Returns the sensor IO interface associated with the given Sensor objectId.
    /// If no such sensor IO exists then `nil` is returned.
    func getSensorIo(sensorId: CoatyUUID) -> SensorIo? {
        if let container = self._sensors[sensorId.string] {
            return container.io
        } else {
            return nil
        }
    }
    
    /// Returns an observable that emits values read from the sensor.
    ///
    /// Only the values read with publishChanneledObservation or
    /// publishAdvertisedObservation will emit new values. Reading the sensor
    /// value manually with SensorIo.read will not emit any new value.
    ///
    /// The observable is created lazily and cached. Once the Sensor associated
    /// with the observable is unregistered, all subscriptions to the observable
    /// are also unsubscribed.
    ///
    /// If the Sensor is not registered, this method will throw an error.
    func getSensorValueObservable(sensorId: CoatyUUID) throws -> Observable<Any> {
        if !self._sensors.keys.contains(sensorId.string) {
            throw CoatySwiftError.RuntimeError("Cannot create a value observable for a non-registered sensor.")
        }
        
        if !self._sensorValueObservables.keys.contains(sensorId.string) {
            self._sensorValueObservables[sensorId.string] = PublishSubject<Any>()
        }
        return self._sensorValueObservables[sensorId.string]!
    }
    
    /// Returns the first registered sensor where the given predicate is true,
    /// `nil` otherwise.
    ///
    /// - Parameters:
    ///     - predicate: findSensor calls predicate once in arbitrary order for
    ///     each registered sensor, until it finds one where predicate returns true.
    ///     If such a sensor is found, that sensor is returned immediately.
    ///     Otherwise, nil is returned
    /// - Returns: the first sensor matching the predicate; otherwise `nil`
    func findSensor(predicate: ((Sensor) -> Bool)) -> Sensor? {
        var found: Sensor?
        self._sensors.values.forEach { container in
            if found == nil, predicate(container.sensor) {
                found = container.sensor
            }
        }
        return found
    }
    
    /// Registers a Sensor to this controller along with its IO handler
    /// interface.
    ///
    /// You can call this function at runtime or register sensors automatically
    /// at the beginning by passing them in the controller options under
    /// `sensors` as a SensorDefinition array.
    ///
    /// If a Sensor with the given objectId already exists, this method is simply
    /// ignored.
    ///
    /// When a sensor is registered, it is advertised to notify other listeners
    /// (unless ignoreSensorAdvertise option is set). The controller class also
    /// starts to listen on query and discover events for Sensors (unless
    /// skipSensorQueryEvents or skipSensorDiscoverEvents options are set).
    ///
    /// If the observationPublicationType is not set to none, then the value of
    /// the sensor is read every `samplingInterval` milliseconds and published as
    /// an observation automatically.
    ///
    /// - Parameters:
    ///     - sensor: Sensor to register to the controller.
    ///     - io: IO handler interface for the sensor. This could be an `MockSensorIo`
    ///     or a custom handler.
    ///     - observationPublicationType: Whether and how the observations of the
    ///     sensor should be published.
    ///     - samplingInterval: If the observations are published automatically,
    ///     defines how often the publications should be sent.
    func registerSensor(sensor: Sensor,
                        io: SensorIo,
                        observationPublicationType: ObservationPublicationType,
                        samplingInterval: Int?) throws {
        if self._sensors.keys.contains(sensor.objectId.string) {
            return
        }
        
        if observationPublicationType != .none && (samplingInterval == nil || samplingInterval! <= 0) {
            throw CoatySwiftError.RuntimeError("A positive sampling interval is expected.")
        }
        
        self._sensors[sensor.objectId.string] = SensorContainer(sensor: sensor, io: io)
        
        if observationPublicationType != .none {
            let timer = Observable<Int>.interval(RxTimeInterval.milliseconds(samplingInterval!), scheduler: MainScheduler.instance)
            let disposable = timer.subscribe { _ in
                try? self._publishObservation(sensorId: sensor.objectId,
                                         channeled: observationPublicationType == .channel)
            }
            self._observationPublishers[sensor.objectId.string] = disposable
        }
        
        if let skipSensorAdvertise = self.options?.extra["skipSensorAdvertise"] as? Bool, !skipSensorAdvertise {
            self.communicationManager.publishAdvertise(try! AdvertiseEvent.with(object: sensor))
        }
        if let ignoreSensorQueryEvents = self.options?.extra["ignoreSensorQueryEvents"] as? Bool, !ignoreSensorQueryEvents {
            self._observeSensorQueriesIfNeeded()
        }
        if let ignoreSensorDiscoverEvents = self.options?.extra["ignoreSensorDiscoverEvents"] as? Bool, !ignoreSensorDiscoverEvents {
            self._observeSensorDiscoversIfNeeded()
        }
    }
    
    /// Unregisters a previously registered Sensor.
    ///
    /// If no such Sensor is registered, then an error is thrown.
    ///
    /// This also sends a disadvertise event to notify the listeners (unless
    /// ignoreSensorDeadvertise option is set). The query and discover events for
    /// this Sensor are ignored from this point on.
    ///
    /// If a value observable for the Sensor exists, then all subscriptions to
    /// that observable are unsubscribed.
    func unregisterSensor(sensorId: CoatyUUID) throws {
        if self._sensors.keys.contains(sensorId.string) {
            throw CoatySwiftError.RuntimeError("sensorId is not registered.")
        }
        
        self._sensors.removeValue(forKey: sensorId.string)
        if self._sensorValueObservables.keys.contains(sensorId.string) {
            self._sensorValueObservables[sensorId.string]?.dispose()
            self._sensorValueObservables.removeValue(forKey: sensorId.string)
        }
        if self._observationPublishers.keys.contains(sensorId.string) {
            self._observationPublishers[sensorId.string]?.dispose()
            self._observationPublishers.removeValue(forKey: sensorId.string)
        }
        
        if let skipSensorDeadvertise = self.options?.extra["skipSensorDeadvertise"] as? Bool, !skipSensorDeadvertise {
            self.communicationManager.publishDeadvertise(DeadvertiseEvent.with(objectIds: [sensorId]))
        }
        
        if self._sensors.isEmpty {
            self._querySubscription?.dispose()
            self._discoverSubscription?.dispose()
        }
    }
    
    /// Publishes an observation for a registered Sensor.
    ///
    /// If no such registered Sensor exists then an error is thrown. The
    /// publication is performed in the form of a channel event. By default the
    /// channelId is the sensorId. However, subclasses can change it by
    /// overriding getChannelId method.
    ///
    /// The observation value is read directly from the IO handler of the Sensor.
    /// The observation time is recorded as this method is called. Subclasses can
    /// change the final value of the observation object by overriding the
    /// createObservation method.
    ///
    /// - Parameters:
    ///     - sensorId: ObjectId of the Sensor to publish the observation.
    ///     - resultQuality: The quality of the result. (optional)
    ///     - validTime: The validity time of the observation. (optional)
    ///     - parameters: Extra parameters for the observation. (optional)
    ///     - featureOfInterestId: UUID of associated feature of interest.
    ///     (optional)
    func publishChanneledObservation(sensorId: CoatyUUID,
                                     resultQuality: [String]? = nil,
                                     validTime: CoatyTimeInterval? = nil,
                                     parameters: [String: String]? = nil,
                                     featureOfInterestId: CoatyUUID? = nil) {
        try? self._publishObservation(sensorId: sensorId,
                                 channeled: true, /* channeled */
                                 resultQuality: resultQuality,
                                 validTime: validTime,
                                 parameters: parameters,
                                 featureOfInterestId: featureOfInterestId)
    }
    
    /// Publishes an observation for a registered Sensor.
    ///
    /// If no such registered Sensor exists then an error is thrown. The
    /// publication is performed in the form of an advertise event.
    ///
    /// The observation value is read directly from the IO handler of the Sensor.
    /// The observation time is recorded as this method is called. Subclasses can
    /// change the final value of the observation object by overriding the
    /// createObservation method.
    ///
    /// - Parameters:
    ///     - sensorId: ObjectId of the Sensor to publish the observation.
    ///     - resultQuality: The quality of the result. (optional)
    ///     - validTime: The validity time of the observation. (optional)
    ///     - parameters: Extra parameters for the observation. (optional)
    ///     - featureOfInterestId: UUID of associated feature of interest.
    ///     (optional)
    func publishAdvertisedObservation(sensorId: CoatyUUID,
                                      resultQuality: [String]? = nil,
                                      validTime: CoatyTimeInterval? = nil,
                                      parameters: [String: String]? = nil,
                                      featureOfInterestId: CoatyUUID? = nil) {
        try? self._publishObservation(sensorId: sensorId,
                                 channeled: false, /* advertised */
                                 resultQuality: resultQuality,
                                 validTime: validTime,
                                 parameters: parameters,
                                 featureOfInterestId: featureOfInterestId)
    }
    
    // MARK: - Private and internal methods.
    /// Creates an Observation object for a Sensor.
    ///
    /// Subclasses can override this method to provide their own logic.
    ///
    /// - Parameters:
    ///     - container: Sensor container creating the observation.
    ///     - value: Value of the observation.
    ///     - resultQuality: The quality of the result. (optional)
    ///     - validTime: The validity time of the observation. (optional)
    ///     - parameters: Extra parameters for the observation. (optional)
    ///     - featureOfInterestId: UUID of associated feature of interest.
    ///     (optional)
    internal func createObservation(container: SensorContainer,
                                    value: Any,
                                    resultQuality: [String]? = nil,
                                    validTime: CoatyTimeInterval? = nil,
                                    parameters: [String: String]? = nil,
                                    featureOfInterestId: CoatyUUID? = nil) -> Observation {
        let now: Double = Date().timeIntervalSince1970 * 1000
        let observation = Observation(phenomenonTime: now,
                                      result: AnyCodable(value),
                                      resultTime: now,
                                      resultQuality: resultQuality,
                                      validTime: validTime,
                                      parameters: parameters,
                                      featureOfInterest: featureOfInterestId,
                                      name: "Observation of \(container.sensor.name)",
                                      objectId: .init(),
                                      externalId: nil,
                                      parentObjectId: container.sensor.objectId)
        return observation
    }
    
    /// Returns the channelId associated with a sensor container.
    ///
    /// By default, it is the objectId of the Sensor. Subclasses can override
    /// this method to provide their own logic.
    internal func getChannelId(container: SensorContainer) -> String {
        return container.sensor.objectId.string
    }
    
    /// Lifecycle method called just before an observation is published for a
    /// specific Sensor.
    ///
    /// Default implementation does nothing.
    internal func onObservationWillPublish(container: SensorContainer, observation: Observation) {
        /// Default implementation is empty
    }
    
    /// Lifecycle method called immediately after an observation is published for
    /// a specific Sensor. Default implementation does nothing.
    internal func onObservationDidPublish(container: SensorContainer, observation: Observation) {
        /// Default implementation is empty
    }
    
    private func _observeSensorQueriesIfNeeded() {
        if self._querySubscription != nil {
            return
        }

        try? self._querySubscription = self.communicationManager.observeQuery().filter({ event -> Bool in
            return true
        }).subscribe(onNext: { event in
            var retrieved: [Sensor] = []
            if event.data.objectFilter == nil {
                retrieved = self.registeredSensors
            } else if let filter = event.data.objectFilter {
                self._sensors.values.forEach { container in
                    if ObjectMatcher.matchesFilter(obj: container.sensor, filter: filter) {
                        retrieved.append(container.sensor)
                    }
                }
            }
            if !retrieved.isEmpty {
                event.retrieve(retrieveEvent: RetrieveEvent.with(objects: retrieved))
            }
        })
    }
    
    private func _observeSensorDiscoversIfNeeded() {
        if self._discoverSubscription != nil {
            return
        }
        
        self._discoverSubscription = self.communicationManager.observeDiscover().subscribe(onNext: { event in
            if event.data.isDiscoveringObjectId() {
                if let container = self._sensors[event.data.objectId!.string] {
                    event.resolve(resolveEvent: ResolveEvent.with(object: container.sensor))
                }
            } else if event.data.isDiscoveringTypes(),
                      event.data.isObjectTypeCompatible(objectType: SensorThingsTypes.OBJECT_TYPE_SENSOR) {
                self._sensors.values.forEach { container in
                    event.resolve(resolveEvent: ResolveEvent.with(object: container.sensor))
                }
            }
        })
    }
    
    private func _publishObservation(sensorId: CoatyUUID,
                                     channeled: Bool,
                                     resultQuality: [String]? = nil,
                                     validTime: CoatyTimeInterval? = nil,
                                     parameters: [String: String]? = nil,
                                     featureOfInterestId: CoatyUUID? = nil) throws {
        if self._sensors.keys.contains(sensorId.string) {
            throw CoatySwiftError.RuntimeError("sensorId is not registered")
        }
        
        let container = self._sensors[sensorId.string]!
        container.io.read { value in
            // Publish the value over the subject if it exists.
            let subject = self._sensorValueObservables[sensorId.string]
            if subject != nil {
                subject?.onNext(value)
            }
            
            let observation = self.createObservation(container: container,
                                                     value: value,
                                                     resultQuality: resultQuality,
                                                     validTime: validTime,
                                                     parameters: parameters,
                                                     featureOfInterestId: featureOfInterestId)
            
            self.onObservationWillPublish(container: container, observation: observation)
            if channeled {
                try? self.communicationManager.publishChannel(ChannelEvent.with(object: observation, channelId: self.getChannelId(container: container)))
            } else {
                try? self.communicationManager.publishAdvertise(AdvertiseEvent.with(object: observation))
            }
            self.onObservationDidPublish(container: container, observation: observation)
        }
    }
}

// MARK: - ObservationPublicationType.

/// Defines whether and how the observations should be automatically published
/// from SensorSourceController.
///
/// This is used together with the samplingInterval value.
public enum ObservationPublicationType: String {
    
    /// The observations should not be published automatically.
    case none = "none"
    
    /// The observations are advertised.
    ///
    /// The value of the sensor is read continuously every `samplingInterval`
    /// milliseconds.
    case advertise = "advertise"
    
    /// The observations are channeled.
    ///
    /// The value of the sensor is read continuously every `samplingInterval`
    /// milliseconds.
    case channel = "channel"
}

// MARK: - SensorDefinition.

/// Static definition of a sensor for use in SensorController.
///
/// This is used in the options of the controller to register the sensors
/// directly at creation. The `sensors` option of the SensorController should
/// contain an array of SensorDefinitions.
///
/// Each definition should contain the Sensor object, the hardware pin that it is
/// connected to, and the type of the IO communication that it has.
public struct SensorDefinition {
    
    /// Hardware-specific parameters necessary for the read and write methods.
    let parameters: Any?
    
    /// The Sensor object.
    ///
    /// This will be used for the main communication with other controllers and
    /// applications.
    let sensor: Sensor

    /// The type of the IO handling used for this sensor.
    ///
    /// You can use predefined ones such as `Aio`, `InputGpio`, `OuputGpio` or
    /// define your own class. You can also use `MockSensorIo` if you don't have
    /// any actual hardware connection.
    let io: ISensorStatic<SensorIo>

    /// The time interval in milliseconds with which the values of the sensor
    /// should be read and published.
    ///
    /// This should only be used if the observationPublicationType is not set to
    /// none.
    let samplingInterval: Int?
    
    /// Defines whether and how the observations should be automatically
    /// published from the controller.
    ///
    /// This is used together with the samplingInterval value. If it is not set
    /// to none, samplingInterval must be set to positive value.
    let observationPublicationType: ObservationPublicationType
    
    public init(parameters: Any? = nil,
                sensor: Sensor,
                io: ISensorStatic<SensorIo>,
                samplingInterval: Int? = nil,
                observationPublicationType: ObservationPublicationType) {
        self.parameters = parameters
        self.sensor = sensor
        self.io = io
        self.samplingInterval = samplingInterval
        self.observationPublicationType = observationPublicationType
    }
}

// MARK: - SensorContainer.

/// The registered sensors as they are used by the SensorController.
///
/// This contains the Sensor object that is used for communication and the IO
/// interface that defines the hardware connection and how the pin is read and
/// written to.
public struct SensorContainer {

    /// The Sensor object. This will be used for the main communication
    /// with other controllers and applications.
    let sensor: Sensor
    
    /// The IO handling used for this sensor.
    let io: SensorIo
}

