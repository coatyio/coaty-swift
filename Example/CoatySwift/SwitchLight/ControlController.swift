//
//  ControlController.swift
//  CoatySwift_Example
//
//

import CoatySwift
import Foundation
import RxSwift

enum SwitchLightOperations: String {
    case lightControlOperation = "coaty.examples.remoteops.switchLight"
}

enum SwitchLightObjectFamily: String, ObjectFamily {
    case light = "coaty.examples.remoteops.Light"
    case lightContext = "coaty.examples.remoteops.LightContext"
    case lightStatus = "coaty.examples.remoteops.LightStatus"
    
    func getType() -> AnyObject.Type {
        switch self {
        case .light:
            return Light.self
        case .lightStatus:
            return LightStatus.self
        case .lightContext:
            return LightContext.self
        }
    }
}

class ColorRGBA: Codable {
    private(set) public var r = 0
    private(set) public var g = 0
    private(set) public var b = 0
    private(set) public var a = 0.0
    
    init(r: Int, g: Int, b: Int, a: Double) {
        // TODO: Validation. Each value needs to be 0 <= value<= 255
        self.r = r
        self.g = g
        self.b = b
        
        // Alpha between 0..1
        self.a = a
    }
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.r = try container.decode(Int.self)
        self.g = try container.decode(Int.self)
        self.b = try container.decode(Int.self)
        self.a = try container.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(r)
        try container.encode(g)
        try container.encode(b)
        try container.encode(a)
    }
}

/**
 * Models the current status of a light including on-off, color-change and
 * luminosity-adjust features as a Coaty object type. Its `parentObjectId`
 * property refers to the associated `Light` object.
 */
class LightStatus: CoatyObject {
    /**
     * Determines whether the light is currently switched on or off.
     */
    var on: Bool;
    
    /** The current luminosity level of the light, a number between 0 (0%) and 1
     * (100%).
     */
    var luminosity: Double;
    
    /**
     * The current color of the light as an rgba tuple.
     */
    var color: ColorRGBA;
    
    init(on: Bool, luminosity: Double, color: ColorRGBA) {
        self.on = on
        self.luminosity = luminosity
        self.color = color
        super.init(coreType: .CoatyObject, objectType: SwitchLightObjectFamily.lightStatus.rawValue, objectId: .init(), name: "TODO")
    }
    
    enum CodingKeys: String, CodingKey {
        case on
        case luminosity
        case color
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.on = try container.decode(Bool.self, forKey: .on)
        self.luminosity =  try container.decode(Double.self, forKey: .luminosity)
        self.color = try container.decode(ColorRGBA.self, forKey: .color)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(on, forKey: .on)
        try container.encode(luminosity, forKey: .luminosity)
        try container.encode(color, forKey: .color)
    }
}

/**
 * Models a lighting source which can change color and adjust luminosity as a
 * Coaty object type. The light source status is represented by a separate object type
 * `LightStatus`, which is associated with its light by the `parentObjectId`
 * relationship.
 */
class Light: CoatyObject {
    /**
     * Determines whether the light is currently defect. The default value is
     * `false`.
     */
    var isDefect: Bool
    
    init(isDefect: Bool = false) {
        self.isDefect = isDefect
        super.init(coreType: .CoatyObject, objectType: SwitchLightObjectFamily.light.rawValue, objectId: .init(), name: "TODO")
    }
    
    // TODO: Codable
    
    enum CodingKeys: String, CodingKey {
        case isDefect
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isDefect = try container.decode(Bool.self, forKey: .isDefect)
        try super.init(from: decoder)
    }
}

/**
 * Represents execution information returned with a remote light control
 * operation.
 */
class LightExecutionInfo: Codable {
    
    /** Object Id of the Light object that has been controlled. */
    var lightId: CoatyUUID
    
    /**
     * The timestamp in UTC microseconds when the light control operation has
     * been triggered.
     */
    var triggerTime: Double
    
    init(lightId: CoatyUUID, triggerTime: Double) {
        self.lightId = lightId
        self.triggerTime = triggerTime
    }
}

/**
 * A Coaty object type that represents the environmental context of a light. The
 * light context defines a building number, a floor number, and a room number
 * indicating where the light is physically located. To control an individual
 * light, the light's ID is also defined in the context.
 */
class LightContext: CoatyObject {
    
    
    init(lightId: CoatyUUID = .init(), building: Int, floor: Int, room: Int) {
        self.lightId = lightId
        self.building = building
        self.floor = floor
        self.room = room
        super.init(coreType: .CoatyObject, objectType: SwitchLightObjectFamily.lightContext.rawValue, objectId: .init(), name: "TODO")
    }
    
    // The object Id of the associated light.
    var lightId: CoatyUUID;
    
    // The number of the building in which this light is located.
    var building: Int
    
