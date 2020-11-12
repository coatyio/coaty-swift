//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ObjectLifecycleControllerTests.swift
//  CoatySwift

import XCTest
import CoatySwift

class ObjectLifecycleControllerTests: XCTestCase {
    
    // NOTE: Make sure that a coaty broker (or just any MQTT broker) is running on the localhost before running
    func test() throws {
        // Configure the first coaty agent
        let mqttOptions1 = MQTTClientOptions(host: "127.0.0.1",
                                             port: UInt16(1883))
        let communication1 = CommunicationOptions(mqttClientOptions: mqttOptions1,
                                                  shouldAutoStart: true)
        
        let configuration1 = Configuration(communication: communication1)
        
        let controllers1: [String: Controller.Type] = ["ObjectLifecycleController": ObjectLifecycleController.self]
        
        let components1 = Components(controllers: controllers1,
                                     objectTypes: [])
        
        let coatyAgent1Container = Container.resolve(components: components1,
                                                     configuration: configuration1)
        
        coatyAgent1Container.communicationManager?.start()
        
        
        // Configure the second coaty agent
        let mqttOptions2 = MQTTClientOptions(host: "127.0.0.1",
                                            port: UInt16(1883))
        let communication2 = CommunicationOptions(mqttClientOptions: mqttOptions2,
                                                  shouldAutoStart: true)
        
        let configuration2 = Configuration(communication: communication2)
        
        let components2 = Components(controllers: .init(),
                                     objectTypes: [])
        
        let coatyAgent2Container = Container.resolve(components: components2,
                                                     configuration: configuration2)
        
        coatyAgent2Container.communicationManager?.start()
        
        // Start observing changes to Log events (This object type is already a part of Coaty standard package)
        guard let controller = coatyAgent1Container.getController(name: "ObjectLifecycleController") as? ObjectLifecycleController else {
            return
        }
        
        let testLocationId: CoatyUUID = .init()
        
        var counter = 1
        
        // Create the testLog object that is used for testing purposes
        let testLog = Log(logLevel: .info,
                          logMessage: "Test log. Ignore.",
                          logDate: "Test date")
        testLog.locationId = testLocationId
        
        let expectation1 = XCTestExpectation(description: "Test if new objects can be added")
        let expectation2 = XCTestExpectation(description: "Test existing objects if they can can be modified")
        let expectation3 = XCTestExpectation(description: "Test existing objects if they can can be removed from th network")
        
        // Observe by object type
        controller.observeObjectLifecycleInfoByObjectType(with: Log.objectType,
                                                          objectFilter: ({ $0.locationId == testLocationId }))
            .subscribe(onNext: { info in
                if counter == 1 {
                    if let added = info.added {
                        if added.contains(where: { object -> Bool in
                            object.objectId == testLog.objectId
                        }) {
                            expectation1.fulfill()
                        }
                    } else {
                        XCTFail()
                    }
                    
                    if info.changed != nil {
                        XCTFail()
                    }
                    
                    if info.removed != nil {
                        XCTFail()
                    }
                } else if counter == 2 {
                    if info.added != nil {
                        XCTFail()
                    }
                    
                    if let changed = info.changed {
                        if changed.contains(where: { object -> Bool in
                            object.objectId == testLog.objectId
                        }) {
                            expectation2.fulfill()
                        }
                    } else {
                        XCTFail()
                    }
                    
                    if info.removed != nil {
                        XCTFail()
                    }
                } else if counter == 3 {
                    if info.added != nil {
                        XCTFail()
                    }
                    
                    if info.changed != nil {
                        XCTFail()
                    }
                    
                    if let removed = info.removed {
                        if removed.contains(where: { object -> Bool in
                            object.objectId == testLog.objectId
                        }) {
                            expectation3.fulfill()
                        }
                    } else {
                        XCTFail()
                    }
                }
                counter += 1
        })
        
        // Advertise the created test object from the second agent
        coatyAgent1Container.communicationManager?.publishAdvertise(try! AdvertiseEvent.with(object: testLog))
        
        // Change the existing object and advertise again from the second agent
        testLog.logMessage = "Modifed for test purposes. Ignore."
        coatyAgent1Container.communicationManager?.publishAdvertise(try! AdvertiseEvent.with(object: testLog))
        
        // Removed
        coatyAgent1Container.communicationManager?.publishDeadvertise(DeadvertiseEvent.with(objectIds: [testLog.objectId]))
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 5)
    }
}
