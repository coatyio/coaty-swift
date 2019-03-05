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
    
    let advertiseEventButton = UIButton(frame: CGRect(x: 0, y: 100, width: 350, height: 50))
    let receiveEventObjectTypeSame = UIButton(frame: CGRect(x: 0, y: 200, width: 350, height: 50))
    let channelEventButton = UIButton(frame: CGRect(x: 0, y: 300, width: 350, height: 50))
    let receiveEventCoreTypeSame =  UIButton(frame: CGRect(x: 0, y: 400, width: 350, height: 50))
    let receiveEventCoreTypeDif =  UIButton(frame: CGRect(x: 0, y: 500, width: 350, height: 50))
    let receiveCustomAdvertise = UIButton(frame: CGRect(x: 0, y: 600, width: 350, height: 50))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*let privateData: [String: Any] = ["so": "private"]
        let dummy = DemoObject(coreType: .Device, objectType: "com.objtype.x", objectId: .init(), name: "some name", message: "henlo world")
        let resolveEvent = ResolveEvent.withObjectAndRelatedObjects(eventSource: identity, object: dummy, relatedObjects: [dummy, dummy], privateData: privateData)

        let encoded = PayloadCoder.encode(resolveEvent)
        print(encoded)
        let decoded: ResolveEvent<CoatyObject> = PayloadCoder.decode(encoded)!
        print(PayloadCoder.encode(decoded))*/
        
        
        advertiseEventButton.backgroundColor = .red
        advertiseEventButton.setTitle("Publish Advertises", for: .normal)
        self.view.addSubview(advertiseEventButton)
        advertiseEventButton.addTarget(self, action: #selector(advertiseButtonTapped), for: .touchUpInside)
        
        receiveEventObjectTypeSame.backgroundColor = .blue
        receiveEventObjectTypeSame.setTitle("Observe Advertises with same objectType", for: .normal)
        self.view.addSubview(receiveEventObjectTypeSame)
        receiveEventObjectTypeSame.addTarget(self, action: #selector(receiveAdvertisementsForObjectType), for: .touchUpInside)
        
        channelEventButton.backgroundColor = .yellow
        channelEventButton.setTitle("Channel Events", for: .normal)
        self.view.addSubview(channelEventButton)
        channelEventButton.setTitleColor(.black, for: .normal)
        channelEventButton.addTarget(self, action: #selector(receiveChannelEvents), for: .touchUpInside)
        
        receiveEventCoreTypeSame.backgroundColor = .green
        receiveEventCoreTypeSame.setTitle("Observe Advertises with same coreType", for: .normal)
        self.view.addSubview(receiveEventCoreTypeSame)
        receiveEventObjectTypeSame.addTarget(self, action: #selector(receiveAdvertisementsForCoreType), for: .touchUpInside)
        
        receiveEventCoreTypeDif.backgroundColor = .purple
        receiveEventCoreTypeDif.setTitle("Observe Advertises with dif. coreType", for: .normal)
        self.view.addSubview(receiveEventCoreTypeDif)
        receiveEventCoreTypeDif.addTarget(self, action: #selector(receiveAdvertisementsForDifCoreType), for: .touchUpInside)
        
        receiveCustomAdvertise.backgroundColor = .gray
        receiveCustomAdvertise.setTitle("Observe Demo-Advertises", for: .normal)
        self.view.addSubview(receiveCustomAdvertise)
        receiveCustomAdvertise.addTarget(self, action: #selector(receiveDemoMessageAdvertise), for: .touchUpInside)
    }
    
    @objc func advertiseButtonTapped() {
        
        let demoMessage = DemoObject(coreType: .CoatyObject, objectType: "com.demo.obj", objectId: .init(), name: "NAME", message: "hiii")
        let advertiseEvent = AdvertiseEvent.withObject(eventSource: identity, object: demoMessage)
        try? comManager.publishAdvertise(advertiseEvent: advertiseEvent, eventTarget: identity)
        
        let discoverEvent = DiscoverEvent.withExternalId(eventSource: identity, externalId: "asdf")
        let observable: Observable<ResolveEvent<DemoObject>> = try! comManager.publishDiscover(event: discoverEvent)
            
            _ = observable.subscribe(onNext: { (resolveEvent) in
            print("Received Resolve:")
                print(resolveEvent.json)
        }, onError: { error in print(error)}, onCompleted: nil, onDisposed: nil)
        
    }
    
    // FIXME: Use proper Component Object for identity.
    // Currently just a garbage object.
    let identity = Component(coreType: .Component, objectType: "SpecialObjectType", objectId: .init(), name: "ControllerIdentity")
    
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
    
    @objc func receiveChannelEvents() {
        let test: Observable<ChannelEvent<DemoObject>> = try! comManager.observeChannel(eventTarget: identity, channelId: "123456")
            test.subscribe({ (channelEvent) in
            print("Received Channel from yellow button:")
            if let channelEvent = channelEvent.element {
                print(channelEvent.json)
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

