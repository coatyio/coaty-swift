# Changelog

<a name="2.4.0"></a>
## [2.4.0](https://github.com/coatyio/coaty-swift/compare/2.3.1...2.4.0) (2022-10-04)

This release adds support for Swift Package Manager and cleans up the library structure. Also fixes some problems with updated dependencies.

### Features

* **Swift Package Manager:** add supprt for swift package manager; fix dependencies error; reorganize the project structure
  ([a8c741d](https://github.com/coatyio/coaty-swift/commit/a8c741d))

<a name="2.3.1"></a>
## [2.3.1](https://github.com/coatyio/coaty-swift/compare/2.3.0...2.3.1) (2021-01-20)

This release adds decentralized logging functionality to the Controller class.

### Features

* **Decentralized logging:** extend base controller class with decentralized logging functionality; add corresponding test and a new section in developer guide
  ([4e333e3](https://github.com/coatyio/coaty-swift/commit/4e333e3))

<a name="2.3.0"></a>
## [2.3.0](https://github.com/coatyio/coaty-swift/compare/2.2.1...2.3.0) (2021-01-19)

This release adds yet unsupported SensorThings API to CoatySwift.

### Features

* **SensorThings API:** implement sensor things with corresponding tests
  ([ce98ff9](https://github.com/coatyio/coaty-swift/commit/1178230))

<a name="2.2.1"></a>
## [2.2.1](https://github.com/coatyio/coaty-swift/compare/2.2.0...2.2.1) (2020-11-11)

This minor release adds ObjectLifecycleController class to CoatySwift.

### Features

* **ObjectLifecycleController:** implement ObjectLifecycleController class with a corresponding test.
  ([9af8ca8](https://github.com/coatyio/coaty-swift/commit/9af8ca8))

<a name="2.2.0"></a>
## [2.2.0](https://github.com/coatyio/coaty-swift/compare/2.1.0...2.2.0) (2020-09-11)

This release adds yet unsupported IO Routing feature to CoatySwift.

### Features

* **IO Routing:** implement io routing
  ([1178230](https://github.com/coatyio/coaty-swift/commit/1178230))

<a name="2.1.0"></a>
## [2.1.0](https://github.com/coatyio/coaty-swift/compare/2.0.1...2.1.0) (2020-06-24)

This minor release adds yet unsupported features in communication patterns: object matching for query-retrieve event
and object filtering for call-return event. Additionally the CoatySwift framework is now augmented with unit tests
implemented as an XCode target.

### Features

* **Raw events:** extend `CommunicationManager.publishRaw` to enable raw bytes array publishing. `CommunicationManager.publishRaw(:topic:value)` is now deprecated, use `CommunicationManager.publishRaw(:topic:withString)` instead
  ([70f2dc0](https://github.com/coatyio/coaty-swift/commit/70f2dc0))
* **Call event:** implement filter matching for Call event
  ([611d455](https://github.com/coatyio/coaty-swift/commit/611d455))
* **Query event:** implement `CommunicationManager.observeQuery` functionality
  ([b556ed7](https://github.com/coatyio/coaty-swift/commit/b556ed7))
* **Object matcher:** implement object matcher with necessary changes to AnyCodable; 
  add tests for ObjectMatcher
  ([a5a54d2](https://github.com/coatyio/coaty-swift/commit/a5a54d2))

<a name="2.0.1"></a>
## [2.0.1](https://github.com/coatyio/coaty-swift/compare/2.0.0...2.0.1) (2020-04-27)

This patch release fixes an issue with custom Coaty object types not properly
registered although registration code has been specified in the Swift class
definition.

### Bug Fixes

* **Runtime/Components:** add `objectTypes` argument to `Component` initializer to
  register application-specific object types
  
  *BREAKING CHANGE*: specify all custom Coaty object types with
  `Components.objectTypes` as described in the [developer
  guide](https://coatyio.github.io/coaty-swift/man/developer-guide/#bootstrapping-a-coaty-container)
  ([fc92815](https://github.com/coatyio/coaty-swift/commit/fc92815))

<a name="2.0.0"></a>
# [2.0.0](https://github.com/coatyio/coaty-swift/compare/1.0.1...2.0.0) (2020-03-10)

This major release upgrades the CoatySwift framework API to Coaty 2. To update
your application, follow the migration steps described in this [migration
guide](https://coatyio.github.io/coaty-swift/man/migration-guide/).

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

<a name="1.0.1"></a>
## [1.0.1](https://github.com/coatyio/coaty-swift/compare/1.0.0...1.0.1) (2019-10-29)

This patch release fixes an Xcode build issue concerning macOS deployments and
some issues related to communication events and object types.

### Bug Fixes

* **Model/Core Types:** rename `Component` to `Identity` in order to make
  CoatySwift macOS compatible
  
  *BREAKING CHANGE*: rename all occurrences of Coaty
  object type `Component` with `Identity` to avoid name conflict in Objective-C
  macOS runtime
  ([fac20c1](https://github.com/coatyio/coaty-swift/commit/fac20c1))
* **Common:** make `CoatyUUID` equatable
  ([3a2b1d7](https://github.com/coatyio/coaty-swift/commit/3a2b1d7))
* **Common,Model:** remove unneeded `NSObject` dependency from `CoatyUUID` and
  `CoatyObject`
  ([ccd4aaf](https://github.com/coatyio/coaty-swift/commit/ccd4aaf))
* **Common,Model:** remove unnecessary `objc` members
  ([9d02133](https://github.com/coatyio/coaty-swift/commit/9d02133))
* **Common:** add missing decodings for `CoatyUUID` and `UUID` in
  `KeyedDecodingContainer`
  ([cc4115c](https://github.com/coatyio/coaty-swift/commit/cc4115c))
* **Communication/Events:** correct parameter validation logic of Discover event
  ([a399b43](https://github.com/coatyio/coaty-swift/commit/a399b43))

<a name="1.0.0"></a>
# [1.0.0](https://github.com/coatyio/coaty-swift/tree/1.0.0) (2019-10-22)

Initial release of the CoatySwift framework.
