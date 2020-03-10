//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  AnyCoatyObjectDecodable.swift
//  CoatySwift
//
//

import Foundation

/// Discriminator key enum that is used to determine the field that
/// discriminates between core type or object type decoding of CoatyObjects.
enum AnyCoatyObjectDiscriminator: String, CodingKey {
    case objectType = "objectType"
    case coreType = "coreType"
}

/// Supports decoding of any Coaty object, either as a core type or as a custom, i.e application-specific object type.
///
/// If the Coaty object type specified in the decodable JSON object has been registered as a Swift class,
/// an instance of the corresponding class type is created with all core type and custom type properties filled in.
/// Any extra fields present on the decodable object are ignored.
///
/// Otherwise, if the Coaty object type has not been registered, an instance of the core type class as specified
/// in the decodable JSON object is created with all core type properties filled in. Additionally, any other field
/// present on the decodable object is added to the `custom` dictionary property of the created instance.
///
/// The second approach is especially useful if you want to observe custom Coaty objects whose object type
/// is not known at compile time so that no Swift class definition exists for them.
///
/// - Note: the created Coaty object instance is accessible by the `object` property.
public class AnyCoatyObjectDecodable: Decodable {
    
    /// The decoded object. Can be an instance of any subclass of CoatyObject.
    var object: CoatyObject
    
    /// Supports decoding of any Coaty object, either as a core type or as a custom, i.e application-specific object type.
    ///
    /// If the Coaty object type specified in the decodable JSON object has been registered as a Swift class,
    /// an instance of the corresponding class type is created with all core type and custom type properties filled in.
    /// Any extra fields present on the decodable object are ignored.
    ///
    /// Otherwise, if the Coaty object type has not been registered, an instance of the core type class as specified
    /// in the decodable JSON object is created with all core type properties filled in. Additionally, any other field
    /// present on the decodable object is added to the `custom` dictionary property of the created instance.
    ///
    /// The second approach is especially useful if you want to observe custom Coaty objects whose object type
    /// is not known at compile time so that no Swift class definition exists for them.
    ///
    /// - Note: the created Coaty object instance is accessible by the `object` property.
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCoatyObjectDiscriminator.self)
        
        // First, try to decode object by the provided object type. This creates an
        // instance of the corresponding object type class with all its core type and
        // custom object type properties decoded.
        // Any other fields of the decodable object are ignored.
        
        guard let objectType = try? container.decode(String.self, forKey: .objectType) else {
            throw CoatySwiftError.DecodingFailure("AnyCoatyObjectDecodable: objectType field is not decodable.")
        }
        
        if let type = CoatyObject.getClassType(forObjectType: objectType) {
            object = try decoder.withContext(
                nil,
                forKey: "coreTypeKeys",
                action: { try type.init(from: decoder) })
            
            // Successfully decoded as custom object type instance.
            return
        }
        
        // Then, try to decode object by the provided core type. This creates an instance of the
        // corresponding core type class with all its core type properties decoded.
        // Any other fields of the decodable object are represented in the
        // `custom` dictionary property of the created instance.
        
        guard let coreType = try? container.decode(CoreType.self, forKey: .coreType) else {
            throw CoatySwiftError.DecodingFailure("AnyCoatyObjectDecodable: coreType field is not decodable.")
        }

        let type = CoreType.getClassType(forCoreType: coreType)
        object = try decoder.withContext(
            NSMutableSet(),
            forKey: "coreTypeKeys",
            action: { try type.init(from: decoder) })
    }
}

