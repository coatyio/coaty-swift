//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  SensorObserverController.swift
//  CoatySwift
//

import Foundation
import RxSwift

// MARK: - SensorObserverController.

/// Observes Sensors and Sensor-related objects. This controller is designed to
/// be used by a client as a counterpart to a SensorSourceController which should
/// answer its requests.
open class SensorObserverController: Controller {
    
    /// Observe the channeled observations for the given Sensor. By default, the
    /// channelId is the same as the sensorId.
    ///
    /// - Parameters:
    ///     - sensorId: ObjectId of the sensor to listen observations of.
    ///     - channelId: ChannelId to listen to. This is by default the objectId
    ///     of the Sensor and therefore should be left nil. (optional)
    public func observeChanneledObservations(sensorId: CoatyUUID, channelId: String? = nil) throws -> Observable<Observation> {
        return try self.communicationManager
            .observeChannel(channelId: channelId != nil ? channelId! : sensorId.string)
            .filter({ event -> Bool in
                return event.data.object != nil
                    && event.data.object!.objectType == SensorThingsTypes.OBJECT_TYPE_OBSERVATION
                    && event.data.object?.parentObjectId == sensorId
            }).map({ event -> Observation in
                return event.data.object as! Observation
            })
    }
    
    /// Observe the advertised observations for the given Sensor.
    ///
    /// - Parameter sensorId: ObjectId of the sensor to listen observations of.
    public func observeAdvertisedObservations(sensorId: CoatyUUID) throws -> Observable<Observation> {
        return try self.communicationManager
            .observeAdvertise(withObjectType: SensorThingsTypes.OBJECT_TYPE_OBSERVATION)
            .filter({ event -> Bool in
                return event.data.object.parentObjectId! == sensorId
            }).map({ event -> Observation in
                return event.data.object as! Observation
            })
    }
    
    /// Returns an observable emitting advertised Sensors.
    
    /// This method does not perform any kind of caching and it should
    /// be performed on the application-side.
    public func observeAdvertisedSensors() throws -> Observable<Sensor> {
        return try self.communicationManager
            .observeAdvertise(withObjectType: SensorThingsTypes.OBJECT_TYPE_SENSOR)
            .compactMap({ event -> Sensor? in
                return event.data.object as? Sensor
            })
    }
    
    /// Returns an observable of the Sensors in the system.
    ///
    /// This is performed by sending a Discovery event with the object type of
    /// Sensor.
    ///
    /// This method does not perform any kind of caching and it should be
    /// performed on the application-side.
    public func discoverSensors() -> Observable<Sensor> {
        return self.communicationManager
            .publishDiscover(DiscoverEvent.with(objectTypes: [SensorThingsTypes.OBJECT_TYPE_SENSOR]))
            .compactMap({ event -> Sensor? in
                return event.data.object as? Sensor
            })
    }
    
    /// Returns an observable of the Sensors that are associated with this Thing.
    ///
    /// This is performed by sending a Query event for Sensor objects with the
    /// parentObjectId matching the objectId of the Thing.
    ///
    /// This method does not perform any kind of caching and it should be
    /// performed on the application-side.
    public func querySensorsOfThings(thingId: CoatyUUID) -> Observable<[Sensor]> {
        let objectFilter = ObjectFilter(conditions: ObjectFilterConditions(and: [ObjectFilterCondition(property: ObjectFilterProperty("parentObjectId"),
                                                                                                       expression: ObjectFilterExpression(filterOperator: .Equals,
                                                                                                                                          op1: AnyCodable(thingId)))]))
        
        return self.communicationManager
            .publishQuery(QueryEvent.with(objectTypes: [SensorThingsTypes.OBJECT_TYPE_SENSOR],
                                          objectFilter: objectFilter,
                                          objectJoinConditions: nil))
            .map { event -> [Sensor] in
                return event.data.objects as! [Sensor]
        }
    }
}
