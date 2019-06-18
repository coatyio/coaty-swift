// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  ViewController.swift
//  CoatySwift
//
//

import UIKit
import XCGLogger
import RxSwift
import CoatySwift


/*class ControllerA: Controller {
    
    // MARK: - Attributes.
    
    private var communicationManager: CommunicationManager<CustomCoatyObjectFamily>?
    private var disposeBag = DisposeBag()
    private var observable: Observable<ChannelEvent<CustomCoatyObjectFamily>>? = nil
    
    // MARK: - Controller lifecycle methods.
    
    override func onInit() {
        print("onInit() \(self.identity.name) \(self.identity.objectId)")
    }
    
    override func onDispose() {
        print("onDispose()")
    }
    
    override func onContainerResolved(container: Container) {
        print("onContainerResolved()")
    }
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        communicationManager = self.getCommunicationManager()
        
        publishUpdate()
    }
    
    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        print("onCommunicationManagerStopping()")
    }
    
    // MARK: - Controller methods.
    
    private func publishUpdate() {
        
        /*
        let observable = Observable<Int>.create { (observer) -> Disposable in
            observer.onNext(1)
            let cancel = Disposables.create {
         
                print("Cleaned up")
            }
            return cancel
        }
        
        let sub = observable.subscribe {
            print($0.element)
        
        }
        
        sub.dispose()
        
        guard let comManager = communicationManager else {
            // CommunicationManager could not be fetched.
            return
        }
        
        // Create new update event.
        let updateEvent = UpdateEvent<CustomCoatyObjectFamily>.withPartial(eventSource: self.identity,
                                                                          objectId: .init(),
                                                                          changedValues: ["Value1": 123, "Value2": "a String"])

        
        // Publish update and subscribe to the complete event.
        observable = try? comManager.observeChannel(eventTarget: self.identity, channelId: "123456")
 */
        
        /*observable!.subscribe {
            
            guard let completeEvent = $0.element else {
                // Got an error instead of the expected element.
                return
            }
            
            // ... do something with the complete event.
            print(completeEvent.json)
        }*/
        
        
        /*// Insert timer for unsubscribing after certain time
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: .init(5), repeats: true, block: {_ in
                // subscription?.dispose()
                self.observable?.subscribe({ (event) in
                    print(event.element?.json)
                })
            })
        } else {
            // Fallback on earlier versions
        }*/
        let firstObs = self.observable?.subscribe({ (event) in
            print("first subscriber ")
        })
        
        let secondObs = self.observable?.subscribe({ (event) in
            print("second subscriber ")
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            firstObs?.dispose()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            secondObs?.dispose()
        }
        
    }
    
    /*
    private func updateCompleteMessage() {
        
        guard let comManager = communicationManager else {
            // CommunicationManager could not be fetched.
            return
        }
        
        let updateEvent = UpdateEvent<CustomCoatyObjectFamily>.withPartial(eventSource: identity, objectId: .init(), changedValues: ["message": "update"])
        let observable: Observable<CompleteEvent<CustomCoatyObjectFamily>> = try! comManager.publishUpdate(event: updateEvent)
        _ = observable.subscribe { (completeEvent) in
            if let completeEvent = completeEvent.element {
                print("Received Complete Event:")
                print(completeEvent.json)
            }
        }
    }*/
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let components = Components(controllers: ["CONA": ControllerA.self/*,
                                                  "CONB": ControllerA.self*/])
        
        
        let configuration: Configuration = try! .build { config in
            config.common = CommonOptions()
            config.controllers = ControllerConfig(controllerOptions: ["CONA": ControllerOptions(shouldAdvertiseIdentity: true),
                                                                      "CONB": ControllerOptions(shouldAdvertiseIdentity: true)])
            
            let brokerOptions = BrokerOptions(host: "192.168.1.120", port: 1883, clientId: "\(UUID.init())")
            config.communication = CommunicationOptions(brokerOptions: brokerOptions, shouldAutoStart: true)
            config.communication?.shouldAdvertiseIdentity = true
        }
        
        let container = Container.resolve(components: components,
                                          configuration: configuration,
                                          objectFamily: CustomCoatyObjectFamily.self)
        
        // Adding a controller at runtime.
        /*try? container.registerController(name: "CONC", controllerType: ControllerA.self,
                                     config: ControllerConfig(controllerOptions: [
                                        "CONC": ControllerOptions(shouldAdvertiseIdentity: true)
                                        ]))*/
    }
    
    
    let redButton = UIButton(frame: CGRect(x: 0, y: 100, width: 350, height: 50))
    let blueButton = UIButton(frame: CGRect(x: 0, y: 200, width: 350, height: 50))
    let yellowButton = UIButton(frame: CGRect(x: 0, y: 300, width: 350, height: 50))
    let greenButton =  UIButton(frame: CGRect(x: 0, y: 400, width: 350, height: 50))
    let purpleButton =  UIButton(frame: CGRect(x: 0, y: 500, width: 350, height: 50))
    let grayButton = UIButton(frame: CGRect(x: 0, y: 600, width: 350, height: 50))
    let helloWorldButton = UIButton(frame: CGRect(x: 0, y: 700, width: 350, height: 50))
    
    let identity = Component(name: "ControllerIdentity")
    
    let demoObject = DemoObject(coreType: .CoatyObject,
                                objectType: "org.example.coaty.demo-object",
                                objectId: .init(),
                                name: "Demo object message name",
                                message: "Coaty loves you")
    
    /*@objc func endClient() {
     try! comManager.endClient()
     }
     
     @objc func advertiseNewComponent() {
     let component = Component(name: "SecondControllerIdentity")
     let advertiseEvent = AdvertiseEvent.withObject(eventSource: component, object: component)
     try! comManager.publishAdvertise(advertiseEvent: advertiseEvent, eventTarget: component)
     }
     
     @objc func helloWorldExample() {
     self.present(HelloWorldExampleViewController(), animated: true)
     }
     
     @objc func advertiseButtonTapped() {
     advertiseMessage()
     discoverResolveMessage()
     }
     
     
     @objc func receiveChannelEvents() {
     channelMessage()
     }
     
     @objc func publishChannelEvent() {
     let channelEvent = ChannelEvent<CustomCoatyObjectFamily>.withObject(eventSource: identity, channelId: "123456", object: demoObject)
     try! comManager.publishChannel(event: channelEvent)
     }
     
     // MARK: Advertise
     
     func advertiseMessage() {
     let advertiseEvent = AdvertiseEvent.withObject(eventSource: identity,
     object: demoObject)
     
     try? comManager.publishAdvertise(advertiseEvent: advertiseEvent,
     eventTarget: identity)
     }
     
     // MARK: Discover Resolve.
     
     func discoverResolveMessage() {
     let discoverEvent = DiscoverEvent<CustomCoatyObjectFamily>.withExternalId(eventSource: identity,
     externalId: "test-id")
     
     let observable: Observable<ResolveEvent<CustomCoatyObjectFamily>> = try! comManager.publishDiscover(event: discoverEvent)
     
     _ = observable.subscribe { (resolveEvent) in
     if let resolveEvent = resolveEvent.element {
     print("Received Resolve Event:")
     print(resolveEvent.json)
     }
     }
     }
     
     // MARK: Update Complete.
     
     @objc func updateCompleteMessage() {
     // FULL UPDATE:
     // let updateEvent = UpdateEvent.withFull(eventSource: identity, object: demoObject)
     
     let updateEvent = UpdateEvent<CustomCoatyObjectFamily>.withPartial(eventSource: identity, objectId: .init(), changedValues: ["message": "update"])
     
     let observable: Observable<CompleteEvent<CustomCoatyObjectFamily>> = try! comManager.publishUpdate(event: updateEvent)
     
     _ = observable.subscribe { (completeEvent) in
     if let completeEvent = completeEvent.element {
     print("Received Complete Event:")
     print(completeEvent.json)
     }
     }
     }
     
     
     // MARK: - Receive Discover
     @objc func receiveDiscoverMessage() {
     let observable: Observable<DiscoverEvent<CustomCoatyObjectFamily>> = try! comManager.observeDiscover(eventTarget: identity)
     
     _ = observable.subscribe({ (discoverEvent) in
     if let discoverEvent = discoverEvent.element {
     print("Received Discover Event:")
     print(discoverEvent.json)
     self.demoObject.externalId = discoverEvent.eventData.object.externalId
     self.demoObject.message = "DISCOVER ANSWER"
     let resolveEvent = ResolveEvent<CustomCoatyObjectFamily>.withObject(eventSource: self.identity,
     object: self.demoObject)
     discoverEvent.resolve(resolveEvent: resolveEvent)
     }
     })
     
     }
     
     // MARK: - Receive Update
     @objc func receiveUpdateMessage() {
     let observable: Observable<UpdateEvent<CustomCoatyObjectFamily>> =
     try! comManager.observeUpdate(eventTarget: identity)
     
     _ = observable.subscribe({ (updateEvent) in
     if let updateEvent = updateEvent.element {
     print("Received Update Event:")
     print(updateEvent.json)
     
     if updateEvent.eventData.isPartialUpdate {
     
     if let demoObject = updateEvent.eventData.object! as? DemoObject {
     demoObject.message = "UPDATE ANSWER"
     let completeEvent = CompleteEvent<CustomCoatyObjectFamily>
     .withObject(eventSource: self.identity, object: demoObject)
     updateEvent.complete(completeEvent: completeEvent)
     }
     }
     }
     })
     }
     
     
     // MARK: - Channel
     func channelMessage() {
     let test: Observable<ChannelEvent<CustomCoatyObjectFamily>> =
     try! comManager.observeChannel(eventTarget: identity, channelId: "123456")
     
     _ = test.subscribe({ (channelEvent) in
     if let channelEvent = channelEvent.element {
     print("Received Channel Event:")
     print(channelEvent.json)
     }
     })
     }
     
     // MARK: - Receive advertisements for object types.
     
     @objc func receiveAdvertisementsForObjectType() {
     // FIXME: These two values are currently just garbage values.
     
     try? _ = comManager.observeAdvertiseWithObjectType(eventTarget: identity, objectType: "SpecialObjectType").subscribe({ (advertiseEvent) in
     print("Received Advertise from blue button:")
     if let advertiseEvent = advertiseEvent.element {
     print(advertiseEvent.json)
     }
     })
     }
     
     @objc func receiveDemoMessageAdvertise() {
     // FIXME: These two values are currently just garbage values.
     do {
     let observable: Observable<AdvertiseEvent<DemoObject>> = try comManager.observeAdvertiseWithObjectType(eventTarget: identity, objectType: "org.example.coaty.demo-message")
     
     _ = observable.subscribe({ (advertiseEvent) in
     if let advertiseEvent = advertiseEvent.element {
     print(advertiseEvent.json)
     let encodedAdvertiseEvent = PayloadCoder.encode(advertiseEvent)
     print(encodedAdvertiseEvent)
     }
     })
     } catch  {
     print("Cannot parse as DemoMessageAdvertise")
     }
     }
     
     // MARK: - Receive advertisements for core types.
     
     @objc func receiveAdvertisementsForCoreType() {
     // FIXME: These two values are currently just garbage values.
     try? _ = comManager.observeAdvertiseWithCoreType(eventTarget: identity, coreType: .Component).subscribe({ (advertiseEvent) in
     print("Received Advertise from green button:")
     if let advertiseEvent = advertiseEvent.element {
     print(advertiseEvent.json)
     }
     })
     }
     
     @objc func receiveAdvertisementsForDifCoreType() {
     // FIXME: These two values are currently just garbage values.
     try? _ = comManager.observeAdvertiseWithCoreType(eventTarget: identity, coreType: .IoActor).subscribe({ (advertiseEvent) in
     print("Received Advertise from purple button:")
     if let advertiseEvent = advertiseEvent.element {
     print(advertiseEvent.json)
     }
     })
     }*/
    
}
*/
