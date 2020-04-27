# Changelog

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
