//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  IoActor.swift
//  CoatySwift
//
//

import Foundation

/// Defines meta information of an IO actor.
open class IoActor: IoPoint {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.IoActor.objectType, with: self)
    }
    
    // MARK: - Attributes.

    /// The semantic, application-specific data type of values to be consumed
    /// by the IO actor, such as Temperature, Notification, Task, etc.
    /// In order to be associated with an IO source their value types must match.
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
    
    // MARK: - Initializers.
    
    /// Default initializer for an `IoActor` object.
    public init(valueType: String,
         useRawIoValues: Bool? = false,
         updateRate: Int? = nil,
         externalRoute: String? = nil,
         name: String = "IoActorObject",
         objectType: String = IoActor.objectType,
         objectId: CoatyUUID = .init()) {
        self.valueType = valueType
        super.init(coreType: .IoActor,
                   objectType: objectType,
                   objectId: objectId,
                   name: name,
                   useRawIoValues: useRawIoValues,
                   updateRate: updateRate,
                   externalRoute: externalRoute)
    }
    
    // MARK: Codable methods.
    
    enum IoActorKeys: String, CodingKey, CaseIterable {
        case valueType
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoActorKeys.self)
        self.valueType = try container.decode(String.self, forKey: .valueType)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: IoActorKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoActorKeys.self)
        try container.encode(valueType, forKey: .valueType)
    }
}
