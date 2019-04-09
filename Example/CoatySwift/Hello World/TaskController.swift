//
//  TaskController.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift
import RxSwift

/// Listens for task requests advertised by the service and carries out assigned tasks.
class TaskController: Controller {
    
    // MARK: - Attributes.
    
    private var assignedTask: HelloWorldTask?
    private var advertiseDisposable: Disposable?
    private var communicationManager: CommunicationManager<HelloWorldObjectFamily>?
    
    // MARK: - Controller lifecycle methods.
    
    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        communicationManager = self.getCommunicationManager()
        
        // Setup subscriptions.
        observeAdvertiseRequests()
        
        print("# Client User ID: \(self.runtime.commonOptions?.associatedUser?.objectId.uuidString ?? "-")")
    }
    
    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        
        // Tear-down subscriptions.
        advertiseDisposable?.dispose()
    }
    
    override func initializeIdentity(identity: Component) {
        super.initializeIdentity(identity: identity)
        // TODO: Implement me.
    }
    
    // MARK: Application logic.
    
    private func observeAdvertiseRequests() {
        // TODO: Implement me.
    }
    
    private func handleRequests(request: HelloWorldTask) {
        // TODO: Implement me.
    }
    
    private func accomplishTask(task: HelloWorldTask) {
        // TODO: Implement me.
    }
    
    // MARK: Util methods.
    
    private enum Direction {
        case In
        case Out
    }
    
    private func logConsole(message: String, eventName: String? = nil, eventDirection: Direction = .In) {
        // TODO: Implement me.
    }
    
    // TODO: private func logHistorian(snapshots: [Snapshot]) {}
}
