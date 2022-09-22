//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ObservedProperty.swift
//  CoatySwift
//

import Foundation

/// An ObservedProperty specifies the phenomenon of an Observation.
public struct ObservedProperty: Codable {
    
    /// A property provides a label for ObservedProperty, commonly a descriptive name.
    public var name: String
    
    /// The URI of the ObservedProperty. Dereferencing this URI SHOULD result in a
    /// representation of the definition of the ObservedProperty.
    public var definition: String
    
    /// A description about the ObservedProperty.
    public var description: String
    
    public init(name: String,
                definition: String,
                description: String) {
        self.name = name
        self.definition = definition
        self.description = description
    }
}
