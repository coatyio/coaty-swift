# Behind the Scenes: CoatySwift Internals

This document aims to explain some of the rationale behind our decisions when building CoatySwift, the problems we faced, and how we decided to solve them. Several sections include coding examples and provide background explanations on why things had and have to be done in a certain way to make CoatySwift do _exactly_ what you want it to do.

## Table of Contents

* [Porting Dynamic- to Static Types](#The-Pleasure-and-Pain-of-Static-Languages)
    * [Codable Subclassing with Generics](#Codable-Subclassing-with-Generics)
    * [Object Families](#The-importance-of-ObjectFamily)
    * [Decoding and Encoding - A Complex Process](#Decoding-and-Encoding---A-Complex-Process)
    * [Type Erased Communication Manager](#Type-Erased-Communication-Manager)


## The Pleasure and Pain of Static Languages 
We decided to use the [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol for all object encoding and decoding tasks. The `Codable` protocol is part of the Swift standard library and is recommended to be used for object conversion from and to JSON. 

> Swift is a __statically typed language__, which makes easy interaction with JSON objects non-trivial. 

By implementing `Codable` we avoid third-party dependencies such as [`SwiftyJSON`](https://github.com/SwiftyJSON/SwiftyJSON). `SwiftyJSON`, for example, could only provide a limited form of type safety in our context, and the user would be left to manually parse objects and create them 'on the go'. `Codable`, on the other hand, allows a standardized interaction with the object parsing API and enables the application programmer to extend the predefined object types by overwriting the `encode(to:) / init(from:)` methods and calling their base implementations (see HelloWorldTask). Relying on traditional JSON parsing frameworks would require to reimplement this functionality entirely for each custom object. Working with untyped JSON objects in Swift is another way to use JSON data. This approach casts the data to `[String: Any]` dictionaries  and eliminates
the power of compiler based type checks what makes this approach inferior to our implementation.

> NOTE: 
> `Codable` is relatively new and under active development. For future releases we hope for better support of heterogenous data structures to simplify the decoding of custom Coaty objects (see rationale on `CommunicationManager/ObjectFamily`).



### Codable Subclassing with Generics
 Consider the following: `Animal` is a super class of the objects `Cat` and `Dog`. We define our generic type `T` when decoding / encoding to be of Type `Animal`. When decoding / encoding an object holding this `T` type, Swift is not able to decode it into its subclasses, such as `Cat` or `Dog` in a straightforward way. Instead, it always decodes / encodes the object as a type of `Animal`, ultimately not letting us access subclass-specific fields and decoding / encoding them properly. 
> SOLUTION: 
> As proposed in this [post](https://medium.com/@kewindannerfjordremeczki/swift-4-0-decodable-heterogeneous-collections-ecc0e6b468cf) by Kewin Dannerfjord Remeczki, we trick the compiler by adding a `ClassWrapper`, an object that wraps around the decodable class (and its subclasses), which we can then map to the correct type.

### The importance of `ObjectFamily`

As previously mentioned, Swift is a statically typed language and thus does not provide an easy option of creating dynamic types on the go. This limits us greatly when decoding or encoding objects in the CoatySwift framework, because the application programmer can introduce completely new types that need to be sent over the wire. 

We have tried several different options, but so far, have found only one way to integrate application-time objects into CoatySwift while considering the constraints given by `Codable` as well as Swift itself. We therefore require a __mapping between custom objects__ and their __corresponding class implementations__. This file is what we call a custom implementation of the `ObjectFamily`, which gives us the possibility to encode and decode new objects which have been introduced by the application programmer. Below you can see an example for a custom ObjectFamily. You can also find it in the Example project under `Example/CoatySwift/CustomCoatyObjectFamily.swift`. 
>NOTE: 
>We assume that your custom `DemoObject.swift` is a subclass of the built-in `CoatyObject.swift`. You can find this file similarly under `Example/CoatySwift/Demo+CoatyObject.swift`. 

```swift
/// If you wish to receive ChannelEvents that hold your personal, customised CoatyObjects
/// (e.g. objects that extend the basic CoatyObject class, such as the `DemoMessage` object in
///  `Demo+CoatyObject`) you have to create your own class family that holds references to these
/// custom objectTypes. This way, CoatySwift can infer the types of your objects properly when
/// decoding messages received over a channel.
/// - NOTE: If you wish to see another example for a ClassFamily, please see `CoatyObjectFamily`
/// in the CoatySwift framework.
enum CustomCoatyObjectFamily: String, ObjectFamily {
    
    /// This is an exemplary objectType for your custom CoatyObject.
    case demoObject = "org.example.coaty.demo-object"

    /// Define the mapping between objectType and your custom CoatyObject class type.
    /// For every objectType enum case you need a corresponding Swift class matching.
    func getType() -> AnyObject.Type {
        switch self {
        case .demoObject:
            return DemoObject.self
        }
    }
}
```

This information is also explicitly needed when bootstrapping CoatySwift applications and resolving controllers, as we need information about this object family to properly decode and encode objects being published or received in the `CommunicationManager`. An example for this can be found in `Example/Hello World/ HelloWorldExampleViewController.swift`:
```swift
        _ = Container.resolve(components: components,
                              configuration: configuration,
                              objectFamily: HelloWorldObjectFamily.self)
```
Here, the `HelloWorldObjectFamily` refers to custom implementations needed for the Hello World application to run, such as the `HelloWorldTask`.

### Decoding and Encoding - A Complex Process
Using the information gathered from the  `ObjectFamily` subclass given by the application programmer, we are able to provide type safety even with custom objects. We have adjusted our decoding and encoding mechanisms to work in the following way:

1. __Encode / Decode via Application-Specific Object Family__

First, our implementation tries to match an object against one of the classes provided by the application programmers in order to encode / decode it. If this fails, go to __2.__

2. __Fallback Solution__

If none of the custom objects matched the object we want to encode / decode, check whether it's a built-in CoatySwift type. You can find all generic CoatyObjects in `CoatySwift/Classes/Common/CoatyObjectFamily.swift`. If even this fails, a coding error will be thrown, as there is no type information given to us that can help us to infer the actual type of the object.



### Type Erased Communication Manager

The `CommunicationManager` has a generic implementation that requires an `ObjectFamily` to instantiate it. By using this generic approach we are able to offer a slimmer API to the application programmer that needs less compiler type hints for operations such as for calls to `.observeChannel()` that expect non-standard Coaty objects as return types. By using the generic implementation the knowledge about the custom types can now be directly encoded into the `CommunicationManager` instance. In order to be able to provide the customized `CommunicationManager` instance to each controller, we are required to use __type erasure__ in the form of the `AnyCommunicationManager` that is a super class to all generic `CommunicationManagers`. As noted in the [Wikipedia Article](https://en.wikipedia.org/wiki/Type_erasure): 
> In programming languages, __type erasure__ refers to the load-time process by which explicit type annotations are removed from a program, before it is executed at run-time.

In order to use the generic implementation of the `CommunicationManager` we need to fetch it using the `getCommunicationManager()` method that should always be called inside the `onCommunicationManagerStarting()` lifecycle method that is provided by the `Controller` class. An application programmer now __must__ specify the custom `ObjectFamily` they use, as shown below by `<HelloWorldObjectFamily>`. 

This is an additional step over the coaty-js version, however, __it is the only way to slimmen down the API and remove the need for generic annotations in all methods and classes referencing a`CommunicationManager`__.

```swift
class TaskController: Controller {

    /// This is the communicationManager for this particular controller. Note that,
    /// you _must_ call `self.communicationManager = getCommunicationManager()`
    /// somewhere in `onCommunicationManagerStarting()` in order to store this reference.
    private var communicationManager: CommunicationManager<HelloWorldObjectFamily>?
    
    override func onCommunicationManagerStarting() {
            super.onCommunicationManagerStarting()
            communicationManager = self.getCommunicationManager()

            // Setup subscriptions...
    }
}
```