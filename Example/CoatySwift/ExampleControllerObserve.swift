//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleControllerObserve.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift

class ExampleControllerObserve<Family: ObjectFamily>: Controller<Family> {

    override func onCommunicationManagerStarting() {
        self.observeAdvertiseExampleObjects()
    }
    
    private func observeAdvertiseExampleObjects() {
        _ = try? self.communicationManager
            .observeAdvertise(withObjectType: "io.coaty.hello-coaty.example-object")
            .subscribe(onNext: { (event) in
                let object = event.data.object as! ExampleObject
                
                print("[ExampleControllerObserve] received advertise event:\t\(object.myValue)")
            })
    }
}
