//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  SensorThingsMocks.swift
//  CoatySwift

import Foundation
import CoatySwift
import XCGLogger
import RxSwift

class AdvertiseEventLogger {
    var count: Int = 0
    var eventData: [AdvertiseEventData] = []
}

class ChannelEventLogger {
    var count: Int = 0
    var eventData: [ChannelEventData] = []
}

class RawEventLogger {
    var count: Int = 0
    var eventData: [Any] = []
}

/// Mock controller consuming data produced by sensorThings sensors.
class MockReceiverController: Controller {
    let log = XCGLogger.init()
    
    override func onInit() {
        super.onInit()
        _ = self.communicationManager.publishDiscover(DiscoverEvent.with(objectTypes: [SensorThingsTypes.OBJECT_TYPE_SENSOR])).subscribe(onNext: { event in
            self.log.info(event.data)
        })
        
        _ = self.communicationManager.observeCommunicationState().subscribe(onNext: { state in
            self.log.info(state)
        })
    }
    
    override func onCommunicationManagerStarting() {
        self.log.info("Starting the container with name: \(self.registeredName)")
    }
    
    override func onCommunicationManagerStopping() {
        self.log.info("Stopping the container with name: \(self.registeredName)")
    }
    
    func watchForAdvertiseEvents( logger: AdvertiseEventLogger, objectType: String) {
        _ = try? self.communicationManager
            .observeAdvertise(withObjectType: objectType)
            .subscribe(onNext: { event in
                logger.count += 1
                logger.eventData.append(event.data)
            }).disposed(by: self.disposeBag)
    }
    
    
    func watchForChannelEvents(logger: ChannelEventLogger, channelId: String) -> Disposable {
        return try! self.communicationManager
            .observeChannel(channelId: channelId)
            .subscribe(onNext: { event in
                // Debugging output, use to debug the channel test
//                print("receive event with: \(event.data.object?.name) \(event.data.object?.objectType) \(self.container.identity?.objectId)")
                logger.count += 1
                logger.eventData.append(event.data)
            })
    }
    
    func watchForRawEvents( logger: RawEventLogger, topic: String) {
        _ = try? self.communicationManager.observeRaw(topicFilter: topic).subscribe(onNext: { value in
            logger.count += 1
            // Raw values are emitted as [UInt8] array
            logger.eventData.append(value.1)
        }).disposed(by: self.disposeBag)
    }
}

/// Mock controller producing  sensorThings observations.
class MockEmitterController: Controller {
    private var _name: String = ""
    let log = XCGLogger.init()
    
    override func onInit() {
        super.onInit()
        self._name = self.options?.extra["name"] as! String
        
        self._handleDiscoverEvents()
    }
    
    override func onCommunicationManagerStarting() {
        self.log.info("Starting the container with name: \(self.registeredName)")
    }
    
    override func onCommunicationManagerStopping() {
        self.log.info("Stopping the container with name: \(self.registeredName)")
    }
    
    /// Publish count objects of type objectType through advertise.
    /// - Parameters:
    ///     - count: number Number of times a different object will be advertised
    ///     - objectType: ObjectType the type for objects to be emitted
    func publishAdvertiseEvents(count: Int = 1, objectType: String) {
        for i in 1...count {
            _ = try? self.communicationManager
                .publishAdvertise(
                    AdvertiseEvent.with(
                        object: self._createSensorThings(i: i,
                                                         objectType: objectType,
                                                         name: "Advertised")))
        }
    }
    
    /// Publish count objects of type objectType on a given channel.
    /// - Parameters:
    ///     - count: number Number of times a different object will be published
    ///     - objectType: ObjectType the type for objects to be emitted
    ///     - channelId: the channel id on which objects will be published
    func publishChannelEvents(count: Int, objectType: String, channelId: String) {
        for i in 1...count {
            // Debugging output: use to debug the channel test
//            print("publish event with: \(i) \(objectType)")
            _ = try? self.communicationManager
                .publishChannel(
                    ChannelEvent.with(
                        object: self._createSensorThings(i: i,
                                                         objectType: objectType,
                                                         name: "Channeled"),
                        channelId: channelId))
        }
    }
    
    /// Count and store the advertise events for objectType
    /// - Parameters:
    ///     - logger: A logger for advertise event
    ///     - objectType: Type to look the advertise events for.
    func watchForAdvertiseEvents(logger: AdvertiseEventLogger, objectTypes: String) {
        _ = try? self.communicationManager.observeAdvertise(withObjectType: objectTypes).subscribe(onNext: { event in
            logger.count += 1
            logger.eventData.append(event.data)
        }).disposed(by: self.disposeBag)
    }
    
