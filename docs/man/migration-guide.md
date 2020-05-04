---
layout: default
title: CoatySwift Documentation
---

# CoatySwift Migration Guide

The jump to a new major release of Coaty involves breaking changes to the
CoatySwift framework API. This guide describes what they are and how to upgrade
your CoatySwift application to a new release.

## Coaty 1 -> Coaty 2

Coaty 2 incorporates experience and feedback gathered with Coaty 1. It pursues
the main goal to streamline and simplify the framework API, to get rid of unused
and deprecated functionality, and to prepare for future extensions.

Among other refactorings, CoatySwift 2 carries breaking changes regarding object
types, distributed lifecycle management, and the communication protocol while
keeping the essential set of communication event patterns. Therefore, CoatySwift
2 applications are no longer backward-compatible and interoperable with
CoatySwift 1 applications.

CoatySwift 1 is still available as CocoaPod `CoatySwift', '~> 1.0'`. CoatySwift
2 is deployed as Cocoapod `CoatySwift', '~> 2.0'`.

To update your application to CoatySwift 2, follow the migration steps described
next.

### Before migrating

* In your project's `Podfile` bump pod `CoatySwift` to `'~> 2.0'`.
* Run `pod update` and open the `xcworkspace` in Xcode for further changes.

### Changes in `Configuration` options

* The `Configuration.common` property is now optional.
* Stop defining `Configuration.common.associatedUser` as this property has been
  removed. If needed, define and access your User object in
  `Configuration.common.extra`.
* Stop defining `Configuration.common.associatedDevice` as this property has
  been removed.

### Changes in Coaty object types

Definition and handling of Coaty object types has been greately simplified
by getting rid of the notion of a Coaty object family:

