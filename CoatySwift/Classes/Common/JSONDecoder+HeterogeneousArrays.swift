//
//  JSONDecoder+HeterogeneousArrays.swift
//  CoatySwift
//
//

import Foundation

extension JSONDecoder {
    /// Decode a heterogeneous list of objects.
    /// - Parameters:
    ///     - family: The ClassFamily enum type to decode with.
    ///     - data: The data to decode.
    /// - Returns: The list of decoded objects.
    func decode<T: ClassFamily, U: Decodable>(family: T.Type, from data: Data) throws -> [U] {
        return try self.decode([ClassWrapper<T, U>].self, from: data).compactMap { $0.object }
    }
    
    private class ClassWrapper<T: ClassFamily, U: Decodable>: Decodable {
        
        /// The decoded object. Can be any subclass of U.
        let object: U?
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Discriminator.self)
            // Decode the family with the discriminator.
            if let customFamily = try? container.decode(T.self, forKey: .objectType) {
                // Decode the object by initialising the corresponding type.
                if let type = customFamily.getType() as? U.Type {
                    object = try type.init(from: decoder)
                } else {
                    object = nil
                }
            } else if let defaultFamily = try? container.decode(CoatyObjectFamily.self, forKey: .objectType) {
                // Decode the object by initialising the corresponding type.
                if let type = defaultFamily.getType() as? U.Type {
                    object = try type.init(from: decoder)
                } else {
                    object = nil
                }
            } else {
                // TODO: Error handling.
                print("error!")
                throw NSError()
            }
            
        }
    }
}
