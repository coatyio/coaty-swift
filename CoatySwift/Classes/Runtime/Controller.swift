//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Controller.swift
//  CoatySwift
//

import Foundation
import RxSwift

/// The base controller class.
open class Controller {

    /// Gets the contrainer's communicationManager.
    private (set) public var communicationManager: CommunicationManager!

    /// Gets the container object of this controller.
    private (set) public var container: Container!

    /// Gets the container's Runtime object.
    private (set) public var runtime: Runtime!

    /// Gets the controller's options as specified in the configuration options.
    private (set) public var options: ControllerOptions?

    /// Gets the registered name of this controller.
    ///
    /// The registered name is either defined by the corresponding key in the
    /// `Components.controllers` object in the container configuration, or by
    /// invoking `Container.registerController` method with this name.
    private (set) public var registeredName: String
    
    /// This dispose bag holds references to your observable subscriptions added
    /// with `.disposed(by: self.disposeBag)`. These subscriptions are
    /// *automatically* disposed when the communication manager is stopped (in
    /// the `onCommunicationManagerStopping` base method).
    public var disposeBag = DisposeBag()
    
    /// Never instantiate controller objects in your application; they are created
    /// automatically by dependency injection.
    ///
    /// - Remark: for internal use in CoatySwift framework only.
    required public init(container: Container,
                         options: ControllerOptions?,
                         controllerType: String) {
        self.container = container
        self.runtime = container.runtime
        self.options = options ?? ControllerOptions()
        self.registeredName = controllerType
        self.communicationManager = container.communicationManager
    }
    
    // MARK: - Distributed logging.
    
    /// Advertise a Log object for debugging purposes.
    ///
    /// - Parameters:
    ///     - message: a debug message
    ///     - tags: any number of log tags
    public func logDebug(message: String, tags: [String]...) {
        self._log(logLevel: .debug, message: message, tags: tags.reduce([], +))
    }
    
    /// Advertise an informational Log object.
    ///
    /// - Parameters:
    ///     - message: an informational message
    ///     - tags: any number of log tags
    public func logInfo(message: String, tags: [String]...) {
        self._log(logLevel: .info, message: message, tags: tags.reduce([], +))
    }
    
    /// Advertise a Log object for a warning.
    ///
    /// - Parameters:
    ///     - message: a warning message
    ///     - tags: any number of log tags
    public func logWarning(message: String, tags: [String]...) {
        self._log(logLevel: .warning, message: message, tags: tags.reduce([], +))
    }
    
    /// Advertise a Log object for an error.
    ///
    /// - Parameters:
    ///     - error: a error (object)
    ///     - message: additional error message
    ///     - tags: any number of log tags
    public func logError(error: Any, message: String, tags: [String]...) {
        let msg = "\(message): \(error)"
        self._log(logLevel: .error, message: msg, tags: tags.reduce([], +))
    }
    
    /// Advertise a Log object for a fatal error.
    ///
    /// - Parameters:
    ///     - error: an error (object)
    ///     - message: additional error message
    ///     - tags: any number of log tags
    public func logFatal(error: Any, message: String, tags: [String]...) {
        let msg = "\(message): \(error)"
        self._log(logLevel: .fatal, message: msg, tags: tags.reduce([], +))
    }
    
    /// Called when the container has completely set up and injected all
    /// dependency components, including all its controllers.
    ///
    /// Use this method to perform initializations in your custom controller
    /// class instead of defining a constructor. Although the base
    /// implementation does nothing it is good practice to call super.onInit()
    /// in your override method; especially if your custom controller class
    /// extends from another custom controller class and not from the base
    /// `Controller` class directly.
    open func onInit() {}
    
    /// Called when the communication manager is about to start or restart.
    /// Implement side effects here. Ensure that
    /// super.onCommunicationManagerStarting is called in your override. The
    /// base implementation does nothing.
    open func onCommunicationManagerStarting() {}
    
    /// Called when the communication manager is about to stop. Implement side
    /// effects here. Ensure that super.onCommunicationManagerStopping is called
    /// in your override.
    ///
    /// The base implementation disposes all observable subscriptions collected
    /// by the controller's dispose bag (see `self.disposeBag`) and
    /// reinitializes a new dispose bag afterwards.
    open func onCommunicationManagerStopping() {
        self.disposeBag = DisposeBag()
    }
    
    /// Called by the Coaty container when this instance should be disposed.
    /// Implement cleanup side effects here. The base implementation does nothing.
    open func onDispose() {}
    
    deinit {
        onDispose()
    }
    
    // MARK: - Utility methods for distributed logging functionality.
    
    /// Whenever one of the controller's log methods (e.g. `logDebug`, `logInfo`,
    /// `logWarning`, `logError`, `logFatal`) is called by application code, the
    /// controller creates a Log object with appropriate property values and
    /// passes it to this method before advertising it.
    ///
    /// You can override this method to additionally set certain properties (such
    /// as `LogHost.hostname` or `Log.logLabels`). Ensure that
    /// `super.extendLogObject` is called in your override. The base method does
    /// nothing.
    ///
    /// - Parameter log: log object to be extended before being advertised
    open func extendLogObject(log: Log) { }
    
    private func _log(logLevel: LogLevel, message: String, tags: [String]) {
        let agentInfo = self.runtime.commonOptions?.agentInfo
        let pid = Double(ProcessInfo.processInfo.processIdentifier)
        
        let hostInfo = LogHost(agentInfo: agentInfo,
                               pid: pid,
                               hostname: nil,
                               userAgent: nil) // always nil, because swift does not run in a browser
        
        let log = Log(logLevel: logLevel,
                      logMessage: message,
                      logDate: CoatyTimeInterval.toLocalIsoString(date: Date(), includeMilis: true),
                      name: "\(self.registeredName)",
                      objectType: Log.objectType,
                      objectId: .init(),
                      logTags: tags,
                      logLabels: nil,
                      logHost: hostInfo)
        
        self.extendLogObject(log: log)
        
        try? self.communicationManager.publishAdvertise(AdvertiseEvent.with(object: log))
    }

}
