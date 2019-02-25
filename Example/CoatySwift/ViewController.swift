//
//  ViewController.swift
//  CoatySwift
//
//

import UIKit
import XCGLogger

class ViewController: UIViewController {
    
    let advertiseEventButton = UIButton(frame: CGRect(x: 0, y: 100, width: 350, height: 50))
    let receiveEventObjectTypeSame = UIButton(frame: CGRect(x: 0, y: 200, width: 350, height: 50))
    let receiveEventObjectTypeDif = UIButton(frame: CGRect(x: 0, y: 300, width: 350, height: 50))
    let receiveEventCoreTypeSame =  UIButton(frame: CGRect(x: 0, y: 400, width: 350, height: 50))
    let receiveEventCoreTypeDif =  UIButton(frame: CGRect(x: 0, y: 500, width: 350, height: 50))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func advertiseButtonTapped() {
        let coatyTopic = "Unicorn"
        comManager.publishAdvertise(topic: coatyTopic, objectType: "SandraObjectType", name: "PublishedName")
    }
    
    @objc func receiveAdvertisementsForObjectType() {
        // Register for receiving of events.
        
        // FIXME: These two values are currently just garbage values, will be incorporated later.
        let coatyTopic = "Unicorn"
        let advertiseCoatyObject = Advertise(coreType: .CoatyObject, objectType: "SandraObjectType", objectId: .init(), name: "SandraName")
        
        _ = comManager.observeAdvertiseWithObjectType(topic: coatyTopic, target: advertiseCoatyObject, objectType: "SandraObjectType")?.subscribe({ (advertiseEvent) in
            print("Received Advertise from blue button:")
            if let advertiseEvent = advertiseEvent.element {
                print(advertiseEvent.json)
            }
            
        })
    }
    
    @objc func receiveAdvertisementsForDifObjectType() {
        // FIXME: These two values are currently just garbage values, will be incorporated later.
        let coatyTopic = "Unicorn"
        let advertiseCoatyObject = Advertise(coreType: .CoatyObject, objectType: "WrongObjectType", objectId: .init(), name: "SandraName")
        
        _ = comManager.observeAdvertiseWithObjectType(topic: coatyTopic, target: advertiseCoatyObject, objectType: "WrongObjectType")?.subscribe({ (advertiseEvent) in
            print("Received Advertise from yellow button:")
            if let advertiseEvent = advertiseEvent.element {
                print(advertiseEvent.json)
            }
            
        })
    }
    
    @objc func receiveAdvertisementsForCoreType() {
        // Register for receiving of events.
        
        // FIXME: These two values are currently just garbage values, will be incorporated later.
        let coatyTopic = "Unicorn"
        let advertiseCoatyObject = Advertise(coreType: .CoatyObject, objectType: "SandraObjectType", objectId: .init(), name: "SandraName")
        
        _ = comManager.observeAdvertiseWithCoreType(topic: coatyTopic, target: advertiseCoatyObject, coreType: .Component)?.subscribe({ (advertiseEvent) in
            print("Received Advertise from green button:")
            if let advertiseEvent = advertiseEvent.element {
                print(advertiseEvent.json)
            }
            
        })
    }
    
    @objc func receiveAdvertisementsForDifCoreType() {
        // FIXME: These two values are currently just garbage values, will be incorporated later.
        let coatyTopic = "Unicorn"
        let advertiseCoatyObject = Advertise(coreType: .CoatyObject, objectType: "WrongObjectType", objectId: .init(), name: "SandraName")
        
        _ = comManager.observeAdvertiseWithCoreType(topic: coatyTopic, target: advertiseCoatyObject, coreType: .IoActor)?.subscribe({ (advertiseEvent) in
            print("Received Advertise from purple button:")
            if let advertiseEvent = advertiseEvent.element {
                print(advertiseEvent.json)
            }
            
        })
    }
    
    

}

