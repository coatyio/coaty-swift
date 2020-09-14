---
layout: default
title: CoatySwift Documentation
---

# CoatySwift Developer Guide

This document covers everything a Swift developer needs to know about using the
CoatySwift framework to implement collaborative IoT applications targeting iOS,
iPadOS, and macOS. We assume you know nothing about CoatySwift before reading
this guide.

> __NOTE__:
>
> We would like to note that more information about the internals and
> basics of the __Coaty__ framework can be found in [Coaty Communication
> Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/). The
> [Coaty JS Developer
> Guide](https://coatyio.github.io/coaty-js/man/developer-guide/), even though
> written for TypeScript, shares many similarities with CoatySwift and we
> recommend checking out this guide as well if you would like to dig deeper, as
> it is documented in a more detailed way and provides more extensive features.

## Table of Contents

- [CoatySwift Developer Guide](#coatyswift-developer-guide)
  - [Table of Contents](#table-of-contents)
  - [Getting started](#getting-started)
  - [Necessary background knowledge](#necessary-background-knowledge)
  - [Coaty(Swift) terminology](#coatyswift-terminology)
  - [Setup instructions and requirements](#setup-instructions-and-requirements)
    - [mDNS broker discovery support](#mdns-broker-discovery-support)
  - [Communication patterns](#communication-patterns)
    - [Publish an Advertise event (one-way)](#publish-an-advertise-event-one-way)
    - [Observe an Advertise event (one-way)](#observe-an-advertise-event-one-way)
    - [Publish a Discover event and observe Resolve events (two-way)](#publish-a-discover-event-and-observe-resolve-events-two-way)
    - [Observe a Discover event (two-way)](#observe-a-discover-event-two-way)
  - [IO Routing](#io-routing)
    - [IO Routing implementation](#io-routing-implementation)
      - [SourcesAgent](#sourcesagent)
      - [NormalStateActorAgent](#normalstateactoragent)
      - [EmergencyStateActorAgent](#emergencystateactoragent)
  - [Bootstrapping a Coaty container](#bootstrapping-a-coaty-container)
  - [Creating controllers](#creating-controllers)
  - [Custom object types](#custom-object-types)
    - [Class registration](#class-registration)
    - [Initializers](#initializers)
    - [Decodable methods](#decodable-methods)
  - [FAQ](#faq)
    - [Interacting with controllers](#interacting-with-controllers)
    - [Managing Observable subscriptions](#managing-observable-subscriptions)
    - [Communication State vs Operating State](#communication-state-vs-operating-state)
    - [Inspecting Coaty object types and AnyCodables](#inspecting-coaty-object-types-and-anycodables)
    - [Distributed lifecycle management](#distributed-lifecycle-management)
    - [Event echo suppression](#event-echo-suppression)
    - [Terminology](#terminology)
  - [Additional resources](#additional-resources)

## Getting started

If you want a short, concise look into CoatySwift, feel free to check out the
[CoatySwift Tutorial](https://coatyio.github.io/coaty-swift/tutorial/index.html)
with a step-by-step guide on how to set up a basic CoatySwift application. The
source code of this tutorial can be found in the
[CoatySwiftExample](https://github.com/coatyio/coaty-swift/tree/master/CoatySwiftExample) Xcode
folder of the CoatySwift repo. Just clone the repo, run `pod install` on the
repo root folder and open the new  `xcworkspace` in Xcode.

You can find additional examples in the `swift` sections of the
[coaty-examples](https://github.com/coatyio/coaty-examples) repo on GitHub. You
will find the following Xcode projects there: `Hello World` and `Remote
Operations`. They are interoperable with the corresponding Coaty JS examples and
intended to be used along with them. These projects can serve as blueprints for
how to design CoatySwift applications.

## Necessary background knowledge

In order to be able to use CoatySwift the way it is intended to, we assume you
are familiar with the following programming concepts:

- [ReactiveX](http://reactivex.io/) - Describes the basics on how incoming
  asynchronous messages are handled in the CoatySwift framework. In particular,
  CoatySwift is using [RxSwift](https://github.com/ReactiveX/RxSwift), the Swift
  version of ReactiveX.

## Coaty(Swift) terminology

> __TL;DR__
>
> - Every iOS/iPadOS/macOS app hosts one or more Coaty __agents__ (usually one)
> - Every Coaty agent holds one __container__
> - Every container has
>   - 1...n __controllers__
>   - 1 __configuration__
>   - 1 __communication manager__

- In Coaty, every application component that communicates with other application
  components by use of Coaty communication flows is called an __agent__. So
  simply speaking, we consider an iOS or a macOS application to host (at least)
  one agent.

- Every agent holds a __container__. A container basically defines entry and
  exit points for a Coaty agent and provides lifecycle management for its
  controllers.

- Every container has 1...n __controllers__. A controller encapsulates
  communication business logic, and most importantly, all access methods related
  to any form of communication flow with other agents that you will be using in
  your application will be called from inside a controller. Each controller
  should encapsulate a single dedicated functionality. ___These controllers are
  in no way related to Apple's UIViewControllers!___

- Every container holds exactly one __communication manager__. A communication
  manager lets you publish and subscribe to communication events, basically
  handling all types of communication flow between Coaty agents.

- Every container has a __configuration__: Defines options for the container, as
  well as the controllers. There are many options available. You can check out
  example configs in the sections below, or the configs found in the `CoatySwiftExample`
  folder in the CoatySwift Xcode project.

## Setup instructions and requirements

- To build and run Coaty agents with the CoatySwift technology stack you need
  [XCode](https://developer.apple.com/xcode/) 10.2 or higher.

- __Set up an MQTT Broker__: Communication flows between Coaty agents are build
  on top of the [MQTT](http://mqtt.org) publish-subscribe messaging protocol -
  so remember to set up and have an MQTT Broker running. We recommend checking
  out one of the following brokers:
  - [Coaty
    Broker](https://coatyio.github.io/coaty-js/man/developer-guide/#coaty-broker-for-development)
    (development broker provided by [Coaty
    JS](https://github.com/coatyio/coaty-js))
  - [Mosquitto](https://mosquitto.org/)
  - [HiveMQ](https://www.hivemq.com/)
  - [VerneMQ](https://vernemq.com/)

- __Integrate CoatySwift in your project__: CoatySwift is available through
  [CocoaPods](https://cocoapods.org). Ensure you have installed **at least**
  version `1.8.4` of CocoaPods, i.e. running `pod --version` should yield `1.8.4` or higher.

  You can add the CoatySwift pod to the Podfile of your app as follows:

   ```ruby
   target 'MyApp' do
   pod 'CoatySwift', '~> 2.0'
   end
   ```

   Then run a `pod install` for a new installation or a `pod update CoatySwift`
   to update the pod to the specified version.

### mDNS broker discovery support

CoatySwift gives you the possibility to discover broker services dynamically via
mDNS. You will need an mDNS-supporting broker for this, which you can find
[here](https://coatyio.github.io/coaty-js/man/developer-guide/#coaty-broker-for-development).
For the client, add the following lines to your `Configuration` object:

```swift
let mqttClientOptions = MQTTClientOptions(shouldTryMDNSDiscovery: true)

config.communication = CommunicationOptions(mqttClientOptions: mqttClientOptions)
```

> __NOTE__: Broker host and port settings and the `shouldAutoStart` option are
> ignored if mDNS broker discovery is enabled.

## Communication patterns

Citing the [Coaty Protocol
Documentation](https://coatyio.github.io/coaty-js/man/communication-protocol/#events-and-event-patterns):

The framework uses a minimum set of predefined events and event patterns to
discover, distribute, and share object information in a decentralized
application:

- __Advertise__ an object: Multicast an object to parties interested in objects
  of a specific core or object type.

- __Deadvertise__ an object by its unique ID: Notify subscribers when capability
  is no longer available; for abnormal disconnection of a party, last will
  concept can be implemented by sending this event.

- __Channel__: Multicast objects to parties interested in any kind of objects
  delivered through a channel with a specific channel identifier.

- __Discover - Resolve__: Discover an object and/or related objects by external
  ID, internal ID, or object type, and receive responses by Resolve events.

- __Query - Retrieve__: Query objects by specifying selection and ordering
  criteria, receive responses by Retrieve events.

- __Update - Complete__: Request or suggest an object update and receive
  accomplishments by Complete events.

- __Call - Return__: Request execution of a remote operation and receive results
  by Return events.

> __NOTE__:
>
>Although Coaty itself also specifices __IoValue__ and __Associate__ events,
>these are currently **not** included in CoatySwift and therefore are left out
>of the documentation.

We differentiate between __one-way__ and __two-way__ events. Advertise,
Deadvertise and Channel are one-way events. Discover-Resolve, Query-Retrieve,
Update-Complete and Call-Return are two-way events.

We also differentiate between __publishing__ events or __observing__ them. When
publishing an event, simply put, you send a message over the broker. When
observing (i.e. subscribing to) an event, you sign up to receive messages over
the broker.

In the following examples, we will show you how you can publish and observe
one-way events as well as two-way events.

### Publish an Advertise event (one-way)

Note that this procedure is much the same as publishing Deadvertise and Channel
events.

```swift
// Create a Task object.
let myTaskObject = Task(creatorId: .init(),
                        creationTimestamp: .nowMillis(),
                        status: .request,
                        name: "MyTask")

// Create the event.
let event = try! AdvertiseEvent.with(object: myTaskObject)

// Publish the event by the communication manager.
self.communicationManager.publishAdvertise(event)
```

### Observe an Advertise event (one-way)

Note that this procedure is much the same as observing Deadvertise and Channel
events.

```swift
self.communicationManager
    .observeAdvertise(withCoreType: .Task)
    .subscribe(onNext: { (advertiseEvent) in
        let task = advertiseEvent.data.object as! Task

        // Do something with this task...
        print(task.name)

    })
    .disposed(by: self.disposeBag)
```

### Publish a Discover event and observe Resolve events (two-way)

Note that this procedure is much the same as for Query-Retrieve,
Update-Complete, and Call-Return events.

```swift
let discoverEvent = DiscoverEvent.with(externalId: "an-external-id")

self.communicationManager
    .publishDiscover(discoverEvent)
    .subscribe(onNext: { (resolveEvent) in
        // Do something with your Resolve event.
        print(resolveEvent.data.object)

    })
    .disposed(by: self.disposeBag)
```

### Observe a Discover event (two-way)

Note that this procedure is much the same as for Query-Retrieve,
Update-Complete, and Call-Return events.

```swift
self.communicationManager
    .observeDiscover()
    .filter { (discoverEvent) -> Bool in
        return discoverEvent.data.isDiscoveringExternalId()
    }
    .subscribe(onNext: { (discoverEvent)
        let externalId = discoverEvent.data.externalId

        // Search for an object with the given external Id...
        let resolvedObject = CoatyObject(coreType: .CoatyObject,
            objectType: "com.mydomain.ExampleObject",
            objectId: .init(),
            name: "My resolved example object")
        resolvedObject.externalId = externalId

        let event = ResolveEvent.with(object: resolvedObject)
        discoverEvent.resolve(resolveEvent: event)

    })
    .disposed(by: self.disposeBag)
```

## IO Routing
**Note**: Please refer to coaty-js Developer Guide for general informations (concepts, constraints and communication event flow) regarding [IO Routing](https://coatyio.github.io/coaty-js/man/developer-guide/#io-routing).

### IO Routing implementation
IO router classes and controller for IO sources/IO actors are provided in the IORouting directory of CoatySwift.

The following example defines a temperature measurement routing scenario with three temperature sensor sources (each with a different strategy for publishing values) and two actors with compatible data value types and formats. The IO context for this scenario defines an operating state, either normal or emergency. In each state, exactly one of the two actors should consume IO values emitted by the sources.

**Note**: This example is fully implemented in [Coaty example on IO Routing]((https://github.com/coatyio/coaty-examples/tree/master/iorouting/swift)).

#### SourcesAgent
```swift
// At first define a class which will represent the context for IO Routing
// This class extends IoContext class with an additional property operatingState
// Make sure to follow all the steps from section ´Custom object types´ 
// (in this Developer Guide) while subclassing IoContext
class TemperatureIoContext: IoContext {
    var operatingState: String
    
    override class var objectType: String {
        return register(objectType: "coaty.TemperatureIoContext", with: self)
    }
    
    init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String, operatingState: String) {
        self.operatingState = operatingState
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    enum CodingKeys: String, CodingKey {
        case operatingState
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.operatingState = try container.decode(String.self, forKey: .operatingState)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(operatingState, forKey: .operatingState)
    }
}

// Common context for IO routing
let ioContext = TemperatureIoContext(coreType: .IoContext,
                                    objectType: "coaty.TemperatureIoContext",
                                    objectId: CoatyUUID(uuidString: "b61740a6-95d7-4d1a-8be5-53f3aa1e0b79")!,
                                    name: "TemperatureMeasurement",
                                    operatingState: "normal")

// Initialize IoSource for .None Strategy.
// This strategy simply publishes all values as they are being sent.
let source1 = IoSource(valueType: "coaty.test.Temperature[Celsius]",
                        updateStrategy: .None,
                        name: "Temperature Source 1",
                        objectType: CoreType.IoSource.rawValue,
                        objectId: CoatyUUID(uuidString: "c547e5cd-ef99-4ccd-b109-fc472fc2d421")!)

// Initialize IoSource for .Sample Strategy.
// This strategy means: Publish the most recent values within periodic time intervals
// according to the recommended update rate assigned to the IO source. More information in documentation.
let source2 = IoSource(valueType: "coaty.test.Temperature[Celsius]",
                        updateStrategy: .Sample,
                        updateRate: 5000,
                        name: "Temperature Source 2",
                        objectType: CoreType.IoSource.rawValue,
                        objectId: CoatyUUID(uuidString: "2e9949f7-a8ef-435b-88a9-527c0a9414c3")!)

// Initialize IoSource for .Throttle Strategy.
// This strategy means: Only publish a value if a particular timespan has 
// passed without it publishing another value. More information in documentation.
let source3 = IoSource(valueType: "coaty.test.Temperature[Celsius]",
                        updateStrategy: .Throttle,
                        updateRate: 5000,
                        name: "Temperature Source 3",
                        objectType: CoreType.IoSource.rawValue,
                        objectId: CoatyUUID(uuidString: "200cc37b-df20-4425-a16f-5c0b42d04dbb")!)

// Configuration of agent1 with an IoNode for three io sources in common options
let ioNodeDefinition = IoNodeDefinition(ioSources: [source1, source2, source3],
                                        ioActors: nil,
                                        characteristics: nil)

let commonOptions = CommonOptions(ioContextNodes: ["TemperatureMeasurement" : ioNodeDefinition],
                                logLevel: .info)
```
#### NormalStateActorAgent
```swift
let actor1 = IoActor(valueType: "coaty.test.Temperature[Celsius]",
                    updateRate: 5000,
                    name: "Temperature Actor 1",
                    objectType: CoreType.IoActor.rawValue,
                    objectId: CoatyUUID(uuidString: "a731fc40-c0f8-486f-b5b6-b653c3cabaea")!)

// Configuration of agent 2 with an IoNode for actor 1 in common options
let ioNodeDefinition = IoNodeDefinition(ioSources: nil,
                                        ioActors: [actor1],
                                        characteristics: nil)

let commonOptions = CommonOptions(ioContextNodes: ["TemperatureMeasurement" : ioNodeDefinition],
                                logLevel: .info)
```

#### EmergencyStateActorAgent
```swift
// Temperature Actor 2 (Emergency operating state).
let actor2 = IoActor(valueType: "coaty.test.Temperature[Celsius]",
                    updateRate: 5000,
                    name: "Temperature Actor 2",
                    objectType: CoreType.IoActor.rawValue,
                    objectId: CoatyUUID(uuidString: "a60a74f3-3d26-446f-a358-911867544944")!)

// Configuration of agent 3 with an IoNode for actor2 in common options
let ioNodeDefinition = IoNodeDefinition(ioSources: nil,
                                        ioActors: [actor1],
                                        characteristics: nil)

let commonOptions = CommonOptions(ioContextNodes: ["TemperatureMeasurement" : ioNodeDefinition],
                                logLevel: .info)
```

Use the RuleBasedIoRouter controller class to realize rule-based routing of data from IO sources to IO actors. By defining application-specific routing rules you can associate IO sources with IO actors based on arbitrary application context.

```swift
// Configure the rules used by the RuleBasedIoRouter.
let condition1: IoRoutingRuleConditionFunc = { (source, sourceNode, actor, actorNode, context, router) -> Bool in
    guard let operatingStateResponsibility = actorNode.characteristics?["isResponsibleForOperatingState"] as? String,
        let context = context as? TemperatureIoContext else {
        return false
    }
    return operatingStateResponsibility == "normal" && context.operatingState == "normal"
}

let condition2: IoRoutingRuleConditionFunc = { (source, sourceNode, actor, actorNode, context, router) -> Bool in
    guard let operatingStateResponsibility = actorNode.characteristics?["isResponsibleForOperatingState"] as? String,
        let context = context as? TemperatureIoContext else {
        return false
    }
    return operatingStateResponsibility == "emergency" && context.operatingState == "emergency"
}

let rules: [IoAssociationRule] = [
    IoAssociationRule(name: "Route temperature sources to normal actors if operating state is normal",
                        valueType: "coaty.test.Temperature[Celsius]",
                        condition: condition1),
    IoAssociationRule(name: "Route temperature sources to emergency actors if operating state is emergency",
                        valueType: "coaty.test.Temperature[Celsius]",
                        condition: condition2)
]

// Configure the required options for a RuleBasedIoRouter
let routerOptions = ControllerOptions(extra: ["ioContext" : ioContext, "rules": rules])
        
// Controller options are always mapped by the controller class name as String.
// This variable is later used in the construction of the Configuration object.
let controllers = ControllerConfig(controllerOptions: ["RuleBasedIoRouter": routerOptions])
```

An IO router makes its IO context available by advertisement and for discovery (by core type, object type or object Id) and listens for Update-Complete events on its IO context. To trigger reevaluation of association rules by an IO router, simply publish an Update event for the discovered IO context object.
```swift
var ioContext: TemperatureIoContext

// Discover temperature measurement context from IO router
coatyContainer?
    .communicationManager?
    .publishDiscover(DiscoverEvent.with(objectTypes: ["coaty.test.TemperatureIoContext"])).subscribe(onNext: { resolve in
        self.ioContext = resolve.data.object as! TemperatureIoContext
    })

// Change context operating state to trigger rerouting from sources to emergency actors
self.ioContext.operatingState = "normal"

coatyContainer?.communicationManager
    .publishUpdate(UpdateEvent.with(object: ioContext)).subscribe(onNext: { complete
        // Updated object is returned.
        self.ioContext = complete.data.object as! TemperatureIoContext
    })
```

The Communication Manager supports methods to control IO routing in your agent: Use publishIoValue to send IO value data for an IO source. Use observeIoState and observeIoValue to receive IO state changes and IO values for an IO actor.

To further simplify management of IO sources and IO actors, the framework provides specific controller classes on top of these methods:

IoSourceController: Provides data transfer rate controlled publishing of IO values for IO sources and monitoring of changes in the association state of IO sources. This controller respects the backpressure strategy of an IO source in order to cope with IO values that are more rapidly produced than specified in the recommended update rate.

IoActorController: Provides convenience methods for observing IO values and for monitoring changes in the association state of specific IO actors. Note that this controller class caches the latest IO value received for the given IO actor (using BehaviorSubjects). When subscribed, the current value (or nil if none exists yet) is emitted immediately. Due to this behavior the cached value of the observable will also be emitted after reassociation. If this is not desired use self.communicationManager.observeIoValue instead. This method doesn’t cache any previously emitted value.

Take a look at these controllers in action in the [CoatySwift Example on IO Routing](https://github.com/coatyio/coaty-examples/tree/master/io-routing/swift)

## Bootstrapping a Coaty container

In order to get your Coaty application running, you will have to set up the
Coaty container and its controllers. We will provide a step by step explanation
of how you can create a container with an exemplary controller.

> __TL;DR__
>
>1. Create a global variable that holds a reference to the `coatyContainer`.
>2. Register all controllers and object types that you want to use.
>3. Create an appropriate container configuration.
>4. Simply call `container.resolve(…)` and assign its return value to the
>   `coatyContainer` global variable from step 1.

> __NOTE__:
>
>Unfortunately there is no sequential way (where everything compiles after each
>step) to set up a container until you added all of the required components. It
>is probably the easiest to add at least one `Controller` before you start to
>resolve your `Container`. We suggest taking a look at the `Hello World` example
>or the example that is integrated in CoatySwift to see how the final result
>looks like.

We suggest setting up the main structure of the container as part of the
`AppDelegate.swift`.

1. Make sure to import CoatySwift in the top.

    ```swift
    import CoatySwift
    ```

2. Create a global variable `coatyContainer`. This will hold a reference to our
   Coaty container. It is needed because otherwise all of our references go out
   of scope and communication is terminated.

    ```swift
    // ...
    import CoatySwift

    /// Save a reference of your container in the app delegate to
    /// make sure it stays alive during the entire lifetime of the app.
    var coatyContainer: Container?

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
    // ...
    ```

3. We will now go on to register our custom controllers and object types. Here,
   we assume that you have already defined an `ExampleController` (as explained
   [here](#creating-controllers)) as well as an `ExampleObject` (as explained
   [here](#custom-object-types)). The key note of this step is to indicate which
   key maps to which controller, in order to be able to access these controllers
   later after the container has been bootstrapped.  

    ```swift
    // Here, you specify which Coaty controllers and object types you want to use in
    // your application.
    //
    // Note that the controller keys (such as "ExampleController")
    // do NOT have to have the exact name of their controller class. Feel free to give
    // them any unique names you want. The _mapping_ is the important thing, so which name
    // maps to what controller class.
    let components = Components(controllers: [
        "ExampleController": ExampleController.self
    ],
                                objectTypes: [
        ExampleObject.self,
    ])
    ```

4. The next step is to specify a configuration for your container. Below we have
   added an example configuration which should be appropriate for most Coaty
   beginner projects. Note the `MQTTClientOptions` in particular: Here, you pass in
   your broker's host address and port (and other optional connection options).

    ```swift
    /// This method creates an exemplary Coaty configuration.
    /// You can use it as a basis for your application.
    private func createExampleConfiguration() -> Configuration? {
        return try? .build { config in

            // This part defines common options shared by all container components,
            // including e.g. an associated user or associated device.
            config.common = CommonOptions()

            // Adjusts the logging level of CoatySwift messages, which is especially
            // helpful if you want to test or debug applications (default is .error).
            config.common?.logLevel = .info

            // Configure an expressive `name` of the container's identity here.
            config.common?.agentIdentity = ["name": "Example Agent"]

            // You can also add extra information to your configuration in the form of a
            // [String: String] dictionary.
            config.common?.extra = ["ContainerVersion": "0.0.1"]

            // Define communication-related options, such as the host address of your broker
            // (default is "localhost") and the port it exposes (default is 1883). Define a
            // unqiue communication namespace for your application and make sure to immediately
            // connect with the broker, indicated by `shouldAutoStart: true`.
            let mqttClientOptions = MQTTClientOptions(host: brokerHost,
                                                      port: UInt16(brokerPort))
            config.communication = CommunicationOptions(namespace: "com.example",
                                                        mqttClientOptions: mqttClientOptions,
                                                        shouldAutoStart: true)
        }
    }

    //...

    /// And then, simply call it when you need it in order to integrate it
    /// into your container configuration.
    guard let configuration = createExampleConfiguration() else {
        print("Invalid configuration! Please check your options.")
        return
    }

    //...
    ```

5. Lastly, the only thing you need to do is to resolve everything and assign the
   variable we previously defined, namely, `coatyContainer`,  with the return
   value of `container.resolve(…)`. Below code shows the last step in
   bootstrapping a Coaty container:

    ```swift
    // Pass in the previously defined components and configuration.
    // Then, call Container.resolve(...), save it into our global variable,
    // and you're done!
    coatyContainer = Container.resolve(components: components,
                                       configuration: configuration)
    ```

## Creating controllers

As previously mentioned, Coaty controllers are the components encapsulating
communication business logic in your application.

Each controller provides __lifecycle methods__ that are called by the framework,
shown here:

```swift
class ExampleController: Controller {

    // MARK: - Controller lifecycle methods.

    override func onInit() {
        // Perform initial setup.
        // Access the container by `self.container`.
        // Access other controllers by `self.container.getController(name:)`
    }

    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        // Setup your observations or start publishing events.
    }

    override func onCommunicationManagerStopping() {
        super.onCommunicationManagerStopping()
        // Perform side effects when communication manager is stopped.
    }

    override func onDispose() {
        // Teardown resources when the container is disposed.
    }
}
```

Of course you can also additional functionality, such as new methods or
variables, references, and so on. A very basic ExampleController could look like
this:

```swift
class ExampleController: Controller {

    override func onCommunicationManagerStarting() {
        super.onCommunicationManagerStarting()
        print("[ExampleController] - onCommunicationManagerStarting()")
    }
}
```

In the next steps, you should add publish and subscribe handlers, as previously
explained in this [section](#communication-patterns).

## Custom object types

> __TL;DR__
>
>1. Create a new Swift class that inherits from `CoatyObject`, any other Coaty
>   core type, or another custom object type.
>2. Register the new class for your custom object type with CoatySwift and
>   use this custom object type in the initializer.
>3. Implement conformance to the
>   [Codable](https://developer.apple.com/documentation/swift/codable) protocol.
>   Make sure to call the super implementations of the initializer and the
>   encode method.

Coaty comes with an opinionated set of core object types to be used or extended
by CoatySwift applications. These Coaty objects are the subject of communication
between Coaty agents. Core types include the base `CoatyObject`, and others,
such as `Task` or `User`. For a detailed specification of the Coaty object model
see
[here](https://coatyio.github.io/coaty-js/man/developer-guide/#object-model).

To define custom, i.e. application-specific object types use standard Swift
classes that extend predefined core types or other custom types. For example,
define your custom type that inherits from `CoatyObject` as in the following
example:

```swift
import Foundation
import CoatySwift

final class ExampleObject: CoatyObject {

    // MARK: - Class registration.

    override class var objectType: String {
        return register(objectType: "hello.coaty.ExampleObject", with: self)
    }

    // MARK: - Properties.

    let myValue: String

     // MARK: Initializers.

    init(myValue: String) {
        self.myValue = myValue
        super.init(coreType: .CoatyObject,
                   objectType: ExampleObject.objectType,
                   objectId: .init(),
                   name: "ExampleObject Name :)")
    }

    // MARK: Codable methods.

    enum CodingKeys: String, CodingKey {
        case myValue
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        myValue = try container.decode(String.self, forKey: .myValue)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        let container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myValue, forKey: .myValue)
    }

}
```

### Class registration

Ensure that the class for your custom Coaty object type is registered with
CoatySwift. This involves two separate registration steps:

1. Define an overriden class variable initializer named `objectType`.
2. Specify the custom object type in the container `Components` as explained
   [previously](#bootstrapping-a-coaty-container).

Note that the registered object type is also useful when observing objects of
this object type, like this:

```swift
try! self.communicationManager
        .observeAdvertise(withObjectType: ExampleObject.objectType)
        .subscribe(onNext: { (event) in
```

The second registration step is necessary because Swift only executes class
variable initializers lazily on first usage. It guarantees that the class
registration performed by `ExampleObject.objectType` has been completed *before*
the first corresponding object is received over the wire and decoded.

### Initializers

The `objectType` parameter specified in the `super.init()` initializer must
equal the registered object type.

### Decodable methods

You need to implement conformance to the
[Codable](https://developer.apple.com/documentation/swift/codable) protocol for
your custom object types. Also, make sure to call the super implementations for
the `init(from:)` initializer as well as the `encode(to:)` method.

If you need to decode or encode a property value of a custom Coaty object type
that can be any valid JSON data, and you don't know the JSON structure in
advance, declare the property type as `AnyCodable`. Using this type, you can
decode or encode mixed-type values in dictionaries and other collections that
require `Decodable` or `Encodable` conformance. For decoding, simply cast the
`value` property of the `AnyCodable` to the expected Swift type.

Likewise, to decode a custom property value that is of any (also variable) Coaty
object type or a collection thereof, use `AnyCoatyObjectDecodable` in the
`container.decode(_ type:)` method. For an example, see the `Snapshot` core type
class which decodes any CoatyObject in its `object` property.

> **Note**
>
>When decoding an object type that has not been registered, an instance of the
>*core type class* is created with all core type properties filled in. Any other
>fields present on the decodable object are added to the `custom` dictionary
>property of the created instance.
>
>This approach is especially useful if you want to observe Coaty objects of
>arbitrary object types for which no Swift class definitions are defined and
>registered in your app.

## FAQ

### Interacting with controllers

A best practice to pass information from a Coaty `Controller` to a
`UIViewController` or other application components can be achieved by
implementing the delegate pattern. Assuming you configured your container and
made it available globally in your application via a variable named
`coatyContainer` you can load a controller to set a delegate as follows:

```swift
import CoatySwift

class ViewController: UIViewController {

    private var controller: ExampleController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.controller = coatyContainer?.getController(name: "ExampleController")

        // Set the ViewController as the delegate.
        self.controller?.delegate = self

        // Call methods of the controller.
        self.controller?.advertiseExample()
    }

    // ...
}
```

### Managing Observable subscriptions

There are several ways how to manage subscriptions of Observables returned by
communication manager's `observe...()` event methods and `publish...()` two-way
event methods:

1. **[Recommended]** You can use the dispose bag provided by a controller to
   dispose of subscriptions *automatically* whenever the communication manager
   is stopped. Just add `.disposed(by: self.disposeBag)` after the `subscribe()`
   method call. Remember that these subscriptions will become disposed if you
   call `communicationManager.stop()`. It is therefore recommended to set up all
   these subscriptions anew in the controller's
   `.onCommunicationManagerStarting()` method which is invoked when calling
   `communicationManager.start()`.
2. Subscriptions are disposed automatically by RxSwift operators whenever the
   observable completes, e.g. as with `take` or `takeUntil`. But if completion
   doesn't happen before the communication manager is stopped, the observable
   still needs to be disposed as recommended above.
3. Subscriptions can be disposed manually as well. You can do this by calling
   `.dispose()` on an active subscription in case you are sure to no longer need
   it.

### Communication State vs Operating State

The communication manager provides two methods to observe operating state
changes via `getOperatingState()` and communication state changes via
`getCommunicationState()`.

Operating states indicate whether the communication manager is currently started
(`started`) or stopped (`stopped`). Communication states indicate the
connectivity state (`offline` or `online`).

When the communication manager is *started*, it tries to connect to the
underlying communication infrastructure. Unless *stopped*, it automatically
tries to reconnect periodically whenever the connection is lost.

When the communication manager is *stopped*, it permanently disconnects from the
underlying communication infrastructure. Afterwards, communication events are no
longer dispatched and emitted. You can start the Communication Manager again
later using the `start()` method.

The communication manager is *started* by

* invoking its `start()` method explicitely,
* specifying the `shouldAutoStart` option as `true` (opt-in),
* specifying the `shouldTryMDNSDiscovery` option as `true` (opt-in).

The communication manager is *stopped* by

* invoking its `stop()` method explicitely,
* invoking the `Container.shutdown()` method.

Starting and stopping actions trigger corresponding state changes on the
operating state Observable. Connections and disconnections trigger corresponding
state changes on the communication state Observable. Note that communication
state changes might happen while the communication manager is in `started`
state. In `stopped` operating state, the communication state is always
`offline`.

Note that operating state changes also trigger invocation of the Controller
lifecycle methods `onCommunicationManagerStarting` or
`onCommunicationManagerStopping`.

Execution of `publish...` and `observe...` event methods by the communication
manager is deferred, if it is either stopped or started but offline, i.e. not
connected currently.

All your *subscriptions* issued while the communication manager is stopped or
offline will be (re)applied when it (re)connects again. *Publications* issued
while the Communication Manager is stopped or offline will be applied only after
the next (re)connect. Publications issued in online state will *not* be
deferred, i.e. not reapplied after a reconnect.

If you stop the communication manager by executing its `stop` method, all
deferred publications and subscriptions will be discarded.

### Inspecting Coaty object types and AnyCodables

For testing and debugging, you can output the external representation of a Coaty
object instance as follows:

```swift
let task = Task(...)
print(task.json)
```

For testing and debugging, you can output the external representation of an
`AnyCodable` as follows:

```swift
let parameters: [String: AnyCodable] = ["on": .init(true),
                                        "color": .init([255, 140, 0, 1]]),
                                        "luminosity": .init(0.75),
                                        "switchTime": .init(10)]
print(PayloadCoder.encode(parameters))
```

### Distributed lifecycle management

To realize distributed lifecycle management for Coaty agents, the agent
container is assigned a unique identity object to be accessible by all
controllers and the communication manager.

Whenever the communication manager is started, it advertises the agent's
identity and makes it discoverable. Whenever the communication manager is
stopped (normally or abnormally), its agent's identity is deadvertised. This
way, other agents can track the agent's lifecycle.

### Event echo suppression

By design, there is no echo suppression of communication events. The
communication manager dispatches *any* incoming event to every controller that
*observes* it, even if the controller published the event itself.

If echo suppression of communication events is required for your custom
controller, place it into its *own* container and *filter out* observed events
whose event source ID equals the object ID of the container's identity, like
this:

```swift
self.communicationManager
    .observeDiscover()
    .filter { (discoverEvent) -> Bool in
        return discoverEvent.sourceId != self.container.identity.objectId
    }
    .subscribe(onNext: { (discoverEvent)
        // Handle non-echo events only.
    })
```

### Terminology

It is important to remember that a CoatySwift `Controller` has nothing to do
with the regular `UIViewController`, and likewise, the `container` variable used
in the `decode` and `encode` methods is not related in any way to the Coaty
`Container` object.

## Additional resources

We would like to point you to additional resources if you want to dig deeper
into CoatySwift and Coaty itself.

- [Tutorial](https://coatyio.github.io/coaty-swift/tutorial/index.html) - shows
  how to set up a minimal CoatySwift app.
- [Coaty Examples](https://github.com/coatyio/coaty-examples) - you can find
  additional examples in the `swift` sections of the coaty-examples repo on
  GitHub.
- [API Documentation](https://coatyio.github.io/coaty-swift/api/index.html) - the
  source code documentation of public types and members of the CoatySwift framework.
- [Design Rationale](https://coatyio.github.io/coaty-swift/man/design-rationale/) - in case
  you want to know why certain things have been implemented in a particular way
  in the CoatySwift implementation.
- [Xcode Quick Help](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/SymbolDocumentation.html) - when
  you are directly writing the code and wondering what a certain function
  does.

The following resources are part of Coaty JS, but the CoatySwift API aims to be
as close as possible to the reference implementation. Therefore, we suggest
checking out these resources as well:

- [In a Nutshell](https://coaty.io/nutshell)
- [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/)
- [Coaty JS Developer Guide](https://coatyio.github.io/coaty-js/man/developer-guide/)
- [Coaty JS Project](https://github.com/coatyio/coaty-js)
