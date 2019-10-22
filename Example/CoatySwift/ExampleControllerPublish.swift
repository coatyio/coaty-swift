//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleControllerPublish.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift


class ExampleControllerPublish<Family: ObjectFamily>: Controller<Family> {

    private var timer: Timer?
    
    override func onCommunicationManagerStarting() {
        self.timer = Timer.scheduledTimer(timeInterval: 5.0,
                                            target: self,
                                            selector: #selector(publishAdvertise),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    @objc func publishAdvertise() {
        // Create the object.
        let object = ExampleObject(myValue: "Hello Coaty!")
        
        // Create an event by using the event factory.
        let event = self.eventFactory.AdvertiseEvent.with(object: object)
        
        // Publish the event by using the communication manager.
        try? self.communicationManager.publishAdvertise(event)
        
        print("[ExampleControllerPublish] published advertise event:\t\(object.myValue)")
    }
}
         
