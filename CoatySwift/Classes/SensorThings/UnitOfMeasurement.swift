//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  UnitOfMeasurement.swift
//  CoatySwift
//

import Foundation

/// An object containing three key-value pairs:
/// - The name property presents the full name of the unitOfMeasurement.
/// - The symbol property shows the textual form of the unit symbol.
/// - The definition contains the URI defining the unitOfMeasurement.
///
/// The values of these properties SHOULD follow the Unified Code for Unit of Measure (UCUM).
public struct UnitOfMeasurement: Codable {
    
    /// Full name of the UnitofMeasurement such as Degree Celsius.
    public var name: String
    
    /// Symbol of the unit such as degC.
    public var symbol: String
    
    /// Link to unit definition such as:
    /// http://www.qudt.org/qudt/owl/1.0.0/unit/Instances.html#DegreeCelsius
    public var definition: String
    
    public init(name: String,
                symbol: String,
                definition: String) {
        self.name = name
        self.symbol = symbol
        self.definition = definition
    }
}
