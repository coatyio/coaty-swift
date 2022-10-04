//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ThingObserverController.swift
//  CoatySwift
//

import Foundation
import RxSwift

// MARK: - ThingObserverController.

/// Observes Things and Thing-related objects.
///
/// This controller is designed to be used by a client with a corresponding
/// controller (e.g. ThingSourceController) that answers to its events.
open class ThingObserverController: Controller {
    
    /// Returns an observable of the Things in the system.
    ///
    /// This is performed by sending a Discovery event with the object type of
    /// Thing.
    ///
    /// This method does not perform any kind of caching and it should be
    /// performed on the application-side.
    public func discoverThings() -> Observable<Thing> {
        return self.communicationManager
            .publishDiscover(DiscoverEvent.with(objectTypes: [SensorThingsTypes.OBJECT_TYPE_THING]))
            .compactMap { event -> Thing? in
                return event.data.object as? Thing
        }
    }
    
    /// Returns an observable emitting advertised Things.
    ///
    /// This method does not perform any kind of caching and it should be
    /// performed on the application-side.
    public func observeAdvertisedThings() throws -> Observable<Thing> {
        return try self.communicationManager
            .observeAdvertise(withObjectType: SensorThingsTypes.OBJECT_TYPE_THING)
            .compactMap { event -> Thing? in
                return event.data.object as? Thing
        }
    }
    
    /// Returns an observable of the Things that are located at the given
    /// Location.
    ///
    /// This is performed by sending a Query event for Thing objects with the
    /// locationId matching the objectId of the Location.
    ///
    /// This method does not perform any kind of caching and it should be
    /// performed on the application-side.
    public func queryThingsAtLocation(locationId: CoatyUUID) -> Observable<[Thing]> {
        let objectFilter = ObjectFilter(condition: ObjectFilterCondition.init(property: ObjectFilterProperty.init("locationId"),
                                                                              expression: .init(filterOperator: .Equals, op1: AnyCodable(locationId))))
        
        return self.communicationManager
            .publishQuery(QueryEvent.with(objectTypes: [SensorThingsTypes.OBJECT_TYPE_THING],
                                          objectFilter: objectFilter,
                                          objectJoinConditions: nil))
            .map { event -> [Thing] in
            return event.data.objects as! [Thing]
        }
    }
}
