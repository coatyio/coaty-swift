// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  LightController.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

/// Delegate to trigger changes of a light.
protocol LightControlDelegate {
    func switchLight(_ on: Bool, _ color: ColorRGBA, _ luminosity: Double)
}

/// A Coaty controller that manages a single light with its context and observes
/// Call requests for remote operations to change the light's status.
///
/// For communicating light status changes to the associated light, the controller provides the
/// `LightControlDelegate`.
class LightController<Family: ObjectFamily>: Controller<Family> {
    
    /// MARK: Public attributes.
    
    public var delegate: LightControlDelegate?
    
    // MARK: Private attributes.
    
    /// This is a DispatchQueue for this particular controller that handles
    /// asynchronous workloads, such as when we wait for the delay of the `switchTime`
    private var lightControllerQueue = DispatchQueue(label: "com.siemens.lightSwitch.lightControllerQueue")
    private var light: Light!
    private var lightStatus: LightStatus!
    private var lightContext: LightContext!
    
    // MARK: Lifecycle methods.
    
    override func onInit() {
        super.onInit()
        
        let initialColor = ColorRGBA(r: 255, g: 255, b: 0, a: 1.0)
        self.light = Light(isDefect: false)
        self.lightStatus = LightStatus(on: false, luminosity: 0, color: initialColor)
        self.lightStatus.parentObjectId = self.light.parentObjectId
        
        // The context is currently hardcoded to the default values.
        self.lightContext = LightContext(building: 33, floor: 4, room: 62)
    }
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        observeCallEvents()
    }
    
    // MARK: Application logic.
    
    /// Observe incoming call events that match the operationId of the lightSwitchOperation that is
    /// offered by this controller.
    private func observeCallEvents() {
        let lightSwitchOperation = SwitchLightOperations.lightControlOperation.rawValue
        try? self.communicationManager.observeCall(eventTarget: self.identity, operationId: lightSwitchOperation)
            .subscribe(onNext: { callEvent in
                
                // TODO: Add real context matching.
                guard let _ = callEvent.data.filter else {
                    print("ContextFilter not found.")
                    return
                }
                
                logConsole(message: "lightSwitchOperation()", eventName: "Call", eventDirection: .In)
                
                // Parse the received parameters.
                let on = callEvent.data.getParameterByName(name: "on") as! Bool
                let color = callEvent.data.getParameterByName(name: "color") as! [Any]
                let colorRGBA = self.createColorRGBA(color)
                let luminosity = self.toDouble(callEvent.data.getParameterByName(name: "luminosity")!)
                let switchTime = callEvent.data.getParameterByName(name: "switchTime") as! Int
                
                // Perform parameter validation.
                if !self.validateSwitchOpParams(on, colorRGBA, luminosity, switchTime) {
                    // Validation failed, reply with error.
                    let error = ReturnError(code: .invalidParameters, message: .invalidParameters)
                    let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                        "triggerTime": self.now()]
                    let event = self.eventFactory.ReturnEvent.withError(eventSource: self.identity,
                                                                        error: error,
                                                                        executionInfo: executionInfo)
                    
                    logConsole(message: "Invalid parameters.", eventName: "Return", eventDirection: .Out)
                    callEvent.returned(returnEvent: event)
                    return
                }
                
                // Respond with a custom error if the light is currently defect.
                if self.light.isDefect {
                    let error = ReturnError(code: 1, message: "Light is defect")
                    let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                        "triggerTime": self.now()]
                    let event = self.eventFactory.ReturnEvent.withError(eventSource: self.identity,
                                                                        error: error,
                                                                        executionInfo: executionInfo)
                    callEvent.returned(returnEvent: event)
                    logConsole(message: "Light is defect.", eventName: "Return", eventDirection: .Out)
                    return
                }
                
                // Everything went alright, update the light status and call the delegate.
                self.lightControllerQueue.asyncAfter(deadline: .now() + .milliseconds(switchTime)) {
                    self.updateLightStatus(on, colorRGBA, luminosity)
                    
                    // Make sure to run UI code on the main thread.
                    DispatchQueue.main.async {
                        self.delegate?.switchLight(on, colorRGBA, luminosity)
                    }
                    
                    // Return successful result to the caller.
                    let result: ReturnResult = .init(self.lightStatus!.on)
                    let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                        "triggerTime": self.now()]
                    let event = self.eventFactory.ReturnEvent.withResult(eventSource: self.identity,
                                                                         result: result,
                                                                         executionInfo: executionInfo)
                    
                    logConsole(message: "Successful switch.", eventName: "Return", eventDirection: .Out)
                    callEvent.returned(returnEvent: event)
                }
            }).disposed(by: disposeBag)
    }
    
    // MARK: Utility methods.
    
    /// - TODO: Handle the dangerous force unwrap.
    private func createColorRGBA(_ color: [Any]) -> ColorRGBA {
        let red = color[0] as! Int
        let green = color[1] as! Int
        let blue = color[2] as! Int
        let alpha = toDouble(color[3])
        return ColorRGBA(r: red, g: green, b: blue, a: alpha)
    }
    
    private func toDouble(_ any: Any) -> Double {
        if let double = any as? Double {
            return double
        }
        
        if let int = any as? Int {
            return Double(int)
        }
        
        // Should never occur. For production use, throw an error here.
        return Double.nan
    }
    
    private func validateSwitchOpParams(_ on: Bool,
                                        _ colorRGBA: ColorRGBA,
                                        _ luminosity: Double,
                                        _ switchTime: Int) -> Bool {
        
        if luminosity < 0 || luminosity > 1 {
            return false
        }
        
        // TODO: Add more validation logic here.
        
        // For testing purposes, yield an error if color is black.
        if colorRGBA.r == 0 && colorRGBA.g == 0 && colorRGBA.b == 0 {
            return false
        }
        
        return true
    }
    
    private func updateLightStatus(_ on: Bool, _ color: ColorRGBA, _ luminosity: Double) {
        self.lightStatus.on = on
        self.lightStatus.color = color
        self.lightStatus.luminosity = luminosity
    }
    
    
    /// Convenience method to get the current in coaty-js compatible timestamp.
    ///
    /// - Returns: a timestamp in ms since 1970.
    private func now() -> Double {
        return (Date().timeIntervalSince1970 * 1000).rounded()
    }
}
