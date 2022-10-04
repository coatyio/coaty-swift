//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleControllerPublish.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift
import RxSwift


class ExampleControllerPublish: Controller {

    private var timer: Timer?
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        
        // Start RxSwift timer to publish an AdvertiseEvent every 5 seonds.
        _ = Observable<Int>
            .timer(RxTimeInterval.seconds(0),
                   period: RxTimeInterval.seconds(5),
                   scheduler: MainScheduler.instance)
            .subscribe(onNext: { (i) in
                self.advertiseExampleObject(i + 1)
            })
            .disposed(by: self.disposeBag)
    }
    
    func advertiseExampleObject(_ counter: Int) {
        // Create the object.
        let object = ExampleObject(myValue: "Hello Coaty! (\(counter))")
        
        // Create the event.
        let event = try! AdvertiseEvent.with(object: object)
        
        // Publish the event by the communication manager.
        self.communicationManager.publishAdvertise(event)
        
        print("[ExampleControllerPublish] published Advertise event: \(object.myValue)")
    }
}
         
