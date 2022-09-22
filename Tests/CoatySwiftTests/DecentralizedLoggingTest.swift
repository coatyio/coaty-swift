//  Copyright (c) 2021 Siemens AG. Licensed under the MIT License.
//
//  DecentralizedLoggingTest.swift
//  CoatySwift

import XCTest
import CoatySwift

class DecentralizedLoggingTest: XCTestCase {
    
    /// NOTE: Please make sure that a MQTT broker is running on localhost on port 1883 before running.
    func testExample() throws {
        let components1 = Components(controllers: ["LogCreateorController": LogCreatorController.self],
                                     objectTypes: [])
        let communication1 = CommunicationOptions(namespace: "Logging Test",
                                                 mqttClientOptions: MQTTClientOptions(host: "localhost",
                                                                                      port: UInt16(1883)),
                                                 shouldAutoStart: false)
        let configuration1 = Configuration(communication: communication1)
        let coatyContainer1 = Container.resolve(components: components1,
                                                configuration: configuration1)
        
        let components2 = Components(controllers: ["LogReceiverController": LogReceiverController.self],
                                     objectTypes: [])
        let communication2 = CommunicationOptions(namespace: "Logging Test",
                                                 mqttClientOptions: MQTTClientOptions(host: "localhost",
                                                                                      port: UInt16(1883)),
                                                 shouldAutoStart: false)
        let configuration2 = Configuration(communication: communication2)
        let coatyContainer2 = Container.resolve(components: components2,
                                                configuration: configuration2)
        
        // Start both coaty agents
        coatyContainer1.communicationManager?.start()
        coatyContainer2.communicationManager?.start()
        
        guard let receiverController = coatyContainer2.getController(name: "LogReceiverController") as? LogReceiverController else {
            return
        }
        
        // Introduce a 5 seconds waiting time to give the infrastructure time to log everything.
        let exp = expectation(description: "Test after 5 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 5.0)
        if result == XCTWaiter.Result.timedOut {
            // Check if all log event have been received
            // Following loop can be used to expect each log object to check for decoding problems.
//            receiverController.logStorage.forEach { log in
//                print(log.logTags)
//                print(log.logLabels)
//                print(log.logHost)
//            }
            XCTAssertTrue(receiverController.logStorage.count == 50)
        } else {
            XCTFail("Delay interrupted")
        }
        
        // Shutdown both containers explicitly
        coatyContainer1.shutdown()
        coatyContainer2.shutdown()
    }
}

class LogCreatorController: Controller {
    override func extendLogObject(log: Log) {
        log.logLabels = [
            "nonce": Int.random(in: 0...10000)
        ]
    }
    
    override func onCommunicationManagerStarting() {
        self.publishMultipleLogs()
    }
    
    /// Publishes 50 log objects in total
    private func publishMultipleLogs() {
        for _ in 0...9 {
            self.logInfo(message: "Info Log", tags: ["tag1", "tag2"])
            self.logDebug(message: "Debug Log", tags: ["tag1", "tag2"])
            self.logWarning(message: "Warning Log", tags: ["tag1", "tag2"])
            self.logError(error: CoatySwiftError.RuntimeError("Random error"), message: "Error Log", tags: ["tag1", "tag2"])
            self.logFatal(error: CoatySwiftError.RuntimeError("Random fatal error"), message: "Fatal Log", tags: ["tag1", "tag2"])
        }
    }
}

class LogReceiverController: Controller {
    public var logStorage: [Log] = []
    
    override func onInit() {
        self.logStorage = .init()
    }
    
    override func onCommunicationManagerStarting() {
        _ = self.communicationManager.observeAdvertise(withCoreType: .Log).subscribe(onNext: { event in
            guard let logObject = event.data.object as? Log else {
                fatalError("Expected a Log object, but got something different. Stopping")
            }
            self.logStorage.append(logObject)
        })
    }
}
