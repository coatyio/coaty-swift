# Coaty Swift
[![Powered by Coaty](https://img.shields.io/badge/Powered%20by-Coaty-FF8C00.svg)](https://coaty.io)
[![Version](https://img.shields.io/cocoapods/v/CoatySwift.svg?style=flat)](https://cocoapods.org/pods/CoatySwift)
[![Platform](https://img.shields.io/cocoapods/p/CoatySwift.svg?style=flat)](https://cocoapods.org/pods/CoatySwift)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

__CoatySwift__ is a [Coaty](https://coaty.io/) implementation written in Swift 5.0. The CoatySwift package provides the cross-platform implementation targeted at __iOS__ (8.0+) and __macOS__ (10.14+) applications running as native application code.

CoatySwift comes with complete source code documentation, a Developer Guide, and best-practice examples.

# What is Coaty?

The Coaty framework enables realization of collaborative IoT applications and scenarios in a distributed, decentralized fashion. A *Coaty application* consists of *Coaty agents* that act independently and communicate with each other to achieve common goals. Coaty agents can run on IoT devices, mobile devices, in microservices, cloud or backend services.

It provides a production-ready application and communication layer foundation for building collaborative IoT applications in an easy-to-use yet powerful and efficient way.
The key properties of the CoatySwift framework include:

* a lightweight and modular object-oriented software architecture favoring a resource-oriented and declarative programming style,
* standardized event based communication patterns on top of an open publish-subscribe
  messaging protocol (currently [MQTT](https://mqtt.org)),
* and a platform-agnostic, extensible object model to discover, distribute, share,
  query, and persist hierarchically typed data.

## Learn how to use

### Requirements

| Deployment Target     | Compatibility     |
|-------------------    |---------------    |
| iOS                   | 8.0+              |
| macOS                 | 10.14+            |

### Documentation 

If you are new to CoatySwift and would like to learn more, we recommend checking out the following resources:

- __[Developer Guide](docs/DeveloperGuide.md)__ - This guide explains how to build a Coaty application with CoatySwift.
- __Source Code Documentation__ - This is the generated sourcecode documentation of the most important functions.
- __[Design Decisions and Rationale](docs/CoatySwiftInternals.md)__ - in case you want to know why certain things have been implemented in a particular way in the CoatySwift implementation. 

### Getting started

To build and run Coaty agents with the CoatySwift technology stack you need XCode 10.2 or higher. CoatySwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CoatySwift'
```

### Examples

To run the example project, clone the repo, and run `pod install` from the Example directory first. We provide two additional examples located in the `Example for CoatySwift` folder:

- __`Hello World`__ which is a CoatySwift implementation of the [Hello World](https://github.com/coatyio/coaty-examples/tree/master/hello-world/js) example. This example demonstrates the basic use of communication event patterns to exchange typed data in a distributed Coaty application.
- __`Switch Light`__ which is a (simplified) CoatySwift implementation of Coaty JS [Remote Operations](https://github.com/coatyio/coaty-examples/tree/master/remote-operations/js).
- Additional examples can be found in the `swift` section of `coaty-examples`, including a macOS version of the Hello World example.

## Contributing

If you like CoatySwift, please consider &#x2605; starring [the project on github](https://github.com/coatyio/coaty-swift). Contributions to the CoatySwift framework are welcome and appreciated. 

- Please follow the recommended practice described in [CONTRIBUTING.md](CONTRIBUTING.md). This document also contains detailed information on how to build, test, and release the framework.


## License

Code and documentation copyright 2019 Siemens AG.

Code is licensed under the [MIT License](https://opensource.org/licenses/MIT).

Documentation is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).


### Third Party Licenses

- RxSwift [MIT License](https://github.com/ReactiveX/RxSwift/blob/master/LICENSE.md)
- CocoaMQTT [MIT License](https://github.com/emqtt/CocoaMQTT/blob/master/LICENSE)
- XCGLogger [MIT License](https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt)
- Quick [Apache License 2.0](https://github.com/Quick/Quick/blob/master/LICENSE)
- Nimble [Apache License 2.0](https://github.com/Quick/Nimble/blob/master/LICENSE)
- AnyCodable [MIT License](https://github.com/Flight-School/AnyCodable/blob/master/LICENSE.md)

## Credits

Last but certainly not least, a big *Thank You!* to the folks who designed and implemented CoatySwift:

* Sandra Grujovic
* Johannes Rohwer [@johannesrohwer](https://github.com/johannesrohwer)