    /// Observe discover events for object of Type sensor reply to the first of them.
    private func _handleDiscoverEvents() {
        let queue = DispatchQueue(label: "coaty.test.handleDiscoverEvent")
        _ = self.communicationManager.observeDiscover().filter({ event -> Bool in return event.data.isObjectTypeCompatible(objectType: SensorThingsTypes.OBJECT_TYPE_SENSOR) })
            .take(1)
            .subscribe(onNext: { event in
                let responseDelay = self.options?.extra["responseDelay"] as! Int
                let delay: DispatchTimeInterval = .milliseconds(responseDelay)
                queue.asyncAfter(deadline: .now() + delay) {
                    event.resolve(resolveEvent: ResolveEvent.with(object: self._createSensorThings(i: 100, objectType: SensorThingsTypes.OBJECT_TYPE_SENSOR, name: nil)))
                }
            }).disposed(by: self.disposeBag)
    }
    
    private func _createSensorThings(i: Int, objectType: String, name: String?) -> CoatyObject {
        guard let result =  SensorThingsCollection.getObjectByType(objectType: objectType, uuid: .init(), i: i, name: name) else {
            fatalError("Incorrect call of _createSensorThings")
        }
        
        return result
    }
}

/// A collection of sensorThings objects. Used to check validators behaviours.
class SensorThingsCollection {
    public static let sensor = Sensor(description: "A thermometer measures the temperature",
                                      encodingType: SensorEncodingTypes.UNDEFINED,
                                      metadata: AnyCodable(),
                                      unitOfMeasurement: UnitOfMeasurement(name: "Celsius",
                                                                           symbol: "degC",
                                                                           definition: "http://www.qudt.org/qudt/owl/1.0.0/unit/Instances.html#DegreeCelsius"),
                                      observationType: ObservationTypes.MEASUREMENT,
                                      phenomenonTime: CoatyTimeInterval(start: Date().millisecondsSince1970 - 1000,
                                                                        end: Date().millisecondsSince1970),
                                      resultTime: CoatyTimeInterval(start: Date().millisecondsSince1970 - 1000,
                                                                    end: Date().millisecondsSince1970),
                                      observedProperty: ObservedProperty(name: "Temperature",
                                                                         definition: "http://dbpedia.org/page/Dew_point",
                                                                         description: "DewPoint Temperature"),
                                      name: "Thermometer",
                                      objectId: CoatyUUID(uuidString: "83dfc46a-0709-4f70-9ea5-beebf8fa89af")!,
                                      parentObjectId: CoatyUUID(uuidString: "4c480c29-f65f-496f-8005-03e7503eec2b")!)
    
    public static let featureOfInterest = FeatureOfInterest(description: "feature of interest",
                                                            encodingType: EncodingTypes.UNDEFINED,
                                                            metadata: AnyCodable("interesting"),
                                                            name: "F0I1",
                                                            objectId: CoatyUUID(uuidString: "b15521af-9077-4b22-978a-5ff8381d53ae")!)
    
    public static let location = Location(geoLocation: GeoLocation(coords: GeoCoordinates(latitude: 32, longitude: 46, accuracy: 1),
                                                                   timestamp: Double(Date().millisecondsSince1970)),
                                          name: "Muenchen",
                                          objectType: Location.objectType,
                                          objectId: CoatyUUID(uuidString: "14119642-ee6a-4596-bf34-d8a3436290d3")!)
    
    public static let observation = Observation(phenomenonTime: Double(Date().millisecondsSince1970),
                                                result: AnyCodable("12.50"),
                                                resultTime: Double(Date().millisecondsSince1970),
                                                featureOfInterest: CoatyUUID(uuidString: "b15521af-9077-4b22-978a-5ff8381d53ae")!,
                                                name: "Observation1",
                                                objectId: CoatyUUID(uuidString: "31ba0e43-ea26-4179-acf2-299e3a9a0f92")!,
                                                parentObjectId: CoatyUUID(uuidString: "83dfc46a-0709-4f70-9ea5-beebf8fa89af")!)
    
    public static let thing = Thing(description: "",
                                    name: "Thing1",
                                    objectId: CoatyUUID(uuidString: "4c480c29-f65f-496f-8005-03e7503eec2b")!,
                                    locationId: CoatyUUID(uuidString: "14119642-ee6a-4596-bf34-d8a3436290d3")!)
    
    public static func getObjectByType(objectType: String,
                                       uuid: CoatyUUID,
                                       i: Int? = nil,
                                       name: String? = nil) -> CoatyObject? {
        // routing
        let result = SensorThingsCollection._objectTypeRouter(objectType: objectType)
        result?.objectId = uuid
        if let object = result, let name = name, let i = i {
            object.name = name + "_" + "\(i)"
        }
        return result
    }
    
    private static func _objectTypeRouter(objectType: String) -> CoatyObject? {
        switch objectType {
        case SensorThingsTypes.OBJECT_TYPE_SENSOR:
            return SensorThingsCollection.sensor
        case SensorThingsTypes.OBJECT_TYPE_FEATURE_OF_INTEREST:
            return SensorThingsCollection.featureOfInterest
        case CoreType.Location.objectType:
            return SensorThingsCollection.location
        case SensorThingsTypes.OBJECT_TYPE_OBSERVATION:
            return SensorThingsCollection.observation
        case SensorThingsTypes.OBJECT_TYPE_THING:
            return SensorThingsCollection.thing
        default:
            return nil
        }
    }
}


// MARK: - Date extension.
extension Date {
    var millisecondsSince1970: Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
