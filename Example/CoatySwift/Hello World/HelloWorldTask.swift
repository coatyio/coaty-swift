//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  HelloWorldTask.swift
//  CoatySwift_Example
//

import Foundation
import CoatySwift


/// Represents a Hello World task or task request.
class HelloWorldTask: Task {
    
    // MARK: - Attributes
    
    /// Level of urgency of the HelloWorldTask.
    public var urgency: HelloWorldTaskUrgency
    
    
    public init(objectType: String,
                objectId: CoatyUUID,
                name: String,
                creatorId: CoatyUUID,
                creationTimestamp: Double,
                status: TaskStatus,
                urgency: HelloWorldTaskUrgency,
                lastModificationTimestamp: Double? = nil,
                dueTimestamp: Double? = nil,
                doneTimestamp: Double? = nil,
                requirements: [String]? = nil,
                description: [String]? = nil,
                workflowId: CoatyUUID? = nil) {
        self.urgency = urgency
        super.init(objectType: objectType, objectId: objectId, name: name,
                   creatorId: creatorId, creationTimestamp: creationTimestamp,
                   status: status, lastModificationTimestamp: lastModificationTimestamp,
                   dueTimestamp: dueTimestamp, doneTimestamp: doneTimestamp,
                   requirements: requirements, description:description, workflowId:workflowId)
    }
    
    required init(coreType: CoreType, objectType: String, objectId: CoatyUUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    // MARK: Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case urgency
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.urgency = try container.decode(HelloWorldTaskUrgency.self, forKey: .urgency)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(urgency, forKey: .urgency)
    }
}

/// Defines urgency levels for HelloWorld tasks.
enum HelloWorldTaskUrgency: Int, Codable {
    case low = 0
    case medium
    case high
    case critical
}
