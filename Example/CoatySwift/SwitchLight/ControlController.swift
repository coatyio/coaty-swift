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
        let callEvent = self.eventFactory.CallEvent.with(eventSource: self.identity,
                                                         operation: switchLightOperation,
                                                         parameters: parameters,
                                                         filter: contextFilter)
        
        try? self.communicationManager.publishCall(event: callEvent)
            .subscribe(onNext: { returnEvent in
                print(returnEvent.json)
        }).disposed(by: disposeBag)
    }
}
