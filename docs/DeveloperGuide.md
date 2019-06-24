# CoatySwift Developer Guide

This document covers everything a developer needs to know about using the CoatySwift framework to implement collaborative IoT applications targeting iOS or macOS. We assume you know nothing about CoatySwift before reading this guide.

> __NOTE__: We would like to note that more information about the internals and basics of the __Coaty__ framework can be found in [Coaty Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/). The [Coaty JS Developer Guide](https://coatyio.github.io/coaty-js/man/developer-guide/), even though written in NodeJS, shares many similarities with CoatySwift and we recommend checking out this guide as well if you would like to dig deeper, as it is documented in a more detailed way and provides more extensive features.


## Table of Contents

[TOC]

## Necessary Background Knowledge

In order to be able to use CoatySwift the way it is intended to, we asume you are familiar with the following programming concepts:

- [ReactiveX](http://reactivex.io/) - Describes the basics on how incoming asynchronous messages are handled in the CoatySwift framework. In particular, CoatySwift is using [RxSwift](https://github.com/ReactiveX/RxSwift), the Swift version of ReactiveX.

## Coaty(Swift) Terminology

- In Coaty, every device that communicates with other devices is called an __agent__. So simply speaking, we consider an iOS application or a macOS application to be exactly one agent.

- Every agent holds a __container__. A container basically defines entry and exit points for a Coaty agent and provides lifecycle management for controllers.

- Every container has 1...n __controllers__. A controller encapsulates business logic, and most importantly, all access methods related to any form of networking that you will be using in your application will be called from inside a controller. ___These controllers are in no way related to Apple's UIViewControllers!___

- Every container holds exactly one __communication manager__. A communication manager lets you publish and subscribe to messages, basically handling all types of communication flow.

- Every container has a __configuration__: Defines options for the container, as well as the controllers. There are many options available. You can check out example configs in the sections below, as well as in the examples located in __TODO: WRONG LINK__ [Examples](aaa).



---

> [color=#FF8C00] __TL;DR Terminology__
> - Every iOS/macOS app is a Coaty __agent__
> - Every Coaty agent has one __container__
> - Every container has
>     -    1...n __controllers__
>     -    1 __configuration__ 
>     -    1 __communication manager__


## Setup Instructions and Requirements

- To build and run Coaty agents with the CoatySwift technology stack you need [XCode](https://developer.apple.com/xcode/) 10.2 or higher.

- __Set up a MQTT Broker__: All messages that are exchanged between agents are sent over a broker - so remember to set up and have a MQTT Broker running. We recommend checking out the following brokers:
- [Mosquitto](Mosquitto)
- [HiveMQ](https://www.hivemq.com/)
- [VerneMQ](https://vernemq.com/)

- __Integrate CoatySwift in your project__: CoatySwift is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile, and run `pod install` or `pod update`afterwards:

```ruby
pod 'CoatySwift'
```


## Communication Patterns

> [color=#FF8C00] Citing the [Coaty Protocol Documentation](https://coatyio.github.io/coaty-js/man/communication-protocol/#events-and-event-patterns):

The framework uses a minimum set of predefined events and event patterns to discover, distribute, and share object information in a decentralized application:

- __Advertise an object__: Broadcast an object to parties interested in objects of a specific core or object type.

- __Deadvertise an object by its unique ID__: Notify subscribers when capability is no longer available; for abnormal disconnection of a party, last will concept can be implemented by sending this event.

- __Channel Broadcast__ objects to parties interested in any kind of objects delivered through a channel with a specific channel identifier.

- __Discover - Resolve__: Discover an object and/or related objects by external ID, internal ID, or object type, and receive responses by Resolve events.


- __Query - Retrieve__: Query objects by specifying selection and ordering criteria, receive responses by Retrieve events.

- __Update - Complete__: Request or suggest an object update and receive accomplishments by Complete events.


- __Call - Return__: Request execution of a remote operation and receive results by Return events.

> [color=#FF8C00] __NOTE__: Although Coaty itself also specifices __IoValue__ and __Associate__ events, these are **not** included in the CoatySwift versions and therefore are left out of the documentation.

We differentiate between __one-way__ and __two-way__ events. Advertise, Deadvertise and Channel are one-way events. Discover-Resolve, Query-Retrieve, Update-Complete and Call-Return are two-way events. 

We also differentiate between __publishing__ events or __subscribing__ to them. When publishing an event, simply put, you send a message over the broker. When subscribing to (or observing) an event, you sign up to receive messages over the broker. 

In the following examples, we will show you how you can publish and subscribe one-way events as well as two-way events.

### Publish an Advertise (one-way event)

Note that this procedure is almost the same for publishes of Deadvertise and Channel events.

```swift
// Create the object.
let myExampleObject = CoatyObject(coreType: .CoatyObject,
objectType: "com.siemens.iot.my-example-object", 
objectId: .init(), 
name: "My amazing object")


// Create an event by using the event factory.
let event = self.eventFactory.AdvertiseEvent
.withObject(eventSource: self.identity, object: myExampleObject)

// Publish the event by using the communication manager.
try? self.communicationManager.publishAdvertise(advertiseEvent: event, 
ventTarget: self.identity)

```

### Observing Advertises (one-way event)

Note that this procedure is almost the same for observing Deadvertise and Channel events.

```swift
try? self.communicationManager
.observeAdvertiseWithCoreType(eventTarget: self.identity, coreType: .Task)
.subscribe(onNext: { (advertiseEvent) in
guard let task = advertiseEvent.data.object as? Task else {
print("Could not parse the advertise event as task.")
return
}

// Do something with this task...
print(task.creatorId)

})
.disposed(by: disposeBag)

```

### Publish a Discover event (two-way event)

Note that this procedure is almost the same for Query-Retrieve, Update-Complete, and Call-Return events.

```swift
```


### Observe a Resolve event (two-way event)

Note that this procedure is almost the same for Query-Retrieve, Update-Complete, and Call-Return events.

```swift
```