* Stop defining Coaty object families for your custom types as this feature has
  been removed. Instead, register classes for your custom Coaty object types as
  described
  [here](https://coatyio.github.io/coaty-swift/man/developer-guide/#custom-object-types).
  Additionally, register your custom object types in the container `Components`
  as described
  [here](https://coatyio.github.io/coaty-swift/man/developer-guide/#bootstrapping-a-coaty-container).
* Stop specifying generic type parameters for `Container`, `Components`,
  `Controller`, and all event classes, i.e. `AdvertiseEvent`, `ChannelEvent`,
  etc.
* Stop using `DynamicContainer`, `DynamicComponents`, `DynamicController`,
  `DynamicSnapshot` and all dynamic event classes, such as
  `DynamicAdvertiseEvent` as this feature has been incorporated into
  `Container`, `Components` etc.

Additional changes to Coaty core types:

* Stop using `Config` as this core type has been removed. If needed, define an
  equivalent object type in your application code.
* Stop using `Device` as this object type has been removed.
* Stop using `CoatyObject.assigneeUserId` as this property has been removed.
* Stop using `Task.workflowId` as this property has been removed. If needed,
  define an equivalent property in your custom task type.
* Use new property `Task.assigneeObjectId` to reference an object, e.g. a user
  or machine, that this task is assigned to.
* Change type of `Task.requirements` property to consist of key-value pairs.
* Stop specifying a generic type parameter for `Snapshot`.
* Optional property `logLabels` has been added to `Log` object type. Useful in
  providing multi-dimensional context-specific data along with a log.

### Changes in `Container`

* If you call `Container.resolve()` remove the `objectFamily` argument.
* If you call `Container.registerController()` or
  `DynamicContainer.registerController()` replace the third argument
  `ControllerConfig` by `ControllerOptions`.

### Changes in distributed lifecycle management

To realize distributed lifecycle management for Coaty agents in Coaty 1,
individual identity objects were assigned to the communication manager as well
as to each controller, in order to be advertised and to be discoverable by other
agents. The identity objects were also used to provide event source IDs for
communication events to realize echo suppression on the controller level so that
events published by a controller could never be observed by itself.

In Coaty 2, distributed lifecycle management has been simplified and made more
efficient:

* The agent container is assigned a unique identity object to be accessible by
  all controllers and the communication manager. Controllers and the
  communication manager no longer own separate identities.
* The container's identity is *always* advertised and discoverable to support
  distributed lifecycle management. You can no longer disable this behavior.
* When publishing or observing communication events, an identity object no
  longer needs to be specified as event source or event target, respectively.
* By design, echo suppression of communication events has been revoked. The
  communication manager dispatches *any* incoming event to every controller that
  *observes* it, even if the controller published the event itself.

Upgrade to the new approach as follows:

* Stop using `Controller.eventFactory` to create communication events as the
  event factory has been removed. Instead, directly call static creation methods
  of a communication event type, e.g. `AdvertiseEvent.with(object:)`.
* Stop configuring identity properties in `CommunicationOptions.identity` as
  this property has been removed. Instead, customize properties of the
  container's identity object in the new `CommonOptions.agentIdentity` property.
* Use `CommunicationManager.identity` or `Container.identity` to access the
  container's identity object. From within a controller use
  `self.container.identity`.
* Stop using `CommunicationOptions.shouldAdvertiseIdentity` and
  `CommunicationOptions.shouldAdvertiseDevice` as these properties has been
  removed.
* Stop using `Controller.identity` as this getter has been removed. Use
  `self.container.identity` instead.
* Stop defining `Controller.initializeIdentity()` as this method has been
  removed.
* Stop using `ControllerOptions.shouldAdvertiseIdentity` as this property has
  been removed.
* Stop defining `Controller.onContainerResolved()` as this method has been
  removed. Perform these side effects in `Controller.onInit`, accessing the
  container by `self.container`.
* Stop expecting your communication logic to track the identity of controllers.
  Only identity of containers can be observed or discovered.

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

### Changes in communication

* Stop using `CommunicationEvent.source` as this getter has been removed.
  Use `CommunicationEvent.sourceId` instead.
* Stop using `CommunicationEvent.userId` as this getter has been removed.
* Stop using `OperatingState.initial`, `OperatingState.starting` and
  `OperatingState.stopping` as these enum members have been removed. Use
  `OperatingState.Started` and `OperatingState.Stopped` instead.
* Broker host and port settings are ignored whenever mDNS broker
  discovery is enabled by `MQTTClientOptions.shouldTryMDNSDiscovery`.
* The MQTT topic structure has been optimized. Your application code is not
  affected by this change.
* You can now specify the MQTT QoS level for all publications, subscriptions,
  and last will messages in `CommunicationOptions.mqttClientOptions.qos`. The
  default and recommended QoS level is 0.
* For debugging, you can now enable logging of low-level MQTT protocol messages
  by setting `CommunicationOptions.mqttClientOptions.shouldLog` to `true`.
* Replace `CommunicationManager.startClient()` and
  `CommunicationManager.endClient()` by `CommunicationManager.start()` and
  `CommunicationManager.stop()`.
* A [namespacing
  concept](https://coatyio.github.io/coaty-js/man/developer-guide/#namespacing)
  has been added to isolate different Coaty applications (see
  `CommunicationOptions.namespace` and
  `CommunicationOptions.shouldEnableCrossNamespacing`). Communication events are
  only routed between agents within a common namespace.

#### Changes in Update event

We abandon *partial* Update events in favor of full Update events where you can
choose to observe Update events for a specific core type or object type,
analogous to Advertise events. This reduces messaging traffic because Update
events are no longer submitted to all Update event observers but only to the
ones interested in a specific type of object.

* Stop publishing Update events using `UpdateEventFactory.withPartial()` or
  `UpdateEventFactory.withFull()`. Instead, use `UpdateEvent.with(object:)`.
* Stop using `UpdateEventData.isPartialUpdate`, `UpdateEventData.isFullUpdate`,
  `UpdateEventData.objectId` and `UpdateEventData.changedValues` as these
  getters have been removed.
* Stop observing Update events with `CommunicationManager.observeUpdate()` as
  this method has been removed. Use either
  `CommunicationManager.observeUpdateWithCoreType(coreType:)` or
  `CommunicationManager.observeUpdateWithObjectType(objectType:)`.

#### Changes in Raw event

* `CommunicationManager.observeRaw()` no longer emits messages for non-raw Coaty
  communication patterns.
