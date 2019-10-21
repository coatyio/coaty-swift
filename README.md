# Coaty Swift

[![Powered by Coaty](https://img.shields.io/badge/Powered%20by-Coaty-FF8C00.svg)](https://coaty.io)
[![Swift version](https://img.shields.io/badge/swift-5-FF4029.svg)](https://developer.apple.com/swift/)
[![Version](https://img.shields.io/cocoapods/v/CoatySwift.svg?style=flat)](https://cocoapods.org/pods/CoatySwift)
[![Platform](https://img.shields.io/cocoapods/p/CoatySwift.svg?style=flat)](https://cocoapods.org/pods/CoatySwift)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

__CoatySwift__ is a [Coaty](https://coaty.io/) implementation written in Swift 5.
The CoatySwift package provides the cross-platform implementation targeted at
__iOS__, __iPadOS__, and __macOS__ applications running as native application
code.

CoatySwift comes with complete API documentation, a developer guide, a tutorial,
and best-practice examples.

## What is Coaty

Using the Coaty [koʊti] framework as a middleware, you can build distributed
applications out of decentrally organized application components, so called
*Coaty agents*, which are loosely coupled and communicate with each other in
(soft) real-time. The main focus is on IoT prosumer scenarios where smart agents
act in an autonomous, collaborative, and ad-hoc fashion. Coaty agents can run on
IoT devices, mobile devices, in microservices, cloud or backend services.

Coaty provides a production-ready application and communication layer foundation
for building collaborative IoT applications in an easy-to-use yet powerful and
efficient way. The key properties of the CoatySwift framework include:

* a lightweight and modular object-oriented software architecture favoring a
  resource-oriented and declarative programming style,
* standardized event based communication patterns on top of an open
  publish-subscribe messaging protocol (currently [MQTT](https://mqtt.org)),
* and a platform-agnostic, extensible object model to discover, distribute,
  share, query, and persist hierarchically typed data.

## Learn how to use

If you are new to CoatySwift and would like to learn more, we recommend checking
out the following resources:

* [Tutorial](https://coatyio.github.io/coaty-swift/tutorial/index.html) - shows
  how to set up a minimal CoatySwift app.
* [Developer Guide](https://coatyio.github.io/coaty-swift/man/developer-guide/) - explains
  how to develop a CoatySwift app.
* [API Documentation](https://coatyio.github.io/coaty-swift/swiftdoc/index.html) - the
  source code documentation of public types and members of the CoatySwift framework.
* [Design Rationale](https://coatyio.github.io/coaty-swift/man/design-rationale/) - in case
  you want to know why certain things have been implemented in a particular way
  in the CoatySwift implementation.

## Getting started

To build and run Coaty agents with the CoatySwift technology stack you need
XCode 10.2 or higher. CoatySwift is available through
[CocoaPods](https://cocoapods.org). To install it, simply add the following line
to your Podfile:

```ruby
pod 'CoatySwift'
```

CoatySwift is compatible with the the following deployment targets:

| Deployment Target     | Compatibility     |
|-------------------    |---------------    |
| iOS                   | 8.0+              |
| macOS                 | 10.14+            |

## Examples

If you want a short, concise look into CoatySwift, feel free to check out the
[CoatySwift Tutorial](https://coatyio.github.io/coaty-swift/tutorial/index.html)
with a step-by-step guide on how to set up a basic CoatySwift application. The
source code of this tutorial can be found in the
[Example](https://github.com/coatyio/coaty-swift/tree/master/Example) Xcode
folder of the CoatySwift repo. Just clone the repo, run `pod install` on the
Example folder and open the new `xcworkspace` in Xcode.

You can find additional examples in the `swift` sections of the
[coaty-examples](https://github.com/coatyio/coaty-examples) repo on GitHub. You
will find three Xcode projects there: the `Hello World`, `Switch Light` and
`Dynamic` project. They are interoperable with the corresponding Coaty JS
examples and intended to be used along with them. Note that `Hello World` and
`Switch Light` are the blueprint examples for how to design CoatySwift
applications. The `Dynamic` example shows how dynamic components provide a less
static and less type safe version of CoatySwift to deal with Coaty object types
that are not yet known at compile time. This feature is currently experimental.

## Contributing

If you like CoatySwift, please consider &#x2605; starring [the project on
github](https://github.com/coatyio/coaty-swift). Contributions to the CoatySwift
framework are welcome and appreciated.

Please follow the recommended practice described in
[CONTRIBUTING.md](https://github.com/coatyio/coaty-swift/blob/master/CONTRIBUTING.md).
This document also contains detailed information on how to build, test, and
release the framework.

## License

Code and documentation copyright 2019 Siemens AG.

Code is licensed under the [MIT License](https://opensource.org/licenses/MIT).

Documentation is licensed under a [Creative Commons Attribution-ShareAlike 4.0
International License](http://creativecommons.org/licenses/by-sa/4.0/).

The following list displays all the relevant licenses for third-party software
CoatySwift depends on:

* RxSwift [MIT License](https://github.com/ReactiveX/RxSwift/blob/master/LICENSE.md)
* CocoaMQTT [MIT License](https://github.com/emqtt/CocoaMQTT/blob/master/LICENSE)
* XCGLogger [MIT License](https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt)
* AnyCodable [MIT License](https://github.com/Flight-School/AnyCodable/blob/master/LICENSE.md)

## Credits

Last but certainly not least, a big *Thank You!* to the folks who designed and
implemented CoatySwift:

* Sandra Grujovic [@melloskitten](https://github.com/melloskitten)
* Johannes Rohwer [@johannesrohwer](https://github.com/johannesrohwer)
