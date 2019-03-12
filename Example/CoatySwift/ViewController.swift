//
//  ViewController.swift
//  CoatySwift
//
//

import UIKit
import XCGLogger
import RxSwift
import CoatySwift

class ViewController: UIViewController {
    
    let redButton = UIButton(frame: CGRect(x: 0, y: 100, width: 350, height: 50))
    let blueButton = UIButton(frame: CGRect(x: 0, y: 200, width: 350, height: 50))
    let yellowButton = UIButton(frame: CGRect(x: 0, y: 300, width: 350, height: 50))
    let greenButton =  UIButton(frame: CGRect(x: 0, y: 400, width: 350, height: 50))
    let purpleButton =  UIButton(frame: CGRect(x: 0, y: 500, width: 350, height: 50))
    let grayButton = UIButton(frame: CGRect(x: 0, y: 600, width: 350, height: 50))
    
    let identity = Component(name: "ControllerIdentity")
    
    let demoObject = DemoObject(coreType: .CoatyObject,
                                objectType: "org.example.coaty.demo-object",
                                objectId: .init(),
                                name: "Demo object message name",
                                message: "Coaty loves you")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*let privateData: [String: Any] = ["so": "private"]
        let dummy = DemoObject(coreType: .Device, objectType: "com.objtype.x", objectId: .init(), name: "some name", message: "henlo world")
        let resolveEvent = ResolveEvent.withObjectAndRelatedObjects(eventSource: identity, object: dummy, relatedObjects: [dummy, dummy], privateData: privateData)

        let encoded = PayloadCoder.encode(resolveEvent)
        print(encoded)
        let decoded: ResolveEvent<CoatyObject> = PayloadCoder.decode(encoded)!
        print(PayloadCoder.encode(decoded))*/
        
        // Establish mqtt connection.
        comManager.startClient()
        
        
        redButton.backgroundColor = .red
        redButton.setTitle("Publish Advertise and Discover/Resolve", for: .normal)
        self.view.addSubview(redButton)
        redButton.addTarget(self, action: #selector(advertiseButtonTapped), for: .touchUpInside)
        
        blueButton.backgroundColor = .blue
        blueButton.setTitle("Publish another component's identity", for: .normal)
        self.view.addSubview(blueButton)
        blueButton.addTarget(self, action: #selector(advertiseNewComponent), for: .touchUpInside)
        
        yellowButton.backgroundColor = .yellow
        yellowButton.setTitle("Channel Events", for: .normal)
        self.view.addSubview(yellowButton)
        yellowButton.setTitleColor(.black, for: .normal)
        yellowButton.addTarget(self, action: #selector(receiveChannelEvents), for: .touchUpInside)
        
        greenButton.backgroundColor = .green
        greenButton.setTitle("Publish Update/Complete", for: .normal)
        self.view.addSubview(greenButton)
        greenButton.addTarget(self, action: #selector(updateCompleteMessage), for: .touchUpInside)
        
        purpleButton.backgroundColor = .purple
        purpleButton.setTitle("Receive Update", for: .normal)
        self.view.addSubview(purpleButton)
        purpleButton.addTarget(self, action: #selector(receiveUpdateMessage), for: .touchUpInside)
        
        grayButton.backgroundColor = .gray
        grayButton.setTitle("Publish over channel", for: .normal)
        self.view.addSubview(grayButton)
        grayButton.addTarget(self, action: #selector(publishChannelEvent), for: .touchUpInside)
    }
    
    @objc func endClient() {
        try! comManager.endClient()
    }
    
    @objc func advertiseNewComponent() {
        let component = Component(name: "SecondControllerIdentity")
        let advertiseEvent = AdvertiseEvent.withObject(eventSource: component, object: component)
        try! comManager.publishAdvertise(advertiseEvent: advertiseEvent, eventTarget: component)
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
        let discoverEvent = DiscoverEvent.withExternalId(eventSource: identity,
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
        
        let updateEvent = UpdateEvent<DemoObject>.withPartial(eventSource: identity, objectId: .init(), changedValues: ["message": "update"])
        
        let observable: Observable<CompleteEvent<DemoObject>> = try! comManager.publishUpdate(event: updateEvent)
        
        _ = observable.subscribe { (completeEvent) in
            if let completeEvent = completeEvent.element {
                print("Received Complete Event:")
                print(completeEvent.json)
            }
        }
    }
    
    @objc func receiveUpdateMessage() {
        let observable: Observable<UpdateEvent<DemoObject>> = try! comManager.observeUpdate(eventTarget: identity)
        
        _ = observable.subscribe({ (updateEvent) in
            if let updateEvent = updateEvent.element {
                print("Received Update Event:")
                print(updateEvent.json)
                
                let payloadObject = updateEvent.eventData
                // HACK!!! making object id lowercase so coaty-js plays nice.
                payloadObject.object?.message = "ANSWER"
                let completeEvent = CompleteEvent.withObject(eventSource: self.identity, object: payloadObject.object!)
                updateEvent.complete(completeEvent: completeEvent)
                
            }
        })
    }

    
    // MARK: - Channel
    
    func channelMessage() {
        let test: Observable<ChannelEvent<CustomCoatyObjectFamily>> = try! comManager.observeChannel(eventTarget: identity, channelId: "123456")
        
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
    }
    
    
}

