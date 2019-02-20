//
//  CoatyObject.swift
//  CoatySwift
//
//

import Foundation

/// A protocol that specifies all required fields for a CoatyObject as defined in
/// https://coatyio.github.io/coaty-js/man/communication-protocol/
protocol CoatyObject: Codable {
    // MARK: - Required attributes.
    var coreType: CoreType { get set }
    var objectType: String { get set }
    var objectId: UUID { get set }
    var name: String { get set }
    
    // MARK: - Optional attributes.
    var externalId: String? { get set }
    var parentObjectId: UUID? { get set }
    var assigneeUserId: UUID? { get set }
    var locationId: UUID? { get set }
    var isDeactivated: Bool? { get set }
    
    // MARK: - Encoding properties.
    var json: String { get }
    
}

// MARK: - Extension enable easy access to JSON representation of Coaty object.
extension CoatyObject {
    var json: String { get {
        return PayloadCoder.encode(self)
        }
    }
}
