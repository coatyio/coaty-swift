//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  IoPoint.swift
//  CoatySwift
//
//

import Foundation

 /// Defines meta information of an IO point.
 ///
 /// This base object has no associated framework base object type.
 /// For instantiation use one of the concrete subtypes `IoSource` or `IoActor`.
 open class IoPoint: CoatyObject {
    
    // MARK: - Attributes.

    /// Determines whether IO values published by IO sources or received by IO
    /// actors should be treated as raw data that is not encoded/decoded as JSON
    /// objects.
    ///
    /// In order to associate an IO source with an IO actor their values of this
    /// property must match, i.e. **both** properties must be either true or false
    /// to ensure that IO values transmitted between an IO source and and an IO actor
    /// can be properly encoded and decoded on each side.
    ///
    /// Set this property to true to indicate that the IO source or IO actor
    /// should handle IO values in raw data format, i.e as a byte array of type
    /// `[UInt8]`.
    ///
    /// If set to false (default), the IO values sent by an IO source should be
    /// encodable as JSON and decodable as JSON by an associated IO actor.
    public var useRawIoValues: Bool?
    
    /// The update rate (in milliseconds) for publishing IoValue events:
    /// * desired rate for IO actors
    /// * maximum possible drain rate for IO sources
    ///
    /// The IO router specifies the recommended update rate in Associate event data.
    /// If undefined, there is no limit on the rate of published events.
    public var updateRate: Int?

    /// A topic specification used for routing IO values from *external* sources
    /// to Coaty-defined IO actors or from Coaty-defined IO sources to *external*
    /// sinks (optional).
    ///
    /// Only used for associating routes that are not created by an IO router,
    /// but defined by an external non-Coaty component.
    ///
    /// - Remark: Note that the format of an external route is binding-specifc. In
    /// order to deliver IO values from/to an external source/actor, the format
    /// of the external route must correspond with the configured communication
    /// binding. That means, it must be in a valid format and must not have a
    /// Coaty-event-like shape. As the external route must be publishable and
    /// subscribable, it must not be pattern-based (no wildcard tokens allowed).
    public var externalRoute: String?
    
    // MARK: - Initializers.
    
    /// Default initializer for an`IoPoint` object.
    init(coreType: CoreType,
         objectType: String,
         objectId: CoatyUUID,
         name: String,
         useRawIoValues: Bool? = false,
         updateRate: Int? = nil,
         externalRoute: String? = nil) {
        self.useRawIoValues = useRawIoValues
        self.updateRate = updateRate
        self.externalRoute = externalRoute
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.

    enum IoPointKeys: String, CodingKey, CaseIterable {
        case useRawIoValues
        case updateRate
        case externalRoute
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoPointKeys.self)
        self.useRawIoValues = try container.decodeIfPresent(Bool.self, forKey: .useRawIoValues)
        self.updateRate = try container.decodeIfPresent(Int.self, forKey: .updateRate)
        self.externalRoute = try container.decodeIfPresent(String.self, forKey: .externalRoute)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: IoPointKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoPointKeys.self)
        try container.encodeIfPresent(useRawIoValues, forKey: .useRawIoValues)
        try container.encodeIfPresent(updateRate, forKey: .updateRate)
        try container.encodeIfPresent(externalRoute, forKey: .externalRoute)
    }
}
