//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  Polygon.swift
//  CoatySwift
//

import Foundation

/// NOTE: This file implements a small portion of the RFC7946 that is used in the coaty framework.
/// This implementation is by no means complete. Many trivial choices were made during development.
/// In case more compliance with the standard is needed, further development of this class is necessary.

/// Polygon geometry object as defined in:
/// https://tools.ietf.org/html/rfc7946#section-3.1.6
open class Polygon: Codable, GeoJsonObject {
    
    /// Specifies the type of GeoJSON object.
    public var type: GeoJsonType
    
    /// Bounding box of the coordinate range of the object's Geometries, Features, or Feature Collections.
    /// The value of the bbox member is an array of length 2*n where n is the number of dimensions
    /// represented in the contained geometries, with all axes of the most southwesterly point
    /// followed by all axes of the more northeasterly point.
    /// The axes order of a bbox follows the axes order of geometries.
    /// https://tools.ietf.org/html/rfc7946#section-5
    public var bbox: BBox?
    
    /// For type "Polygon", the "coordinates" member MUST be an array of linear ring coordinate arrays.
    public var coordinates: [[Position]]
    
    public init(coordinates: [[Position]]) {
        self.type = .Polygon
        self.coordinates = []
    }
}

/**
 * The base GeoJSON object.
 * https://tools.ietf.org/html/rfc7946#section-3
 * The GeoJSON specification also allows foreign members
 * (https://tools.ietf.org/html/rfc7946#section-6.1)
 * Developers should use "&" type in TypeScript or extend the interface
 * to add these foreign members.
 */
public protocol GeoJsonObject {
    var type: GeoJsonType { get set }
    var bbox: BBox? { get set}
}

/// The value values for the "type" property of GeoJSON Objects.
/// NOTE: Only include types that are relevant for CoatySwift.
public enum GeoJsonType: String, Codable {
    case Polygon
}

public class BBox: Codable {
    // NOTE: if ever needed more explicitly, check for correct lengths of the array in the constructor
    public var array: [Double]
}

/// A Position is an array of coordinates.
/// https://tools.ietf.org/html/rfc7946#section-3.1.1
/// Array should contain between two and three elements.
/// The previous GeoJSON specification allowed more elements (e.g., which could be used to represent M values),
/// but the current specification only allows X, Y, and (optionally) Z to be defined.
public typealias Position = [Double]
