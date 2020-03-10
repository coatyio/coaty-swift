---
layout: default
title: CoatySwift Documentation
---

# CoatySwift Design Rationale

This document aims to explain some of the rationale behind our decisions when
building CoatySwift, the problems we faced, and how we decided to solve them.
Several sections include coding examples and provide background explanations on
why things had and have to be done in a certain way to make CoatySwift do
_exactly_ what you want it to do.

## The Pleasure and Pain of Static Languages

We decided to use the
[`Codable`](https://developer.apple.com/documentation/swift/codable) protocol
for all communication event and object encoding and decoding tasks. The
`Codable` protocol is part of the Swift standard library and is recommended to
be used for object conversion from and to JSON.

> Swift is a __statically typed language__, which makes easy interaction with
> JSON objects non-trivial.

By implementing `Codable` we avoid third-party dependencies such as
[`SwiftyJSON`](https://github.com/SwiftyJSON/SwiftyJSON). `SwiftyJSON`, for
example, could only provide a limited form of type safety in our context, and
the user would be left to manually parse objects and create them 'on the go'.

`Codable`, on the other hand, allows a standardized interaction with the object
encoding / decoding API and enables the application programmer to extend the
predefined object types by overwriting the `encode(to:) / init(from:)` methods
and calling their base implementations. Relying on traditional JSON parsing
frameworks would require to reimplement this functionality entirely for each
custom object.

Working with untyped JSON objects in Swift is another way to use JSON data. This
approach casts the data to `[String: Any]` dictionaries and eliminates the power
of compiler based type checks what makes this approach inferior to our
implementation.

> NOTE: `Codable` is relatively new and under active development. For future
> releases we hope for better support of heterogenous data structures to
> simplify the decoding of custom Coaty objects.

## The Importance of Registering Custom Object Types

As previously mentioned, Swift is a statically typed language and thus does not
provide an easy option of creating dynamic types on the go. This limits us
greatly when decoding Coaty objects in CoatySwift, because the application
programmer can introduce completely new object types that need to be sent over
the wire.

To integrate application-time Coaty objects into CoatySwift while considering
the constraints given by `Codable` as well as Swift itself, we require a
__mapping between custom Coaty objects__ and their __corresponding Swift class
implementations__. The mapping is realized by registering the class for the
corresponding object type (an arbitrary String) in a class variable initializer:

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

    // MARK: - Initializers.

    init(myValue: String) {
        self.myValue = myValue
        super.init(coreType: .CoatyObject,
                   objectType: ExampleObject.objectType,
                   objectId: .init(),
                   name: "ExampleObject Name :)")
    }

    // MARK: Codable methods.

    ...
}
```

> Note that the registered object type is also used for the corresponding
> initialization parameter of the initializer. It is also useful when observing
> objects of this object type, like this:

```swift
try! self.communicationManager
        .observeAdvertise(withObjectType: ExampleObject.objectType)
        .subscribe(onNext: { (event) in
```

## Decoding Coaty Objects

Using the information gathered from registering object types, we are able to
provide type safety even with custom objects. We have implemented this decoding
strategy in a helper class named `AnyCoatyObjectDecodable`. It supports decoding
of any Coaty object, either as a core type or as a custom, i.e
application-specific object type as follows:

1. Try to decode by registered object type

    If the Coaty object type specified in the decodable JSON object has been
    registered as a Swift class, an instance of the corresponding class type is
    created with all core type and custom type properties filled in. Any extra
    fields present on the decodable object are ignored.

2. Try to decode by built-in core type

    If the Coaty object type has not been registered, an instance of the core
    type class as specified in the decodable JSON object is created with all
    core type properties filled in. Any other fields present on the decodable
    object are added to the `custom` dictionary property of the created
    instance.

    This approach is especially useful if you want to observe Coaty objects of
    arbitrary object types for which no Swift class definitions exist in your
    app.

3. Throw a decoding error

    If the core type given in the decodable JSON object has no corresponding
    class predefined by CoatySwift, a decoding error will be thrown, as there is
    no type information that can help us infer the actual type of the object.

> __NOTE:__ You can also use the `AnyCoatyObjectDecodable` class to decode a
> custom property value that is of any (variable) Coaty object type or a
> collection thereof. For an example, see the `Snapshot` core type class which
> decodes any CoatyObject in its `object` property.
>
> __NOTE:__ If you need to decode or encode a property value of a custom Coaty
> object type that can be any valid JSON data, and you don't know the JSON
> structure in advance, declare the property type as `AnyCodable`. Using this
> type, you can decode or encode mixed-type values in dictionaries and other
> collections that require `Decodable` or `Encodable` conformance.
