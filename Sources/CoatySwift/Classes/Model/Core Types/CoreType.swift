//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoreType.swift
//  CoatySwift
//
//

import Foundation

/// All Coaty core types as defined in https://github.com/coatyio/coaty-js/blob/master/src/model/types.ts
public enum CoreType: String, Codable {
    
    // MARK: - Value definitions.
    
    case CoatyObject = "CoatyObject"
    case User = "User"
    case Annotation = "Annotation"
    case Task = "Task"
    case IoSource = "IoSource"
    case IoActor = "IoActor"
    case IoNode = "IoNode"
    case IoContext = "IoContext"
    case Identity = "Identity"
    case Log = "Log"
    case Location = "Location"
    case Snapshot = "Snapshot"
    
    enum ObjectType: String {
        case CoatyObject = "coaty.CoatyObject"
        case User = "coaty.User"
        case Annotation = "coaty.Annotation"
        case Task = "coaty.Task"
        case IoSource = "coaty.IoSource"
        case IoActor = "coaty.IoActor"
        case IoNode = "coaty.IoNode"
        case IoContext = "coaty.IoContext"
        case Identity = "coaty.Identity"
        case Log = "coaty.Log"
        case Location = "coaty.Location"
        case Snapshot = "coaty.Snapshot"
    }
    
    static func getClassType(forCoreType: CoreType) -> CoatyObject.Type {
        switch forCoreType {
        case .CoatyObject:
            return CoatySwift.CoatyObject.self
        case .User:
            return CoatySwift.User.self
        case .Annotation:
            return CoatySwift.Annotation.self
        case .Task:
            return CoatySwift.Task.self
        case .IoSource:
            return CoatySwift.IoSource.self
        case .IoActor:
            return CoatySwift.IoActor.self
        case .IoNode:
            return CoatySwift.IoNode.self
        case .IoContext:
            return CoatySwift.IoContext.self
        case .Identity:
            return CoatySwift.Identity.self
        case .Log:
            return CoatySwift.Log.self
        case .Location:
            return CoatySwift.Location.self
        case .Snapshot:
            return CoatySwift.Snapshot.self
        }
    }

    /// Gets the core type for the given object type, if the object type corresponds
    /// to a Coaty core type.
    static func getCoreType(forObjectType: String) -> CoreType? {
        switch forObjectType {
        case ObjectType.CoatyObject.rawValue:
            return self.CoatyObject
        case ObjectType.User.rawValue:
            return self.User
        case ObjectType.Annotation.rawValue:
            return self.Annotation
        case ObjectType.Task.rawValue:
            return self.Task
        case ObjectType.IoSource.rawValue:
            return self.IoSource
        case ObjectType.IoActor.rawValue:
            return self.IoActor
        case ObjectType.IoNode.rawValue:
            return self.IoNode
        case ObjectType.IoContext.rawValue:
            return self.IoContext
        case ObjectType.Identity.rawValue:
            return self.Identity
        case ObjectType.Log.rawValue:
            return self.Log
        case ObjectType.Location.rawValue:
            return self.Location
        case ObjectType.Snapshot.rawValue:
            return self.Snapshot
        default:
            return nil
        }
    }
    
    /// Registers all Coaty core object types.
    static func registerCoreObjectTypes() {
        _ = CoatySwift.CoatyObject.objectType
        _ = CoatySwift.User.objectType
        _ = CoatySwift.Annotation.objectType
        _ = CoatySwift.Task.objectType
        _ = CoatySwift.IoSource.objectType
        _ = CoatySwift.IoActor.objectType
        _ = CoatySwift.IoNode.objectType
        _ = CoatySwift.IoContext.objectType
        _ = CoatySwift.Identity.objectType
        _ = CoatySwift.Log.objectType
        _ = CoatySwift.Location.objectType
        _ = CoatySwift.Snapshot.objectType
    }
    
    static func registerSensorThingsTypes() {
        _ = CoatySwift.Sensor.objectType
        _ = CoatySwift.Thing.objectType
        _ = CoatySwift.FeatureOfInterest.objectType
        _ = CoatySwift.Observation.objectType
    }
    
    /// Gets the object type of this core type.
    public var objectType: String {
        switch self {
        case .CoatyObject:
            return ObjectType.CoatyObject.rawValue
        case .User:
            return ObjectType.User.rawValue
        case .Annotation:
            return ObjectType.Annotation.rawValue
        case .Task:
            return ObjectType.Task.rawValue
        case .IoSource:
            return ObjectType.IoSource.rawValue
        case .IoActor:
            return ObjectType.IoActor.rawValue
        case .IoNode:
            return ObjectType.IoNode.rawValue
        case .IoContext:
            return ObjectType.IoContext.rawValue
        case .Identity:
            return ObjectType.Identity.rawValue
        case .Log:
            return ObjectType.Log.rawValue
        case .Location:
            return ObjectType.Location.rawValue
        case .Snapshot:
            return ObjectType.Snapshot.rawValue
}
    }
    
    // MARK: - Codable methods.
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        
        // Try to parse the raw value to the actual enum.
        guard let coreType = CoreType(rawValue: rawString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Attempt to decode invalid CoreType."))
        }
        
        self = coreType
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
