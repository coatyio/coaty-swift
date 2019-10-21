//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DynamicTaskController.swift
//  CoatySwift_Example
//
import Foundation
import CoatySwift
import RxSwift

/// Listens for task requests advertised by the service and carries out assigned tasks.
class DynamicTaskController: DynamicController {
    
    // MARK: - Attributes.
    
    /// This is a DispatchQueue for this particular controller that handles
    /// asynchronous workloads, such as when we wait for a reply on our task offer.
    private var taskControllerQueue = DispatchQueue(label: "com.mycompany.helloWorld.dynamicTaskControllerQueue")
    
    // MARK: - Thread safety measures for working on tasks.
    
    /// A mutex lock managing the access to the `isBusy` variable.
    private let mutex = DispatchSemaphore(value: 1)
    
    /// Indicates whether the TaskController is currently working on a task already.
    private var isBusy: Bool = false
    
    // MARK: - Configurable options.
    
    /// Minimum amount of time in milliseconds until an offer is sent.
    let minTaskOfferDelay = 2000
    
    /// Minimum amount of time in milliseconds until a task is completed.
    let minTaskDuration = 5000
    
    /// Timeout for the query-retrieve event in milliseconds.
    let queryTimeout = 5000
    
    // MARK: - Controller lifecycle methods.
    
    override func onInit() {
        setBusy(false)
    }
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        
        // Setup subscriptions.
        try? observeAdvertiseRequests()
        
