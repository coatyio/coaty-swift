//
//  ClassFamily.swift
//  CoatySwift
//
//

import Foundation

/// A ClassFamily defines a protocol for custom object types.
/// See `CoatyObjectFamily` for a concrete implementation.
public protocol ClassFamily: Decodable {
    
    /// Returns the class type of the object coresponding to the value.
    func getType() -> AnyObject.Type
}

/// Discriminator key enum that is used to determine the field that discriminates between
/// the different object types. For CoatyObjects this is _always_ "objectType".
enum Discriminator: String, CodingKey {
    case objectType = "objectType"
}

