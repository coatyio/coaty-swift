//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  SensorIo.swift
//  CoatySwift
//

import Foundation

/// The base class for sensor hardware-level IO control. Some IO
/// classes are already defined:
/// - MockSensorIo: Mocks the functionality with a cached value.
/// - Note: no sensorIo classes are defined except for the mocked version.
///
/// Applications can also define their own SensorIo classes.
open class SensorIo: ISensorIo {
    public required init(parameters: Any?) { }
    
    public var parameters: Any?
    
    public func read(callback: ((Any) -> ())) {
        preconditionFailure("This method must be overridden. (abstract method)")
    }
    
    public func write(value: Any) {
        preconditionFailure("This method must be overridden. (abstract method)")
    }
}

/// Mocks the IO communication of an actual sensor hardware. Stores
/// a cached value for the pin and simply updates it with the 'write'
/// calls. The value is 0 at the beginning.
open class MockSensorIo: SensorIo {
    private var _value: Any = 0
    
    /// Returns the internally cached value.
    public override func read(callback: ((Any) -> ())) {
        callback(_value)
    }
    
    /// Writes on the internally cached value.
    public override func write(value: Any) {
        self._value = value
    }
}

/// Base interface for a sensor hardware-level IO control.
/// Provides the basic read and write functionality according to
/// the given parameters.
public protocol ISensorIo {
    init(parameters: Any?)
    
    var parameters: Any? { get set }
    
    func read(callback: ((Any) -> ()))
    
    func write(value: Any)
}

/// Defines a static type for sensor IO interfaces.
/// It is used to create a new instance of this sensor using dependency injection in the sensor controller.
public typealias ISensorStatic<T: ISensorIo> = T.Type

