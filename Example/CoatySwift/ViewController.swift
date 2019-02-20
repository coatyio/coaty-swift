//
//  ViewController.swift
//  CoatySwift
//
//

import UIKit
import XCGLogger

class ViewController: UIViewController {
    
    let advertiseEventButton = UIButton(frame: CGRect(x: 50, y: 100, width: 50, height: 50))
    let receiveAdvertiseEventButton = UIButton(frame: CGRect(x: 50, y: 200, width: 50, height: 50))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        advertiseEventButton.backgroundColor = .red
        self.view.addSubview(advertiseEventButton)
        advertiseEventButton.addTarget(self, action: #selector(advertiseButtonTapped), for: .touchUpInside)
        
        receiveAdvertiseEventButton.backgroundColor = .blue
        self.view.addSubview(receiveAdvertiseEventButton)
        receiveAdvertiseEventButton.addTarget(self, action: #selector(receiveAdvertisements), for: .touchUpInside)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func advertiseButtonTapped() {
        comManager.publishAdvertiseIdentity(topic: "Unicorn")
    }
    
    @objc func receiveAdvertisements() {
        // Register for receiving of events.
        _ = comManager.observeAdvertise(topic: "Unicorn").subscribe { (advertiseEvent) in
            print("Received Advertise:")
            print(advertiseEvent.element as Any)
        }
    }
    
    

}

