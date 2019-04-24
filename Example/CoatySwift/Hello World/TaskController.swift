//
//  TaskController.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift
import RxSwift

/// Listens for task requests advertised by the service and carries out assigned tasks.
class TaskController: Controller {
    
    /// This is the communicationManager for this particular controller. Note that,
    /// you _must_ call `self.communicationManager = getCommunicationManager()`
    /// somewhere in `onCommunicationManagerStarting()` in order to store this reference.
    private var communicationManager: CommunicationManager<HelloWorldObjectFamily>?
    
    // MARK: - Attributes.
    
    /// This disposebag holds references to all of your subscriptions. It's standard in RxSwift
    /// to call `.disposed(by: self.disposeBag)` at the end of every subscription.
    private var disposeBag = DisposeBag()
    
    /// An object that represents the currently assigned Task. See the `HelloWorldTask.swift`
    /// class for more insights.
    private var assignedTask: HelloWorldTask?
    
    /// This is a DispatchQueue for this particular controller that handles
    private var taskControllerQueue = DispatchQueue(label: "com.siemens.helloWorld.taskControllerQueue")
    
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
        communicationManager = self.getCommunicationManager()
        
        // Setup subscriptions.
        try? observeAdvertiseRequests()
        
        print("# Client User ID: \(self.runtime.commonOptions?.associatedUser?.objectId.uuidString ?? "-")")
    }
    
    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
    }
    
    override func initializeIdentity(identity: Component) {
        // You can change your client identity in the following way, for example:
        identity.assigneeUserId = self.runtime.commonOptions?.associatedUser?.objectId
    }
    
    // MARK: Application logic.
    
    
    /// Observe Advertises with the objectType of `OBJECT_TYPE_HELLO_WORLD_TASK`.
    /// When a HelloWorldTask Advertise was received, handle it via the `handleRequests`
    /// method.
    private func observeAdvertiseRequests() throws {
        try communicationManager?
            .observeAdvertiseWithObjectType(eventTarget: identity,
                                            objectType: ModelObjectTypes.HELLO_WORLD_TASK.rawValue)
            .map {(advertiseEvent) -> HelloWorldTask? in
                /// Make sure that the received event if of the expected type.
                return advertiseEvent.eventData.object as? HelloWorldTask
            }
            .flatMap {
                /// This is a "hack" to remove nil values from our observable stream.
                Observable.from(optional: $0)
            }
            .filter { (task) -> Bool in
                return task.status == .request
            }
            .subscribe(onNext: { (task) in
                // Subscribe to received Hello World Tasks & pass to `handleRequests`.
                self.handleRequests(request: task)
            }).disposed(by: self.disposeBag)
    }
    
    /// This methods sends an Update to the Service in order to make an offer to carry out a task.
    /// If it receives back a complete that matches its own ID, this means it has won the offer
    /// and can fulfill the task. The task will then be carried out in the `accomplishTask`method.
    ///
    /// - Parameter request: The task that was previously advertised by the Service and that needs
    ///                      to be handled.
    private func handleRequests(request: HelloWorldTask) {
        
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
            _ = try? self.communicationManager?.publishUpdate(event: event)
                .take(1)
                .map { (completeEvent) -> HelloWorldTask? in
                    return completeEvent.eventData.object as? HelloWorldTask
                }
                .flatMap {
                    Observable.from(optional: $0)
                }
                .subscribe(onNext: { (task) in
                    // If our Id is the same of the received complete event from the service, this
                    // means the Service has chosen us to carry out the task.
                    if task.assigneeUserId?.uuidString.lowercased() == self.identity.assigneeUserId?.uuidString.lowercased() {
                        self.logConsole(message: "Offer accepted for request: \(task.name)",
                                        eventName: "COMPLETE",
                                        eventDirection: .In)
                        self.accomplishTask(task: task)
                        
                    } else {
                        // We were not chosen to carry out the task.
                        self.setBusy(false)
                        self.logConsole(message: "Offer rejected for request: \(task.name)",
                                        eventName: "COMPLETE",
                                        eventDirection: .In)
                    }
                }).disposed(by: self.disposeBag)
            }
    }
    
    private func createTaskOfferEvent(_ request: HelloWorldTask) -> UpdateEvent<HelloWorldObjectFamily> {
        let dueTimeStamp = Int(Date().timeIntervalSince1970 * 1000)
        let assigneeUserId = self.identity.assigneeUserId?.uuidString.lowercased()
        let changedValues: [String: Any] = ["dueTimestamp": dueTimeStamp,
                                            "assigneeUserId": assigneeUserId!]
        return UpdateEvent<HelloWorldObjectFamily>.withPartial(eventSource: self.identity,
                                                                objectId: request.objectId,
                                                                    changedValues: changedValues)
    }
    
    private func accomplishTask(task: HelloWorldTask) {
        task.status = .inProgress
        task.lastModificationTimestamp = Date().timeIntervalSince1970
        
        print("Carrying out task: \(task.name)")
        
        // Notify other components that task is now in progress.
        let event = AdvertiseEvent<HelloWorldObjectFamily>.withObject(eventSource: self.identity, object: task)
        _ = try? communicationManager?.publishAdvertise(advertiseEvent: event, eventTarget: self.identity)
        
        let taskDelay = Int.random(in: minTaskDuration..<2*minTaskDuration)
        
        taskControllerQueue.asyncAfter(deadline: .now() + .milliseconds(taskDelay)) {
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
            
            _ = try? self.communicationManager?.publishQuery(event: queryEvent)
                .take(1)
                .timeout(Double(self.queryTimeout), scheduler: SerialDispatchQueueScheduler(
                    queue: self.taskControllerQueue,
                    internalSerialQueueName: "com.siemens.coaty.internalQueryQueue"))
                .subscribe({ (event) in
                    
                    if event.isCompleted || event.isStopEvent {
                        // We reached the timeout.
                        return
                    }
                    
                    if event.error != nil {
                        print("Failed to create snapshot objects.")
                        return
                    }
                    
                    self.logConsole(message: "Snapshots by parentObjectId: \(task.name)",eventName: "RETRIEVE", eventDirection: .In)
                    
                    if let snapshots = event.element?.eventData.objects
                        .map({ (coatyObject) -> Snapshot<HelloWorldObjectFamily> in
                        return coatyObject as! Snapshot<HelloWorldObjectFamily>
                        }){
                        
                        self.logHistorian(snapshots)

                    }

                }).disposed(by: self.disposeBag)
            
            self.setBusy(false)
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
    
    private func setBusy(_ to: Bool) {
        mutex.wait()
        isBusy = to
        mutex.signal()
    }
}
