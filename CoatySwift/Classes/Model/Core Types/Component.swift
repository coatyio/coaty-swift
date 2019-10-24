//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Component.swift
//  CoatySwift
//

import Foundation

/// Represents a Coaty container component, i.e. a controller or the communication manager.
open class Component: CoatyObject {
    
    public init(name: String = "ComponentObject",
                objectType: String = "\(COATY_OBJECT_TYPE_NAMESPACE_PREFIX)\(CoreType.Component)",
                objectId: CoatyUUID = .init()) {
        super.init(coreType: .Component, objectType: objectType, objectId: objectId, name: name)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
