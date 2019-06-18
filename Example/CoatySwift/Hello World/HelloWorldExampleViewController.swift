// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  HelloWorldExampleViewController.swift
//  CoatySwift_Example
//

import Foundation
import UIKit
import RxSwift
import CoatySwift

/// This example view controller shows how you can set up a basic CoatySwift bootstrap application.
class HelloWorldExampleViewController: UIViewController {
    
    let enableSSL = false
    let brokerIp = "192.168.2.190"
    let brokerPort = 1883
    
    override func viewDidLoad() {
        setupView()
        
        // Instantiate controllers.
        let components = Components(controllers: ["TaskController": TaskController<HelloWorldObjectFamily>.self])
        
        guard let configuration = createHelloWorldConfiguration() else {
            print("Invalid configuration! Please check your options.")
            return
        }
        
        // Resolve your components with the given configuration and get your CoatySwift
        // application up and running.
        // Important: You need to specify clearly which Object Family you are going to use.
        // More details about what an ObjectFamily does can be found
        // in `HelloWorldObjectFamily.swift`.
        _ = Container.resolve(components: components,
                              configuration: configuration,
                              objectFamily: HelloWorldObjectFamily.self)
        
    }
    
    // MARK: - Setup methods.
    
    private func setupView() {
        self.view.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        view.addSubview(label)
        label.center = view.center
    }
    
    
    /// Creates a basic configuration file for your HelloWorld application.
    private func createHelloWorldConfiguration() -> Configuration? {
        return try? .build { config in
            
            // This part defines the associated user (aka the identity associated with this client).
            config.common = CommonOptions()
            config.common?.associatedUser = User(name: "ClientUser",
                                                 names: ScimUserNames(familyName: "ClientUser",
                                                                      givenName: ""),
                                                 objectType: CoatyObjectFamily.user.rawValue,
                                                 objectId: CoatyUUID())
            
            // Adjusts the logging level of CoatySwift messages.
            config.common?.logLevel = .debug
            
            // Here, we define that the TaskController should advertise its identity as soon as
            // it gets online.
            config.controllers = ControllerConfig(
                controllerOptions: ["TaskController": ControllerOptions(shouldAdvertiseIdentity: true)])
            
            // Define the communication-related options, such as the Ip address of your broker and
            // the port it exposes, and your own mqtt client Id. Also, make sure
            // to immediately connect with the broker.
            let mqttClientOptions = MQTTClientOptions(host: brokerIp,
                                              port: UInt16(brokerPort),
                                              clientId: "\(UUID.init())",
                                              enableSSL: enableSSL)
            config.communication = CommunicationOptions(mqttClientOptions: mqttClientOptions,
                                                        shouldAutoStart: true)
            
            // The communicationManager will also advertise its identity upon connection to the
            // mqtt broker.
            config.communication?.shouldAdvertiseIdentity = true
            
        }
    }
}
