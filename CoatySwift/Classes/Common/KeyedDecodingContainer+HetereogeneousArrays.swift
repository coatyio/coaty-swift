//
//  KeyedDecodingContainer+HetereogeneousArrays.swift
//  CoatySwift
//
//

import Foundation

// MARK: - Extension for decoding heterogenous list of objects.

extension KeyedDecodingContainer {
    
    /// Decode a heterogeneous list of objects for a given family.
    /// - Parameters:
    ///     - family: The ClassFamily enum for the type family.
    ///     - key: The CodingKey to look up the list in the current container.
    /// - Returns: The resulting list of heterogeneousType elements.
    func decode<T : Decodable, U : ClassFamily>(family: U.Type, forKey key: K) throws -> [T] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        var list = [T]()
        var tmpContainer = container
        while !container.isAtEnd {
            let typeContainer = try container.nestedContainer(keyedBy: Discriminator.self)
            
            do {
                // First, try to decode the element of the array as the custom type from U.
                let family: U = try typeContainer.decode(U.self, forKey: .objectType)
                if let type = family.getType() as? T.Type {
                    list.append(try tmpContainer.decode(type))
                    continue
                }
            } catch {
                // If the previous decode did not succeed, fall back to trying to decode the
                // object as a standard CoatyObject.
                let standardFamily = try typeContainer.decode(CoatyObjectFamily.self,
                                                              forKey: .objectType)
                if let type = standardFamily.getType() as? T.Type {
                    list.append(try tmpContainer.decode(type))
                }
            }
        }
        return list
    }
    
    /// Convenience method for decoding a heterogeneous list of objects for a given family
    /// that returns an optional.
    ///
    /// - Parameters:
    ///   - family: The ClassFamily enum for the type family.
    ///   - key: The CodingKey to look up the list in the current container.
    /// - Returns: An optional list of heterogeneousType elements.
    func decodeIfPresent<T : Decodable, U : ClassFamily>(family: U.Type,
                                                         forKey key: K) throws -> [T]? {
        return try? decode(family: family, forKey: key)
    }
}
