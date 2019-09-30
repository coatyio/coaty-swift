// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Component.swift
//  CoatySwift
//

import Foundation

/// Represents a Coaty container component, i.e. a controller or the communication manager.
public class Component: CoatyObject {
    
    public init(name: String = "ComponentObject",
                objectType: String = "\(COATY_PREFIX)\(CoreType.Component)",
                objectId: CoatyUUID = .init()) {
        super.init(coreType: .Component, objectType: objectType, objectId: objectId, name: name)
    }
    
    /// - NOTE: Should NOT be used by the application programmer.
    internal required override init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String) {
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