    // The number of the floor on which the light is located.
    var floor: Int
    
    // The number of the room on which the light is located.
    var room: Int
    
    // TODO: Codable
    
    enum CodingKeys: String, CodingKey {
        case lightId
        case building
        case floor
        case room
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lightId = try container.decode(CoatyUUID.self, forKey: .lightId)
        self.building = try container.decode(Int.self, forKey: .building)
        self.floor = try container.decode(Int.self, forKey: .floor)
        self.room = try container.decode(Int.self, forKey: .room)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lightId, forKey: .lightId)
        try container.encode(building, forKey: .building)
        try container.encode(floor, forKey: .floor)
        try container.encode(room, forKey: .room)
    }
}

class ControlController<Family: ObjectFamily>: Controller<Family> {
    
    func switchLights(contextFilter: ContextFilter,
                      onOff: Bool,
                      luminosity: Double,
                      rgba: ColorRGBA,
                      switchTime: Double) {
        
        let parameters: [String: AnyCodable] = ["on": .init(onOff),
                                                "color": .init(rgba),
                                                "luminosity": .init(luminosity),
                                                "switchTime": .init(switchTime)]
        
        let callEvent = self.eventFactory.CallEvent.with(eventSource: self.identity,
                                                         operation: SwitchLightOperations.lightControlOperation.rawValue,
                                                         parameters: parameters,
                                                         filter: contextFilter)
        
        _ = try? self.communicationManager.publishCall(event: callEvent).subscribe { event in
            guard let returnEvent = event.element else {
                // TODO: ???
                print("No return event found.")
                return
            }
            
            // TODO: pretty print
            print(returnEvent.json)
        }
    }
}

protocol LightControlDelegate {
    func switchLight(_ on: Bool, _ color: ColorRGBA, _ luminosity: Double)
}

class LightController<Family: ObjectFamily>: Controller<Family> {
    public var delegate: LightControlDelegate?

    private var light: Light!
    private var lightStatus: LightStatus!
    private var lightContext: LightContext!
    
    
    override func onInit() {
        super.onInit()
        
        self.light = Light(isDefect: false)
        self.lightStatus = LightStatus(on: false,
                                       luminosity: 0,
                                       color: ColorRGBA(r: 255, g: 255, b: 0, a: 1.0))
        self.lightStatus.parentObjectId = self.light.parentObjectId
        
        self.lightContext = LightContext(building: 33, floor: 4, room: 62)
    }
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        observeCallEvents()
    }
    
    /// TODO: Dangerous force unwrap.
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
    
    private func observeCallEvents() {
        let lightSwitchOperation = SwitchLightOperations.lightControlOperation.rawValue
        try? self.communicationManager.observeCall(eventTarget: self.identity, operationId: lightSwitchOperation)
            .subscribe{ event in
                guard let callEvent = event.element else {
                    print("No element found.")
                    return
                }
                
                let on = callEvent.eventData.getParameterByName(name: "on") as! Bool
                let color = callEvent.eventData.getParameterByName(name: "color") as! [Any]
                let colorRGBA = self.createColorRGBA(color)
                let luminosity = self.toDouble(callEvent.eventData.getParameterByName(name: "luminosity")!)
                let switchTime = callEvent.eventData.getParameterByName(name: "switchTime") as! Int
                
                if !self.validateSwitchOpParams(on, colorRGBA, luminosity, switchTime) {
                    let error = ReturnError(code: .invalidParameters, message: .invalidParameters)
                    let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                        "triggerTime": Date().timeIntervalSince1970]
                    let event = self.eventFactory.ReturnEvent.withError(eventSource: self.identity,
                                                                        error: error,
                                                                        executionInfo: executionInfo)
                    callEvent.returned(returnEvent: event)
                    return
                }
                
                if self.light.isDefect {
                    let error = ReturnError(code: 1, message: "Light is defect")
                    let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                        "triggerTime": Date().timeIntervalSince1970]
                    let event = self.eventFactory.ReturnEvent.withError(eventSource: self.identity,
                                                                         error: error,
                                                                         executionInfo: executionInfo)
                    callEvent.returned(returnEvent: event)
                    return
                }
                
                self.updateLightStatus(on, colorRGBA, luminosity)
                self.delegate?.switchLight(on, colorRGBA, luminosity)
                
                let result: ReturnResult = .init(self.lightStatus!.on)
                let executionInfo: ExecutionInfo = ["lightId": self.light.objectId,
                                                    "triggerTime": Date().timeIntervalSince1970]
                let event = self.eventFactory.ReturnEvent.withResult(eventSource: self.identity,
                                                                     result: result,
                                                                     executionInfo: executionInfo)
                callEvent.returned(returnEvent: event)
            }.disposed(by: disposeBag)
    }
    
    private func validateSwitchOpParams(_ on: Bool, _ colorRGBA: ColorRGBA, _ luminosity: Double, _ switchTime: Int) -> Bool {
        
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
}

