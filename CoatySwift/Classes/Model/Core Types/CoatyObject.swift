//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatyObject.swift
//  CoatySwift
//
//

import Foundation

/// The base type of all objects in the Coaty object model. Application-specific object types
/// extend either CoatyObject directly or any of its derived core types.
open class CoatyObject: Codable {
    
    // MARK: - Class registration.
    
    open class var objectType: String {
        return register(objectType: CoreType.CoatyObject.objectType, with: self)
    }
    
    // MARK: - Required attributes.
    
    /// The framework core type of the object, i.e. the name of the interface that defines
    /// the object's shape.
    public var coreType: CoreType
    
    /// The concrete type name of the object.
    ///
    /// The name should be in a canonical form following
    /// the naming convention for Java packages to avoid name collisions. All framework core
    /// types use the form coaty.<ClassName>, e.g. "coaty.CoatyObject".
    /// - Note: Object type names should be made up of characters in the range 0 to 9, a to z,
    /// A to Z, and dot (.).
    /// - Note: All object types starting with "coaty." are reserved for use by the Coaty framework
    ///   and must not be used by applications  to define custom object types.
    public var objectType: String
    
    /// Unique ID of the object.
    public var objectId: CoatyUUID
    
    /// The name/description of the object.
    public var name: String
    
    // MARK: - Optional attributes.
    
    /// External ID associated with this object (optional).
    public var externalId: String?
    
    /// Unique ID of parent/superordinate object (optional).
    public var parentObjectId: CoatyUUID?
    
    /// Unique ID of Location object that this object has been associated with (optional).
    public var locationId: CoatyUUID?
    
    /// Marks an object that is no longer in use.
    ///
    /// The concrete definition meaning of this
    /// property is defined by the application. The property value is optional and should
    /// default to false.
    public var isDeactivated: Bool?
    
    /// Holds all custom properties of a non-registered object type that is decoded as
    /// part of an incoming communication event.
    ///
    /// For any custom object type that has not been registered, this dictionary holds all
    /// custom fields that are not defined by the core type of this Coaty object.
    ///
    /// - Note: For registered custom object types (and core types), this dictionary is
    ///   always empty.
    /// - Note: This property is never encoded. It is only intended to be accessed
    ///   inside your local app.
    internal (set) public var custom: [String: Any]
    
    // MARK: - Initializers.
    
    /// Default initializer for a `CoatyObject` object.
    public init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String) {
        self.coreType = coreType
        self.objectId = objectId
        self.objectType = objectType
        self.name = name
        self.custom = [String: Any]()
    }
    
    // MARK: - Static and instance registration methods.
    
    /// Register the given Coaty object type with the implementing Swift class type.
    public static func register(objectType: String, with classType: CoatyObject.Type) -> String {
        self.classTypes[objectType] = classType
        return objectType
    }
    
    /// Determines whether this Coaty object has been registered by its object type.
    /// If true is returned, all core type properties and non-core type properties of this object
    /// are accessible. Otherwise, non-core type values are accessible in the `custom`
    /// dictionary property.
    public var isObjectTypeRegistered: Bool {
        return CoatyObject.getClassType(forObjectType: self.objectType) != nil
    }
    
    /// All class types registered for object types by this class and subclasses.
    private static var classTypes = [String: CoatyObject.Type]()
    
    static func getClassType(forObjectType: String) -> CoatyObject.Type? {
        return self.classTypes[forObjectType]
    }
    
    // MARK: - Codable methods.
    
    enum CoatyObjectKeys: String, CodingKey, CaseIterable {
        case objectId
        case coreType
        case objectType
        case name
        case externalId
        case parentObjectId
        case locationId
        case isDeactivated
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CoatyObjectKeys.self)
        
        // Decode required attributes.
        objectId = try container.decode(CoatyUUID.self, forKey: .objectId)
        coreType = try container.decode(CoreType.self, forKey: .coreType)
        objectType = try container.decode(String.self, forKey: .objectType)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode optional attributes.
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        parentObjectId = try container.decodeIfPresent(CoatyUUID.self, forKey: .parentObjectId)
        locationId = try container.decodeIfPresent(CoatyUUID.self, forKey: .locationId)
        isDeactivated = try container.decodeIfPresent(Bool.self, forKey: .isDeactivated)

        // If core type decoding is enabled, decode any attributes not yet decoded
        // by this core type into the custom dictionary attribute.
        custom = [:]
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: CoatyObjectKeys.self)
        try decodeCustomKeys(decoder)
    }
    
    static func addCoreTypeKeys<T>(decoder: Decoder, coreTypeKeys: T.Type)
        where T: CodingKey, T: CaseIterable, T: RawRepresentable, T.RawValue == String {
            guard let allCoreTypeKeys = decoder.currentContext(forKey: "coreTypeKeys") as? NSMutableSet else {
                return
            }
            coreTypeKeys.allCases.forEach({ key in allCoreTypeKeys.add(key.rawValue) })
    }
    
    private func decodeCustomKeys(_ decoder: Decoder) throws {
        guard let coreTypeKeys = decoder.currentContext(forKey: "coreTypeKeys") as? NSMutableSet else {
            return
        }
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        for key in container.allKeys {
            if coreTypeKeys.contains(key.stringValue) {
                continue
            }
            
            let value = try container.decode(AnyCodable.self, forKey: key)
            self.custom[key.stringValue] = value.value
        }
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoatyObjectKeys.self)
        
        // Encode required attributes.
        try container.encode(objectId, forKey: .objectId)
        try container.encode(coreType, forKey: .coreType)
        try container.encode(objectType, forKey: .objectType)
        try container.encode(name, forKey: .name)
        
        // Encode optional attributes.
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(parentObjectId, forKey: .parentObjectId)
        try container.encodeIfPresent(locationId, forKey: .locationId)
        try container.encodeIfPresent(isDeactivated, forKey: .isDeactivated)
    }
}

// MARK: - Extension enable easy access to JSON representation of Coaty object.

extension CoatyObject {
    public var json: String {
        get {
            return PayloadCoder.encode(self)
        }
    }
}
