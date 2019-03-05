//
//  Component.swift
//  CoatySwift
//

import Foundation

/// Represents a Coaty container component, i.e. a controller or the communication manager.
public class Component: CoatyObject {
    
    init(name: String, objectType: String = "\(COATY_PREFIX)\(CoreType.Component)", objectId: UUID = .init()) {
        super.init(coreType: .Component, objectType: objectType, objectId: objectId, name: name)
    }
    
    /// - NOTE: Should NOT be used by the application programmer.
    public required init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        super.init(coreType: coreType, objectType: objectType, objectId: objectId, name: name)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