class SwitchLightViewController: UIViewController {
    
    let brokerIp = "192.168.1.23"
    let brokerPort = 1883
    private var lightView: UIView?
    
    override func viewDidLoad() {
        // Setup view.
        self.view.backgroundColor = .white
        
        // Instantiate controllers.
        let components = Components(controllers: [
            "ControlController": ControlController<SwitchLightObjectFamily>.self,
            "LightController": LightController<SwitchLightObjectFamily>.self
            ])
        
        guard let configuration = createSwitchLightConfiguration() else {
            print("Invalid configuration! Please check your options.")
            return
        }
        
        // Resolve your components with the given configuration and get your CoatySwift
        // application up and running.
        // Important: You need to specify clearly which Object Family you are going to use.
        // More details about what an ObjectFamily does can be found
        // in `SwitchLightObjectFamily.swift`.
        self.container = Container.resolve(components: components,
                              configuration: configuration,
                              objectFamily: SwitchLightObjectFamily.self)

        let switchButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        switchButton.backgroundColor = .red
        switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        self.view.addSubview(switchButton)
        
        let lightView = UIView(frame: CGRect(x: 100, y: 300, width: 300, height: 100))
        self.lightView = lightView
        lightView.backgroundColor = .clear
        self.view.addSubview(lightView)
        
        // Set delegate.
        guard let lightController = container?.getController(name: "LightController") as? LightController else {
            print("Could not load LightController")
            return
        }
        
        lightController.delegate = self
    }
    
    private var container: Container<SwitchLightObjectFamily>?
    
    @objc func switchButtonTapped() {
        print("tapped")
        guard let controlController = self.container?.getController(name: "ControlController") as? ControlController<SwitchLightObjectFamily> else {
            print("Controller not found.")
            return
        }
        
        let contextFilter: ContextFilter = try! .buildWithConditions {
            let buildingFilter = ContextFilterCondition(property: .init("building"),
                                                    expression: .init(filterOperator: .In, op1: 33))
            let floorFilter = ContextFilterCondition(property: .init("floor"),
                                                    expression: .init(filterOperator: .In, op1: 4))
            let roomFilter = ContextFilterCondition(property: .init("room"),
                                                   expression: .init(filterOperator: .In, op1: 62))
            
            $0.conditions = ObjectFilterConditions.init(and: [buildingFilter, floorFilter, roomFilter])
        }
        
        let colorRGBA = ColorRGBA(r: Int.random(in: 0..<255),
                                  g: Int.random(in: 0..<255),
                                  b: Int.random(in: 0..<255),
                                  a: 1)
        
        controlController.switchLights(contextFilter: contextFilter,
                                       onOff: true,
                                       luminosity: 0.75,
                                       rgba: colorRGBA,
                                       switchTime: 0)
    }
    
    /// Creates a basic configuration file for your HelloWorld application.
    private func createSwitchLightConfiguration() -> Configuration? {
        return try? .build { config in
          
            // Adjusts the logging level of CoatySwift messages.
            config.common = CommonOptions()
            config.common?.logLevel = .info
            
            // Here, we define that the ControlController should advertise its identity as soon as
            // it gets online.
            config.controllers = ControllerConfig(
                controllerOptions: [
                    "ControlController": ControllerOptions(shouldAdvertiseIdentity: true),
                    "LightController": ControllerOptions(shouldAdvertiseIdentity: true)
                ])
            
            // Define the communication-related options, such as the Ip address of your broker and
            // the port it exposes, and your own mqtt client Id. Also, make sure
            // to immediately connect with the broker.
            let brokerOptions = BrokerOptions(host: brokerIp,
                                              port: UInt16(brokerPort),
                                              clientId: "\(UUID.init())")
            config.communication = CommunicationOptions(brokerOptions: brokerOptions,
                                                        shouldAutoStart: true)
            
            // The communicationManager will also advertise its identity upon connection to the
            // mqtt broker.
            config.communication?.shouldAdvertiseIdentity = true
            
        }
    }
}

extension SwitchLightViewController: LightControlDelegate {
    func switchLight(_ on: Bool, _ color: ColorRGBA, _ luminosity: Double) {

        guard let light = self.lightView else {
            return
        }
        
        // Switch light on or off.
        light.isHidden = !on
        
        // Adjust light color.
        let lightColor = UIColor(red: CGFloat(color.r) / 255.0,
                                 green: CGFloat(color.g) / 255.0,
                                 blue: CGFloat(color.b) / 255.0,
                                 alpha: CGFloat(color.a))
        light.backgroundColor = lightColor
    }
    
    
}
