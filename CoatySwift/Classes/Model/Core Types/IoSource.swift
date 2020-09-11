//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  IoSource.swift
//  CoatySwift
//
//

import Foundation

/// Defines strategies for coping with IO sources that produce IO values more
/// rapidly than specified in their currently recommended update rate.
public enum IoSourceBackpressureStrategy: Int, Codable {

    /// Use a default strategy for publishing values: If no recommended
    /// update rate is assigned to the IO source, use the `None` strategy;
    /// otherwise use the `Sample` strategy.
    case Default

    /// Publish all values immediately. Note that this strategy ignores
    /// the recommended update rate assigned to the IO source.
    case None

    /// Publish the most recent values within periodic time intervals
    /// according to the recommended update rate assigned to the IO source.
    /// If no update rate is given, fall back to the `None` strategy.
    case Sample

    /// Only publish a value if a particular timespan has
    /// passed without it publishing another value. The timespan is
    /// determined by the recommended update rate assigned to the IO source.
    /// If no update rate is given, fall back to the `None` strategy.
    case Throttle
}

/// Defines meta information of an IO source.
open class IoSource: IoPoint {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.IoSource.objectType, with: self)
    }
    
    // MARK: - Attributes.

    /// The semantic, application-specific data type of values to be represented
    /// by the IO source, such as Temperature, Notification, Task, etc.
    /// In order to be associated with an IO actor their value types must match.
    ///
    /// The property value must be a non-empty string. You should choose
    /// canonical names for value types to avoid naming collisions. For example,
    /// by following the naming convention for Java packages, such as
    /// `com.mydomain.myapp.Temperature`.
    ///
    /// Note that this value type is different from the underlying data format
    /// used by the IO source to publish IO data values. For example, an IO source
    /// for a temperature sensor could emit values as numbers or as a Value1D
    /// object with specific properties.
    public var valueType: String

    /// The backpressure strategy for publishing IO values (optional).
    ///
    /// If not specified, the value defaults to
    /// `IoSourceBackpressureStrategy.Default`.
    ///
    public var updateStrategy: IoSourceBackpressureStrategy?
    
    // MARK: - Initializers.
    
    /// Default initializer for an `IoSource` object.
    public init(valueType: String,
         updateStrategy: IoSourceBackpressureStrategy? = nil,
         useRawIoValues: Bool? = false,
         updateRate: Int? = nil,
         externalRoute: String? = nil,
         name: String = "IoSourceObject",
         objectType: String = IoSource.objectType,
         objectId: CoatyUUID = .init()) {
        self.valueType = valueType
        self.updateStrategy = updateStrategy
        super.init(coreType: .IoSource,
                   objectType: objectType,
                   objectId: objectId,
                   name: name,
                   useRawIoValues: useRawIoValues,
                   updateRate: updateRate,
                   externalRoute: externalRoute)
    }
    
    // MARK: - Codable methods.

    enum IoSourceKeys: String, CodingKey, CaseIterable {
        case valueType
        case updateStrategy
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoSourceKeys.self)
        self.valueType = try container.decode(String.self, forKey: .valueType)
        self.updateStrategy = try container.decodeIfPresent(IoSourceBackpressureStrategy.self, forKey: .updateStrategy)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: IoSourceKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoSourceKeys.self)
        try container.encode(valueType, forKey: .valueType)
        try container.encodeIfPresent(updateStrategy, forKey: .updateStrategy)
    }
}
