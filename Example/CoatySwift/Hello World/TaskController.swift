//
//  TaskController.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift
import RxSwift


enum ModelTypes: String {
    case OBJECT_TYPE_HELLO_WORLD_TASK = "com.helloworld.Task"
    case OBJECT_TYPE_DATABASE_CHANGE = "com.helloworld.DatabaseChange"
}

/// Listens for task requests advertised by the service and carries out assigned tasks.
class TaskController: Controller {
    
    // MARK: - Attributes.
    
    private var assignedTask: HelloWorldTask?
    private var advertiseDisposable: Disposable?
    private var communicationManager: CommunicationManager<HelloWorldObjectFamily>?
    private var taskControllerQueue = DispatchQueue(label: "com.siemens.helloWorld.taskControllerQueue")
   
    // Subscriptions.
    
    private var disposeBag = DisposeBag()
    private var advertiseRequestSubscription: Disposable?
    
    /// - TODO: Clean this up. We need a way to store the subscriptions to prevent them from being
    ///   immediately disposed. Maybe it is already enough to add them to the dispose bag?
    private var observeSubscriptions = [Disposable]()
    
    /// - TODO: Convert into mutex.
    private var isBusy: Bool = false
    
    // MARK: - Controller lifecycle methods.

    override func onInit() {
        isBusy = false
    }
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        communicationManager = self.getCommunicationManager()
        
        // Setup subscriptions.
        try? observeAdvertiseRequests()
        
