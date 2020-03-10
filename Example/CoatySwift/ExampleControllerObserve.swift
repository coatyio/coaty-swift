//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ExampleControllerObserve.swift
//  CoatySwift
//
//

import Foundation
import CoatySwift

class ExampleControllerObserve: Controller {

    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        
        self.observeAdvertiseExampleObjects()
    }
    
    private func observeAdvertiseExampleObjects() {
        try! self.communicationManager
            .observeAdvertise(withObjectType: ExampleObject.objectType)
            .subscribe(onNext: { (event) in
                let object = event.data.object as! ExampleObject

                print("[ExampleControllerObserve] received Advertise event: \(object.myValue)")
            })
            .disposed(by: self.disposeBag)
    }
}
