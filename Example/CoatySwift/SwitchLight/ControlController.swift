//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ControlController.swift
//  CoatySwift_Example
//
//

import CoatySwift
import Foundation
import RxSwift

/// A Coaty controller that invokes remote operations to control lights.
class ControlController<Family: ObjectFamily>: Controller<Family> {
    
    func switchLights(contextFilter: ContextFilter,
                      onOff: Bool,
                      luminosity: Double,
                      rgba: ColorRGBA,
                      switchTime: Double) {
        self.disposeBag = DisposeBag()
        
        let parameters: [String: AnyCodable] = ["on": .init(onOff),
                                                "color": .init(rgba),
                                                "luminosity": .init(luminosity),
                                                "switchTime": .init(switchTime)]
        
        let switchLightOperation = SwitchLightOperations.lightControlOperation.rawValue
        let callEvent = self.eventFactory.CallEvent.with(operation: switchLightOperation,
                                                         parameters: parameters,
                                                         filter: contextFilter)
        
        try? self.communicationManager
            .publishCall(callEvent)
            .subscribe(onNext: { returnEvent in
                if let result = returnEvent.data.result {
                    logConsole(message: "Switch success: \(result)", eventName: "Return", eventDirection: .In)
                }
                
                if let error = returnEvent.data.error {
                    logConsole(message: "\(error)", eventName: "Return", eventDirection: .In)

                }
        }).disposed(by: disposeBag)
    }
}