        print("# Client User ID: \(self.runtime.commonOptions?.associatedUser?.objectId.uuidString ?? "-")")
    }
    
    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        
        // Tear-down subscriptions.
        advertiseDisposable?.dispose()
    }
    
    override func initializeIdentity(identity: Component) {
        // super.initializeIdentity(identity: identity)
        identity.assigneeUserId = self.runtime.commonOptions?.associatedUser?.objectId
    }
    
    // MARK: Application logic.
    
    private func observeAdvertiseRequests() throws {
        advertiseRequestSubscription = try communicationManager?
            .observeAdvertiseWithObjectType(eventTarget: identity, objectType: ModelTypes.OBJECT_TYPE_HELLO_WORLD_TASK.rawValue)
            .map({ (advertiseEvent) -> HelloWorldTask? in
                return advertiseEvent.eventData.object as? HelloWorldTask
            })
            .flatMap{Observable.from(optional: $0)}
            .filter({ (task) -> Bool in
                return task.status == .request
            })
            .subscribe({ (event) in
                if let helloWorldTask = event.element {
                    self.handleRequests(request: helloWorldTask)
                }
            })
        
        advertiseRequestSubscription?.disposed(by: self.disposeBag)
    }
    
    private func handleRequests(request: HelloWorldTask) {
        if isBusy {
            logConsole(message: "Request ignored while busy: \(request.name)",
                       eventName: "ADVERTISE",
                       eventDirection: .In)
        }
        
        isBusy = true
        logConsole(message: "Request received: \(request.name)", eventName: "ADVERTISE", eventDirection: .In)
        
        // TODO: make random. include option "minTaskOfferDelay"
        let delay: DispatchTime = .now() + .seconds(1)
        taskControllerQueue.asyncAfter(deadline: delay) {
            
            // TODO: Check if associated user id exists.
            let dueTimeStamp = Int(Date().timeIntervalSince1970 * 1000)
            let assigneeUserId = self.identity.assigneeUserId?.uuidString.lowercased()
            let changedValues: [String: Any] = ["dueTimestamp": dueTimeStamp,
                                                "assigneeUserId": assigneeUserId]
            let event = UpdateEvent<HelloWorldObjectFamily>.withPartial(eventSource: self.identity,
                                                objectId: request.objectId,
                                                changedValues: changedValues)
            
            let subscription = try? self.communicationManager?.publishUpdate(event: event)
                .map({ (completeEvent) -> HelloWorldTask? in
                    return completeEvent.eventData.object as? HelloWorldTask
                })
                .flatMap{Observable.from(optional: $0)}
                .subscribe({ (event) in
                    guard let task = event.element else {
                        return
                    }
                    
                    if task.assigneeUserId?.uuidString.lowercased() == self.identity.assigneeUserId?.uuidString.lowercased() {
                        self.logConsole(message: "Offer accepted for request: \(task.name)", eventName: "COMPLETE", eventDirection: .In)
                        self.accomplishTask(task: task)
                    } else {
                        self.isBusy = false
                        self.logConsole(message: "Offer rejected for request: \(task.name)", eventName: "COMPLETE", eventDirection: .In)
                    }
                })
            
            self.observeSubscriptions.append(subscription!!)

            }
    }
    
    private func accomplishTask(task: HelloWorldTask) {
        task.status = .inProgress
        task.lastModificationTimestamp = Date().timeIntervalSince1970
        
        print("Carrying out task: \(task.name)")
        
        // Notify other components that task is now in progress.
        let event = AdvertiseEvent<HelloWorldObjectFamily>.withObject(eventSource: self.identity, object: task)
        _ = try? communicationManager?.publishAdvertise(advertiseEvent: event, eventTarget: self.identity)
        
        
        // TODO: make random. include option "minTaskDuration"
        let queryTimeoutMillis = 5000.0 // is this really MS????
        let delay: DispatchTime = .now() + .seconds(1)
        taskControllerQueue.asyncAfter(deadline: delay) {
            task.status = .done
            task.doneTimestamp = Double(Date().timeIntervalSince1970 * 1000)
            task.lastModificationTimestamp = Double(Date().timeIntervalSince1970 * 1000)
            
            self.logConsole(message: "Completed task: \(task.name)", eventName: "ADVERTISE", eventDirection: .Out)
            
            // Notify other components that task has been completed.
            let advertiseEvent = AdvertiseEvent<HelloWorldObjectFamily>.withObject(eventSource: self.identity, object: task)
            _ = try? self.communicationManager?.publishAdvertise(advertiseEvent: advertiseEvent, eventTarget: self.identity)
            
            // TODO: Double check string to any codable cast.
            let objectFilter = try? ObjectFilter.buildWithCondition {
                let objectId = AnyCodable(task.objectId.uuidString.lowercased())
                $0.condition = ObjectFilterCondition(property: .init("parentObjectId"),
                                                     expression: .init(filterOperator: .Equals, op1: objectId))
                $0.orderByProperties = [OrderByProperty(properties: .init("creationTimestamp"), sortingOrder: .Desc)]
            }
            
            self.logConsole(message: "Snapshot by parentObjectId: \(task.name)", eventName: "QUERY", eventDirection: .Out)
            
            let queryEvent = QueryEvent<HelloWorldObjectFamily>.withCoreTypes(eventSource: self.identity,
                                                 coreTypes: [.Snapshot],
                                                 objectFilter: objectFilter)
            
            let subscription = try? self.communicationManager?.publishQuery(event: queryEvent)
                // .timeout(queryTimeoutMillis, scheduler: MainScheduler.instance)
                .subscribe({ (event) in
                    
                    if event.error != nil {
                        print("Failed to create snapshot objects.")
                        return
                    }
                
                    if let snapshots = event.element?.eventData.objects
                        .map({ (coatyObject) -> Snapshot<HelloWorldObjectFamily> in
                        return coatyObject as! Snapshot<HelloWorldObjectFamily>
                        }){
                        
                        self.logHistorian(snapshots)

                    }

                })
            
            self.isBusy = false
            
            self.observeSubscriptions.append(subscription!!)
        }
        
        
    }
    
    // MARK: Util methods.
    
    private enum Direction {
        case In
        case Out
    }
    
    private func logConsole(message: String, eventName: String, eventDirection: Direction = .In) {
        let direction = eventDirection == .Out ? "<-" : "->"
        print("\(direction) \(eventName) | \(message)")
    }
    
    private func logHistorian(_ snapshots: [Snapshot<HelloWorldObjectFamily>]) {
        
        print("#############################")
        print("## Snapshots retrieved: \(snapshots.count)")
        snapshots.forEach {
            if let task = $0.object as? HelloWorldTask {
                print("# timestamp:\t\(task.creationTimestamp) status:\t\(task.status) assigneeUserId:\t\(task.assigneeUserId?.uuidString ?? "-")")
            }
        }
        
        print("#############################\n")
    }
}
