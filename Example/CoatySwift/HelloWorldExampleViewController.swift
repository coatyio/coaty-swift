//
//  HelloWorldExampleViewController.swift
//  CoatySwift_Example
//

import Foundation
import UIKit
import RxSwift
import CoatySwift

class HelloWorldExampleViewController: UIViewController {
    
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
            event in
            guard let state = event.element else {
                // We did not get a state update.
                return
            }
            
            print("Communication Manager changed state to: \(state)")
        }
        
    }
    
    private func setupView() {
        self.view.backgroundColor = .white
        
        let queryButton = UIButton(frame: CGRect(x: 0, y: 150, width: 350, height: 50))
        queryButton.backgroundColor = .lightGray
        queryButton.setTitle("Query", for: .normal)
        queryButton.addTarget(self, action: #selector(query), for: .touchUpInside)
        self.view.addSubview(queryButton)
    }
    
    /// Query list of snapshot objects from a task with a given id.
    @objc private func query() {
        
        let taskId = "7ee64499-f03b-4277-9582-0e1347752251"
        
        // Setup the query.
        let filterCondition = ObjectFilterCondition(property: .init("parentObjectId"),
                                                    expression: .init(filterOperator: .Equals,
                                                                      op1: .init(taskId)))
        
        let resultOrder = OrderByProperty(properties: .init("creationTimestamp"),
                                          sortingOrder: .Desc)
        
        let objectFilter = ObjectFilter(condition: filterCondition,
                                        orderByProperties: [resultOrder])
        
        // Create query event.
        let queryEvent = QueryEvent<CustomCoatyObjectFamily>.withCoreTypes(eventSource: identity,
                                                                           coreTypes: [.Snapshot],
                                                                           objectFilter: objectFilter)
        
        // Publish the query and subscribe to the corresponding retrieve event.
        
        try? comManager.publishQuery(event: queryEvent).subscribe { event in
            
            guard let retrieveEvent = event.element else {
                print("Something went wrong.")
                return
            }
            
            print(retrieveEvent.json)
            
        }.disposed(by: disposeBag)
    }
}