        print("# Client User ID: \(self.runtime.commonOptions?.associatedUser?.objectId.string ?? "-")")
    }
    
    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
    }
    
    override func initializeIdentity(identity: Component) {
        // You can change your client identity in the following way, for example:
        identity.assigneeUserId = self.runtime.commonOptions?.associatedUser?.objectId
    }
    
    // MARK: Application logic.
    
    /// Observe Advertises with the objectType of `HelloWorldTask`.
    /// When a Task Advertise was received, handle it via the `handleRequests`
    /// method.
    private func observeAdvertiseRequests() throws {
        try communicationManager
            .observeAdvertise(withObjectType: HelloWorldObjectFamily.helloWorldTask.rawValue)
            .compactMap { (advertiseEvent) -> Task? in
                advertiseEvent.data.object as? Task
            }
            .filter { (task) -> Bool in
                return task.status == .request
            }
            .subscribe(onNext: { (task) in
                // Subscribe to received Hello World Tasks & pass to `handleRequests`.
                if let urgency = task.custom["urgency"] as? Double {
                    let value = HelloWorldTaskUrgency.init(rawValue: Int(urgency))!
                    print("Custom field urgency: \(value)")
                } else {
                    print("Custom field urgency could not be parsed.")
                }
                
                
                self.handleRequests(request: task)
            }).disposed(by: self.disposeBag)
    }
    
    /// This methods sends an Update to the Service in order to make an offer to carry out a task.
    /// If it receives back a complete that matches its own ID, this means it has won the offer
    /// and can fulfill the task. The task will then be carried out in the `accomplishTask`method.
    ///
    /// - Parameter request: The task that was previously advertised by the Service and that needs
    ///                      to be handled.
    private func handleRequests(request: Task) {
        
        mutex.wait()
        // If we are busy with another task, we will ignore all incoming requests.
        if isBusy {
            logConsole(message: "Request ignored while busy: \(request.name)",
                eventName: "ADVERTISE",
                eventDirection: .In)
            
            mutex.signal()
            return
        }
        
        isBusy = true
        mutex.signal()
        
        logConsole(message: "Request received: \(request.name)",
            eventName: "ADVERTISE",
            eventDirection: .In)
        
        /// This just represents a delay we introduce when we respond to a request.
        let offerDelay = Int.random(in: minTaskOfferDelay..<2*minTaskOfferDelay)
        
        taskControllerQueue.asyncAfter(deadline: .now() + .milliseconds(offerDelay)) {
            
            self.logConsole(message: "Make an offer for request \(request.name)",
                eventName: "UPDATE",
                eventDirection: .Out)
            
            // Create the Update Event, which represents our Offer to carry out the given task.
            let event = self.createTaskOfferEvent(request)
            
            // Send it out and wait for the Service to answer.
            try? self.communicationManager.publishUpdate(event)
                .take(1)
                .compactMap { (completeEvent) -> Task? in
                    return completeEvent.data.object as? Task
                }
                .subscribe(onNext: { (task) in
                    // If our Id is the same of the received complete event from the service, this
                    // means the Service has chosen us to carry out the task.
                    if task.assigneeUserId == self.identity.assigneeUserId {
                        self.logConsole(message: "Offer accepted for request: \(task.name)",
                            eventName: "COMPLETE",
                            eventDirection: .In)
                        self.accomplishTask(task: task)
                        
                    } else {
                        // We were not chosen to carry out the task.
                        self.setBusy(false)
                        self.logConsole(message: "Offer rejected for request: \(task.name) - \(String(describing: task.assigneeUserId)):\(String(describing: self.identity.assigneeUserId))",
                            eventName: "COMPLETE",
                            eventDirection: .In)
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    
    /// Accomplishes a task after it was assigned to this task controller.
    ///
    /// - Parameter task: the task that should be accomplished.
    private func accomplishTask(task: Task) {
        
        // Update the task status and the modification timestamp.
        task.status = .inProgress
        task.lastModificationTimestamp = CoatyTimestamp.nowMillis()
        
        print("Carrying out task: \(task.name)")
        
        // Notify other components that task is now in progress.
        let event = eventFactory.AdvertiseEvent.with(object: task)
        try? communicationManager.publishAdvertise(event)
        
        // Calculate random delay to simulate task exection time.
        let taskDelay = Int.random(in: minTaskDuration..<2*minTaskDuration)
        
        taskControllerQueue.asyncAfter(deadline: .now() + .milliseconds(taskDelay)) {
            
            // Update the task object to set its status to "done".
            task.status = .done
            task.doneTimestamp = CoatyTimestamp.nowMillis()
            task.lastModificationTimestamp = task.doneTimestamp
            
            self.logConsole(message: "Completed task: \(task.name)",
                eventName: "ADVERTISE",
                eventDirection: .Out)
            
            // Notify other components that task has been completed.
            let advertiseEvent = self.eventFactory.AdvertiseEvent.with(object: task)
            
            try? self.communicationManager.publishAdvertise(advertiseEvent)
            
            // Send out query to get all available snapshots of the task object.
            
            self.logConsole(message: "Snapshot by parentObjectId: \(task.name)",
                            eventName: "QUERY",
                            eventDirection: .Out)
            
            // Note that the queried snapshots may or may not include the latest
            // task snapshot with task status "Done", because the task snaphot
            // of the completed task may or may not have been stored in the
            // database before the query is executed. A proper implementation
            // should use an Update-Complete event to advertise task status
            // changes and await the response before querying snapshots.
            let queryEvent = self.createSnapshotQuery(forTask: task)
            
            try? self.communicationManager.publishQuery(queryEvent)
                .take(1)
                .timeout(Double(self.queryTimeout),
                         scheduler: SerialDispatchQueueScheduler(
                            queue: self.taskControllerQueue,
                            internalSerialQueueName: "com.mycompany.coaty.internalQueryQueue")
                )
                .subscribe(
                    
                    // Handle incoming snapshots.
                    onNext: { (retrieveEvent) in
                        self.logConsole(message: "Snapshots by parentObjectId: \(task.name)",
                                        eventName: "RETRIEVE",
                                        eventDirection: .In)
                        
                        let objects = retrieveEvent.data.objects
                        let snapshots = objects.map { (coatyObject) -> DynamicSnapshot in
                            coatyObject as! DynamicSnapshot
                        }
                        
                        self.logHistorian(snapshots)
                    },
                    
                    // Handle possible errors.
                    onError: { _ in
                        print("Failed to retrieve snapshot objects.")
                })
                .disposed(by: self.disposeBag)
            
            // Task was accomplished, set busy state to free.
            self.setBusy(false)
        }
    }
    
    // MARK: - Event creation methods.
    
    /// Convenience method to create an offer for a task request.
    ///
    /// - Parameter request: the task request we want to make an offer to.
    /// - Returns: an update event that updates the dueTimeStamp and the assigneeUserId.
    private func createTaskOfferEvent(_ request: Task) -> DynamicUpdateEvent {
        let dueTimeStamp = CoatyTimestamp.nowMillis()
        let assigneeUserId = self.identity.assigneeUserId
        let changedValues: [String: Any] = ["dueTimestamp": dueTimeStamp,
                                            "assigneeUserId": assigneeUserId?.string as Any]
        
        return eventFactory.UpdateEvent.withPartial(objectId: request.objectId,
                                                    changedValues: changedValues)
    }
    
    /// Builds a query that asks for snapshots of the provided task object.
    ///
    /// - Parameter task: the tasks that we are interested in.
    /// - Returns: a query event.
    private func createSnapshotQuery(forTask task: Task) -> DynamicQueryEvent {
        
        // Setup the object filter to match on the `parentObjectId` and sort the results by the
        // creation timestamp.
        let objectFilter = try? ObjectFilter.buildWithCondition {
            let objectId = AnyCodable(task.objectId)
            $0.condition = ObjectFilterCondition(property: .init("parentObjectId"),
                                                 expression: .init(filterOperator: .Equals, op1: objectId))
            $0.orderByProperties = [OrderByProperty(properties: .init("creationTimestamp"), sortingOrder: .Desc)]
        }
        
        return eventFactory.QueryEvent.with(coreTypes: [.Snapshot], objectFilter: objectFilter)
    }
    
    // MARK: Util methods.
    
    private enum Direction {
        case In
        case Out
    }
    
    /// Pretty printing for event flow.
    ///
    /// - Parameters:
    ///   - message: the text that is displayed as description.
    ///   - eventName: typically the core type.
    ///   - eventDirection: either in or out.
    private func logConsole(message: String, eventName: String, eventDirection: Direction = .In) {
        let direction = eventDirection == .Out ? "<-" : "->"
        print("\(direction) \(eventName) | \(message)")
    }
    
    /// Pretty printing method for snapshots.
    ///
    /// - Parameter snapshots: the snapshots we want to print.
    private func logHistorian(_ snapshots: [DynamicSnapshot]) {
        print("#############################")
        print("## Snapshots retrieved: \(snapshots.count)")
        snapshots.forEach {
            if let task = $0.object as? Task {
                print("# timestamp:\t\(task.creationTimestamp) status:\t\(task.status) assigneeUserId:\t\(task.assigneeUserId?.string ?? "-")")
            }
        }
        
        print("#############################\n")
    }
    
    /// Thread-safe setter for `isBusy`
    ///
    /// - Parameter to: value that `isBusy` should be set to.
    private func setBusy(_ to: Bool) {
        mutex.wait()
        isBusy = to
        mutex.signal()
    }
}

