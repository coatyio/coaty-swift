//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  AppDelegate.swift
//  CoatySwift
//
//

import UIKit
import CoatySwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// Save a reference of your container in the app delegate to
    /// make sure it stays alive during the entire life-time of the app.
    var container: Container<ExampleObjectFamily>?
    let brokerIp = "127.0.0.1"
    let brokerPort = 1883

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        launchContainer()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Shutdown container in order to trigger a graceful deadvertise of all advertised components.
        container?.shutdown();
    }
    
    // MARK: - Coaty Container setup methods.

    /// This method sets up the Coaty container necessary to run our application.
    private func launchContainer() {
        
        // Instantiate controllers.
        let components = Components(controllers: [
            "ExampleControllerPublish": ExampleControllerPublish<ExampleObjectFamily>.self,
            "ExampleControllerObserve": ExampleControllerObserve<ExampleObjectFamily>.self
            ])
        
        // Create a configuration.
        guard let configuration = createExampleConfiguration() else {
            print("Invalid configuration! Please check your options.")
            return
        }
        
        // Resolve everything!
        container = Container.resolve(components: components,
                                      configuration: configuration,
                                      objectFamily: ExampleObjectFamily.self)

    }
    

    /// This method creates an exemplary Coaty configuration. You can use it as a basis for your
    /// application.
    private func createExampleConfiguration() -> Configuration? {
        return try? .build { config in
            
            // This part defines optional common options shared by all container components.
            config.common = CommonOptions()
            
            // Adjusts the logging level of CoatySwift messages, which is especially
            // helpful when you want to debug applications.
            config.common?.logLevel = .info
            
            // You can also add extra information to your configuration in the form of a
            // [String: String] dictionary.
            config.common?.extra = ["ContainerVersion": "0.0.1"]
            
            // Define the communication-related options, such as the IP address of your broker and
            // the port it exposes, and your own MQTT client Id. Also, make sure
            // to immediately connect with the broker, indicated by `shouldAutoStart: true`.
            let mqttClientOptions = MQTTClientOptions(host: brokerIp,
                                                      port: UInt16(brokerPort))
            
            config.communication = CommunicationOptions(mqttClientOptions: mqttClientOptions,                                              identity: ["name": "ExampleClient"],
                                                        shouldAutoStart: true)
            
            // The communicationManager will advertise its identity upon connection to the
            // MQTT broker.
            config.communication?.shouldAdvertiseIdentity = true
        }
    }
    
    
}

