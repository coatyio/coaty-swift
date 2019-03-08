//
//  JSONDecoder+HeterogeneousArrays.swift
//  CoatySwift
//
//

import Foundation

extension JSONDecoder {
    
    /// Decode a heterogeneous list of objects.
    ///
    /// - Parameters:
    ///     - family: The ClassFamily enum type to decode with.
    ///     - data: The data to decode.
    /// - Returns: The list of decoded objects.
    func decode<T: ClassFamily, U: Decodable>(family: T.Type, from data: Data) throws -> [U] {
        return try self.decode([ClassWrapper<T, U>].self, from: data).compactMap { $0.object }
    }
    
    /// Decode a single object with a type from a ClassFamily.
    ///
    /// - Parameters:
    ///     - family: The ClassFamily enum type to decode with.
    ///     - data: The data to decode.
    /// - Returns: The list of decoded objects.
    func decode<T: ClassFamily, U: Decodable>(family: T.Type, from data: Data) throws -> U {
        guard let object = try self.decode(ClassWrapper<T, U>.self, from: data).object else {
            // TODO: Handle error.
            throw NSError()
        }
        
        return object
    }
    
    /// ClassWrapper is a private helper class that allows the decoding of an object based
    /// on a ClassFamily.
    private class ClassWrapper<T: ClassFamily, U: Decodable>: Decodable {
        
        /// The decoded object. Can be any subclass of U.
        let object: U?
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Discriminator.self)
            
            // Try to decode the object with the provided custom type.
            if let customFamily = try? container.decode(T.self, forKey: .objectType) {
                // Decode the object by initialising the corresponding type.
                if let type = customFamily.getType() as? U.Type {
                    object = try type.init(from: decoder)
                } else {
                    object = nil
                }
                
                // Succesfully decoded as custom type.
                return
            }
            
            // Try to decode the object with the builtin standard Coaty types.
            if let defaultFamily = try? container.decode(CoatyObjectFamily.self, forKey: .objectType) {
                // Decode the object by initialising the corresponding type.
                if let type = defaultFamily.getType() as? U.Type {
                    object = try type.init(from: decoder)
                } else {
                    object = nil
                }
                
                // Successfully decoded as default type.
                return
            }
            
            // Could neither decode as custom nor as default type.
            // TODO: Error handling.
            print("error!")
            throw NSError()
        }
    }
}
