//
//  KeyedDecodingContainer+HetereogeneousArrays.swift
//  CoatySwift
//
//

import Foundation

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
                let family: U = try typeContainer.decode(U.self, forKey: .objectType)
                if let type = family.getType() as? T.Type {
                    list.append(try tmpContainer.decode(type))
                    print("add as custom type.")
                    continue
                }
            } catch {
                // Try to parse as standard type.
                let standardFamily = try typeContainer.decode(CoatyObjectFamily.self, forKey: .objectType)
                if let type = standardFamily.getType() as? T.Type {
                    list.append(try tmpContainer.decode(type))
                    print("add as standard type.")
                }
            }
        }
        return list
    }
    
    func decodeIfPresent<T : Decodable, U : ClassFamily>(family: U.Type, forKey key: K) throws -> [T]? {
        return try? decode(family: family, forKey: key)
    }

}
