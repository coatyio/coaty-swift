//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoContext.swift
//  CoatySwift
//
//

import Foundation

/// Represents the context of IO routing.
///
/// An IO context is associated with an IO router that can use its context
/// information to manage routes.
///
/// - Remark: If needed, create a custom subtype with custom properties that
/// represent application-specific context information.
open class IoContext: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.IoContext.objectType, with: self)
    }
    
    // MARK: - Attributes.
    
    /// - Note: This comment refers to the property `name` of superclass CoatyObject,
    /// since Swift does not support overridden comments
    ///
    /// A name that uniquely identifies this IO context *within a Coaty
    /// application scope*.
    ///
    /// Use an expressive name that is shared by all agents defining IO nodes for
    /// this context.
    ///
    /// - Remark: The context name must be a non-empty string that does not
    /// contain the following characters: `NULL (U+0000)`, `# (U+0023)`, `+
    /// (U+002B)`, `/ (U+002F)`.
    
    // MARK: - Initializers.
    public override init(coreType: CoreType,
                objectType: String,
                objectId: CoatyUUID,
                name: String) {
        super.init(coreType: coreType,
                   objectType: objectType,
                   objectId: objectId,
                   name: name)
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}
