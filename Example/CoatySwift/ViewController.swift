//
//  ViewController.swift
//  CoatySwift
//
//

import UIKit
import XCGLogger
import RxSwift

class ViewController: UIViewController {
    
    let advertiseEventButton = UIButton(frame: CGRect(x: 0, y: 100, width: 350, height: 50))
    let receiveEventObjectTypeSame = UIButton(frame: CGRect(x: 0, y: 200, width: 350, height: 50))
    let receiveEventObjectTypeDif = UIButton(frame: CGRect(x: 0, y: 300, width: 350, height: 50))
    let receiveEventCoreTypeSame =  UIButton(frame: CGRect(x: 0, y: 400, width: 350, height: 50))
    let receiveEventCoreTypeDif =  UIButton(frame: CGRect(x: 0, y: 500, width: 350, height: 50))
    let receiveCustomAdvertise = UIButton(frame: CGRect(x: 0, y: 600, width: 350, height: 50))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        advertiseEventButton.backgroundColor = .red
        advertiseEventButton.setTitle("Publish Advertises", for: .normal)
        self.view.addSubview(advertiseEventButton)
        advertiseEventButton.addTarget(self, action: #selector(advertiseButtonTapped), for: .touchUpInside)
        
        receiveEventObjectTypeSame.backgroundColor = .blue
        receiveEventObjectTypeSame.setTitle("Observe Advertises with same objectType", for: .normal)
        self.view.addSubview(receiveEventObjectTypeSame)
        receiveEventObjectTypeSame.addTarget(self, action: #selector(receiveAdvertisementsForObjectType), for: .touchUpInside)
        
        receiveEventObjectTypeDif.backgroundColor = .yellow
        receiveEventObjectTypeDif.setTitle("Observe Advertises with dif. objectType", for: .normal)
        self.view.addSubview(receiveEventObjectTypeDif)
        receiveEventObjectTypeDif.setTitleColor(.black, for: .normal)
        receiveEventObjectTypeDif.addTarget(self, action: #selector(receiveAdvertisementsForDifObjectType), for: .touchUpInside)
        
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
        try? comManager.publishAdvertise(eventTarget: identity, objectType: "SpecialObjectType")
    }
    
    // FIXME: Use proper Component Object for identity.
    // Currently just a garbage object.
    let identity = Advertise(coreType: .CoatyObject, objectType: "SpecialObjectType", objectId: .init(), name: "ControllerIdentity")
    
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
    
    @objc func receiveAdvertisementsForDifObjectType() {
        // FIXME: These two values are currently just garbage values.
        try? _ = comManager.observeAdvertiseWithObjectType(eventTarget: identity, objectType: "WrongObjectType").subscribe({ (advertiseEvent) in
            print("Received Advertise from yellow button:")
            if let advertiseEvent = advertiseEvent.element {
                print(advertiseEvent.json)
            }
        })
    }
    
    @objc func receiveDemoMessageAdvertise() {
        // FIXME: These two values are currently just garbage values.
        do {
            let observable: Observable<AdvertiseEvent<DemoAdvertise>> = try comManager.observeAdvertiseWithObjectType(eventTarget: identity, objectType: "org.example.coaty.demo-message")
            
            _ = observable.subscribe({ (advertiseEvent) in
                if let advertiseEvent = advertiseEvent.element {
                    print(advertiseEvent.json)
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

