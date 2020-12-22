---
layout: default title: Coaty JS Documentation
---

# Sensor Things in Coaty Applications

> __NOTE__:
>
> We would like to note that more information about the Sensor Things
> integration in Coaty framework can be found in [Coaty JS Sensor Things
> guide](https://coatyio.github.io/coaty-js/man/sensor-things-guide/)
>
> This guide presents only the significant differences between Swift and JS
> version of Sensor Things implementation. It's a shorter and more concise
> version thereof and should serve as a complementary reading, since it does not
> contain all details.

## Table of contents

* [Sensor Things Types](#sensor-things-types)
  * [Thing](#thing)
  * [Location](#location)
  * [Sensor](#sensor)
  * [Observation](#observation)
  * [Feature of Interest](#feature-of-interest)
* [Sensor Things Additional Objects and
  Types](#sensor-things-additional-objects-and-types)
  * [Unit of Measurement](#unit-of-measurement)
  * [Observed Property](#observed-property)
  * [Encoding Type](#encoding-type)
  * [Observation Type](#observation-type)
* [Controllers](#controllers)
  * [Sensor Source Controller](#sensor-source-controller)
  * [Thing Observer Controller](#thing-observer-controller)
  * [Sensor Observer Controller](#sensor-observer-controller)
  * [Thing Sensor Observation Observer
    Controller](#thing-sensor-observation-observer-controller)
  * [Discovering Sensor Things](#discovering-sensor-things)
  * [Detecting online and offline state of Sensor Things
    agents](#detecting-online-and-offline-state-of-sensor-things-agents)

## Sensor Things Types

See [Coaty JS Sensor Things Types
Section](https://coatyio.github.io/coaty-js/man/sensor-things-guide/#sensor-things-types)
for background on Sensor Things API (diagram and description).

Following sections only presents a guide on how to initialize specific objects
in Coaty Swift. To get some background on the meaning and significance of
specific object please refer to CoatyJS Sensor Things Guide.

### Thing

A Thing defines following properties:

```swift
let thing = Thing(
    description: String,
    properties: [String: String]? = nil,
    name: String,
    objectId: CoatyUUID = .init(),
    externalId: String? = nil,
    parentObjectId: CoatyUUID? = nil,
    locationId: CoatyUUID? = nil,
    objectType: String = Thing.objectType
)
```

### Location

A Location defines the following properties:

```swift
let location = Location(
    geoLocation: GeoLocation,
    name: String = "LocationObject",
    objectType: String = Location.objectType,
    objectId: CoatyUUID = .init()
)
```

### Sensor

A Sensor defines the following properties.

```swift
let sensor = Sensor(
    description: String,
    encodingType: String,
    metadata: AnyCodable,
    unitOfMeasurement: UnitOfMeasurement,
    observationType: ObservationType,
    observedArea: Polygon? = nil,
    phenomenonTime: CoatyTimeInterval? = nil,
    resultTime: CoatyTimeInterval? = nil,
    observedProperty: ObservedProperty,
    name: String,
    objectId: CoatyUUID = .init(),
    externalId: String? = nil,
    parentObjectId: CoatyUUID? = nil,
    objectType: String = Sensor.objectType
)
```

### Observation

An Observation defines the following properties.

```swift
let observation = Observation(
    phenomenonTime: Double,
    result: AnyCodable,
    resultTime: Double,
    resultQuality: [String]? = nil,
    validTime: CoatyTimeInterval? = nil,
    parameters: [String: String]? = nil,
    featureOfInterest: CoatyUUID? = nil,
    name: String,
    objectId: CoatyUUID = .init(),
    externalId: String? = nil,
    parentObjectId: CoatyUUID? = nil,
    objectType: String = Observation.objectType
)
```

### Feature of Interest

```swift
let featureOfInterest = FeatureOfInterest(
    description: String,
    encodingType: String,
    metadata: AnyCodable,
    name: String,
    objectId: CoatyUUID = .init(),
    externalId: String? = nil,
    parentObjectId: CoatyUUID? = nil,
    objectType: String = FeatureOfInterest.objectType
)
```

## Sensor Things Additional Objects and Types

Here is a list of objects and types used in SensorThings API that are not Coaty
objects.

### Unit of Measurement

Represented as a struct with the following public intiializer:

```swift
let unitOfMeasurement = (
    name: String,
    symbol: String,
    definition: String
)
```

### Observed Property

Represented as a struct with the following public intiializer:

```swift
let observedProperty = (
    name: String,
    definition: String,
    description: String
)
```

### Encoding Type

Please open the Sensor.swift file in Coaty Swift framework to learn more.

This element has a String value.

```swift
open class SensorEncodingTypes {
    public static let UNDEFINED = ""
    public static let PDF = "application/pdf"
    public static let SENSOR_ML = "http://www.opengis.net/doc/IS/SensorML/2.0"
}

open class EncodingTypes: SensorEncodingTypes {
    public static let GEO_JSON = "application/vnd.geo+json"
}
```

### Observation Type

Represented as an enum with raw String values.

Please refer to Sensor.swift file in Coaty Swift to learn more

```swift
public class ObservationTypes {
    /// Expects results in format of URLs.
    public static let CATEGORY = ObservationType.category_observation
    /// Expects results in format of integers.
    public static let COUNT = ObservationType.count_observation
    /// Expects results in format of doubles.
    public static let MEASUREMENT = ObservationType.measurement
    /// Expects results of any type of JSON format.
    public static let ANY = ObservationType.observation
    /// Expects results in format of booleans.
    public static let TRUTH = ObservationType.truth_observation
}

public enum ObservationType: String, Codable {
    case category_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Category_Observation"
    case count_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_CountObservation"
    case measurement = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement"
    case observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Observation"
    case truth_observation = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_TruthObservation"
}
```

## Controllers

SensorThings provide some controllers with some convenience methods for use.
These controllers are split in two groups: source and observer controllers. The
source controllers are designed to be used by sensor data producers to provide
the SensorThings objects whereas the observer controllers should be used by
sensor data consumers.

Following sections only present differences between CoatySwift and CoatyJS
versions, since the interfaces in both versions are the same.

### Sensor Source Controller

Most important difference to coaty-js version is the fact that the only defined
SensorIo is MockSensorIo. The reason for that is the fact that iOS/macOS etc.
are probably not going to be used to access hardware sensors. If however such
need appears, please take a look at the comments of SensorIo.swift class to
understand how to implement it.

Sensors can be registerd both manually and by providing the "sensors" property
in extra. For extra please define an array of SensorDefinition objects.

### Thing Observer Controller

Please refer to code documentation and coaty-js guide to learn more.

### Sensor Observer Controller

Please refer to code documentation and coaty-js guide to learn more.

### Thing Sensor Observation Observer Controller

Please refer to code documentation and coaty-js guide to learn more.

### Discovering Sensor Things

Please refer to coaty-js guide to learn more about this topic.

### Detecting online and offline state of Sensor Things agents

Please note that `ObjectLifecycleController` is also available in CoatySwift:
(ObjectLifecycleController
file)[https://github.com/coatyio/coaty-swift/blob/master/CoatySwift/Classes/Controller/ObjectLifecycleController.swift].

---
Copyright (c) 2020 Siemens AG. This work is licensed under a [Creative Commons
Attribution-ShareAlike 4.0 International
License](http://creativecommons.org/licenses/by-sa/4.0/).
