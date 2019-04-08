//
//  HelloWorldExampleViewController.swift
//  CoatySwift_Example
//

import Foundation
import UIKit
import RxSwift
import CoatySwift

class HelloWorldExampleViewController: UIViewController {
  /*
    var identity =  Component(name: "HelloWorldCoatySwiftClient")
    var disposeBag = DisposeBag()
    var operatingState: Observable<OperatingState>?
    
    override func viewDidLoad() {
        setupView()
        
        // Establish mqtt connection.
        comManager.startClient()
        
        // Observe operating state.
        operatingState = comManager.getOperatingState()
        _ = operatingState?.subscribe {
            guard let state = $0.element else {
                // We did not get a state update.
                return
            }
            
            print("Communication Manager changed state to: \(state)")
        }
        
    }
    
    /// Query list of snapshot objects from a task with a given id.
    @objc private func query() {
        
        // Task identifier for a snapshot object from the hello world example.
        let taskId: AnyCodable = "7ee64499-f03b-4277-9582-0e1347752251"
        
        // Setup filter.
        let filter = try? ObjectFilter.buildWithCondition { filter in
            filter.skip = 0
            filter.take = 10
            
            filter.condition = try .build { condition in
                condition.property = ObjectFilterProperty("parentObjectId")
                condition.expression = ObjectFilterExpression(filterOperator: .Equals, op1: taskId)
            }
            
            let order = OrderByProperty(properties: .init("creationTimestamp"), sortingOrder: .Desc)
            filter.orderByProperties = [order]
        }
        
        // Create query event.
        let queryEvent = QueryEvent<CustomCoatyObjectFamily>.withCoreTypes(eventSource: identity,
                                                                           coreTypes: [.Snapshot],
                                                                           objectFilter: filter)
        
        // Publish the query and subscribe to the corresponding retrieve event.
        try? comManager.publishQuery(event: queryEvent).subscribe { event in
            
            if let retrieveEvent = event.element {
                 print(retrieveEvent.json)
            }
            
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Setup methods.
    
    private func setupView() {
        self.view.backgroundColor = .white
        
        let queryButton = UIButton(frame: CGRect(x: 0, y: 150, width: 350, height: 50))
        queryButton.backgroundColor = .lightGray
        queryButton.setTitle("Query", for: .normal)
        queryButton.addTarget(self, action: #selector(query), for: .touchUpInside)
        self.view.addSubview(queryButton)
    }*/
}
