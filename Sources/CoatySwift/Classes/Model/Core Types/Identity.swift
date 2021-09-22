//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Identity.swift
//  CoatySwift
//

import Foundation

/// Represents the unique identity of a Coaty container.
open class Identity: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.Identity.objectType, with: self)
    }
    
    /// Default initializer for an `Identity` object.
    public init(name: String = "IdentityObject",
                objectType: String = Identity.objectType,
                objectId: CoatyUUID = .init()) {
        super.init(coreType: .Identity, objectType: objectType, objectId: objectId, name: name)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
