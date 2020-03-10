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

}
