//
//  ClassFamily.swift
//  CoatySwift
//
//

import Foundation

/// To support a new class family, create an enum that conforms to this protocol and contains the different types.
public protocol ClassFamily: Decodable {    
    /// Returns the class type of the object coresponding to the value.
    func getType() -> AnyObject.Type
}

/// Discriminator key enum used to retrieve discriminator fields in JSON payloads.
enum Discriminator: String, CodingKey {
    case objectType = "objectType"
}

