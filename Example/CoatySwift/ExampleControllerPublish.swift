//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleControllerPublish.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift
import RxSwift


class ExampleControllerPublish<Family: ObjectFamily>: Controller<Family> {

    private var timer: Timer?
    
    override func onCommunicationManagerStarting() {
        // Start RxSwift timer to publish an AdvertiseEvent every 5 seonds.
        _ = Observable<Int>
            .timer(RxTimeInterval.seconds(0),
                   period: RxTimeInterval.seconds(5),
                   scheduler: MainScheduler.instance)
            .subscribe(onNext: { (_) in
                self.publishAdvertise()
            })
    }
    
    func publishAdvertise() {
        // Create the object.
        let object = ExampleObject(myValue: "Hello Coaty!")
        
        // Create an event by using the event factory.
        let event = self.eventFactory.AdvertiseEvent.with(object: object)
        
        // Publish the event by using the communication manager.
        try? self.communicationManager.publishAdvertise(event)
        
        print("[ExampleControllerPublish] published advertise event:\t\(object.myValue)")
    }
}
         
