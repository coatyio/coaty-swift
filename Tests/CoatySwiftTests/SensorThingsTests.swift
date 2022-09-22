//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  SensorThingsTests.swift
//  CoatySwift

import XCTest
import Foundation
import CoatySwift
import RxSwift

/// NOTE: This test case sometimes fails to run because of some problems related to thread scheduling
/// If possible run these tests against a physical device (e.g. iPhone), instead of Simulator.
/// Please also note that test results are also often influenced by the current stress on the CPU.

// MARK: - Communication tests.
class SensorThingsTests: XCTestCase {
    static let TEST_TIMEOUT = 10
    
    static let SENSOR_THINGS_TYPES_SET = [
        SensorThingsTypes.OBJECT_TYPE_FEATURE_OF_INTEREST,
        SensorThingsTypes.OBJECT_TYPE_OBSERVATION,
        SensorThingsTypes.OBJECT_TYPE_SENSOR,
        SensorThingsTypes.OBJECT_TYPE_THING
    ]
    
    // MARK: - Test methods.
    func testAdvertise() throws {
        let mqttClientOptions1 = MQTTClientOptions(host: "127.0.0.1", port: UInt16(1883))
        let communicationOptions1 = CommunicationOptions(mqttClientOptions: mqttClientOptions1, shouldAutoStart: true)
        let controllerOptions1 = ControllerOptions(extra: ["name" : "MockEmitterController1", "responseDelay": 1000])
        let controllersConfig1 = ControllerConfig(controllerOptions: ["MockEmitterController" : controllerOptions1])
        let configuration1 = Configuration(common: nil,
                                          communication: communicationOptions1,
                                          controllers: controllersConfig1,
                                          databases: nil)
        let controllers1: [String: Controller.Type] = ["MockEmitterController": MockEmitterController.self]
        let components1 = Components(controllers: controllers1, objectTypes: [])
        let container1 = Container.resolve(components: components1, configuration: configuration1)
        container1.communicationManager?.start()
        
        let mqttClientOptions2 = MQTTClientOptions(host: "127.0.0.1", port: UInt16(1883))
        let communicationOptions2 = CommunicationOptions(mqttClientOptions: mqttClientOptions2, shouldAutoStart: true)
        let configuration2 = Configuration(communication: communicationOptions2)
        let controllers2: [String: Controller.Type] = ["MockReceiverController": MockReceiverController.self]
        let components2 = Components(controllers: controllers2, objectTypes: [])
        let container2 = Container.resolve(components: components2, configuration: configuration2)
        container2.communicationManager?.start()
        
        // Give the infrastructure time to start
        sleep(4)
        
        let expectation = self.expectation(description: "All sensorThings objects can be advertised and received")
        let eventCount = 5
    
        // Set the number of fulfillment calls required for this test to pass
        expectation.expectedFulfillmentCount = SensorThingsTests.SENSOR_THINGS_TYPES_SET.count * (eventCount + 2)
        
        SensorThingsTests.SENSOR_THINGS_TYPES_SET.forEach { element in
            let receiverController = container2.getController(name: "MockReceiverController") as! MockReceiverController
            
            let logger = AdvertiseEventLogger()
            
            receiverController.watchForAdvertiseEvents(logger: logger, objectType: element)
            
            let emitterController = container1.getController(name: "MockEmitterController") as! MockEmitterController
            
            let queue = DispatchQueue.init(label: "test.coaty.sensorThings")
            let delay: DispatchTimeInterval = .milliseconds(1500)
            queue.asyncAfter(deadline: .now() + delay) {
                emitterController.publishAdvertiseEvents(count: eventCount, objectType: element)
                
                // smaller delay does not always guarantee that all events will be received
                let delay2: DispatchTimeInterval = .seconds(4)
                
                queue.asyncAfter(deadline: .now() + delay2) {
                    if logger.count == eventCount {
                        expectation.fulfill()
                    }
                    if logger.eventData.count == eventCount {
                        expectation.fulfill()
                    }
                    for i in 1...eventCount {
                        if i > logger.count {
                            XCTFail("Something went wrong")
                            return
                        }
                        if logger.eventData[i-1].object.name == "Advertised_\(i)" {
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
            
        waitForExpectations(timeout: TimeInterval(5 * SensorThingsTests.TEST_TIMEOUT)) { error in
            container1.shutdown()
            container2.shutdown()
            
            // Give infrastructure time to shutdown the containers
            sleep(2)
            
            if let error = error {
                print("An error occured: \(error.localizedDescription)")
            } else {
                print("Test finished with success")
            }
        }
    }
    
    func testChannel() throws {
        let mqttClientOptions1 = MQTTClientOptions(host: "127.0.0.1", port: UInt16(1883))
        let communicationOptions1 = CommunicationOptions(mqttClientOptions: mqttClientOptions1, shouldAutoStart: true)
        let controllerOptions1 = ControllerOptions(extra: ["name" : "MockEmitterController1", "responseDelay": 1000])
        let controllersConfig1 = ControllerConfig(controllerOptions: ["MockEmitterController" : controllerOptions1])
        let configuration1 = Configuration(common: nil,
                                          communication: communicationOptions1,
                                          controllers: controllersConfig1,
                                          databases: nil)
        let controllers1: [String: Controller.Type] = ["MockEmitterController": MockEmitterController.self]
        let components1 = Components(controllers: controllers1, objectTypes: [])
        let container1 = Container.resolve(components: components1, configuration: configuration1)
        container1.communicationManager?.start()
        
        let mqttClientOptions2 = MQTTClientOptions(host: "127.0.0.1", port: UInt16(1883))
        let communicationOptions2 = CommunicationOptions(mqttClientOptions: mqttClientOptions2, shouldAutoStart: true)
        let configuration2 = Configuration(communication: communicationOptions2)
        let controllers2: [String: Controller.Type] = ["MockReceiverController": MockReceiverController.self]
        let components2 = Components(controllers: controllers2, objectTypes: [])
        let container2 = Container.resolve(components: components2, configuration: configuration2)
        container2.communicationManager?.start()
        
        // Give the infrastructure time to start
        sleep(2)
        
        let expectation = self.expectation(description: "All sensorThings objects can be received through Channel")
        let eventCount = 2
    
        // Set the number of fulfillment calls required for this test to pass
        expectation.expectedFulfillmentCount = SensorThingsTests.SENSOR_THINGS_TYPES_SET.count * (eventCount + 2)
        
        let queue = DispatchQueue.init(label: "test.coaty.sensorThings", qos: .userInitiated)
        
        var testFunction: ((NSArray, Int) -> ())!
        
        /// NOTE: using enough delay is crucial in this test, because of the internal Swift queue management mechanisms
        /// If delay is chosen too small, then the test will fail.
        /// Be aware that this test might also fail if e.g. the broker has some internal delay (try to run it a couple of times before concluding that something is wrong with the implementation)
        
        testFunction = { (elementArray: NSArray, index: Int) in
            if index == elementArray.count {
                return
            }
            let element = elementArray.object(at: index) as! String
            let logger = ChannelEventLogger()
            let channelId = "42"
            
            let receiverController = container2.getController(name: "MockReceiverController") as! MockReceiverController
            let emitterController = container1.getController(name: "MockEmitterController") as! MockEmitterController
            
            var disposable: Disposable!
            
            queue.async {
                disposable = receiverController.watchForChannelEvents(logger: logger, channelId: channelId)
            }
            
            let delay: DispatchTimeInterval = .seconds(6)
            queue.asyncAfter(deadline: .now() + delay) {
                emitterController.publishChannelEvents(count: eventCount, objectType: element, channelId: channelId)
                
                // Delay it by enough time to give the receiverController time to log the incoming events
                let delay2: DispatchTimeInterval = .seconds(6)
                
                queue.asyncAfter(deadline: .now() + delay2) {
                    if logger.count == eventCount {
                        expectation.fulfill()
                    }
                    if logger.eventData.count == eventCount {
                        expectation.fulfill()
                    }
                    for i in 1...eventCount {
                        if i-1 < logger.eventData.count, let object = logger.eventData[i-1].object, object.name == "Channeled_\(i)" {
                            expectation.fulfill()
                        }
                    }
                    
                    // Dispose the channel observable before moving to the next element
                    disposable.dispose()
                    testFunction(elementArray, index+1)
                }
            }
        }
        
        let copy = NSArray(array: SensorThingsTests.SENSOR_THINGS_TYPES_SET)
        testFunction(copy, 0)
            
        waitForExpectations(timeout: TimeInterval(15 * SensorThingsTests.TEST_TIMEOUT)) { error in
            container1.shutdown()
            container2.shutdown()
            
            // Give infrastructure time to shutdown the containers
            sleep(2)
            
            if let error = error {
                print("An error occured: \(error.localizedDescription)")
            } else {
                print("Test finished with success")
            }
        }
    }
    
    func testCoatyTimeInterval() throws {
        // With miliseconds
        let timeInterval = CoatyTimeInterval(start: Date.init().millisecondsSince1970, duration: 4200012)
        let timeIntervalString = timeInterval.toLocalIntervalIsoString(includeMillis: true)
        print(timeIntervalString)
        
        // Without miliseconds
        let timeInterval2 = CoatyTimeInterval(start: Date.init().millisecondsSince1970, duration: 4200012)
        let timeIntervalString2 = timeInterval2.toLocalIntervalIsoString()
        print(timeIntervalString2)
    }
}
