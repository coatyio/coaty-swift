//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Task.swift
//  CoatySwift
//

import Foundation

/// Represents a task or task request.
open class Task: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.Task.objectType, with: self)
    }
    
    // MARK: - Attributes.
    
    /// Object ID of user who created the task
    public var creatorId: CoatyUUID
    
    /// Coaty compatible timestamp when task was issued/created.
    /// (see `CoatyTimestamp.nowMillis()` or `CoatyTimestamp.dateMillis()`)
    public var creationTimestamp: Double
    
    /// Coaty compatible timestamp when task has been changed (optional).
    /// (see `CoatyTimestamp.nowMillis()` or `CoatyTimestamp.dateMillis()`)
    public var lastModificationTimestamp: Double?
    
    /// Coaty compatible timestamp when task should be due (optional).
    /// (see `CoatyTimestamp.nowMillis()` or `CoatyTimestamp.dateMillis()`)
    public var dueTimestamp: Double?
    
    /// Coaty compatible timestamp when task has been done (optional).
    /// (see `CoatyTimestamp.nowMillis()` or `CoatyTimestamp.dateMillis()`)
    public var doneTimestamp: Double?
    
    /// The amount of time (in milliseconds) the task will
    /// take or should took to complete (optional).
    public var duration: Double?
    
    /// Status of task.
    public var status: TaskStatus
    
    /// Required competencies, roles, etc. needed to fulfill this task
    /// (optional). Requirements are specified as key-value pairs with JSON
    /// compatible values.
    public var requirements: [String: Any]?
    
    /// Description of the task (optional)
    public var desc: String?

    /// Unique ID of object that this task is assigned to (optional).
    public var assigneeObjectId: CoatyUUID?

    // MARK: - Initializers.

    /// Default initializer for a `Task` object.
    public init(creatorId: CoatyUUID,
                creationTimestamp: Double,
                status: TaskStatus,
                name: String = "TaskObject",
                objectType: String = Task.objectType,
                objectId: CoatyUUID = .init(),
                lastModificationTimestamp: Double? = nil,
                dueTimestamp: Double? = nil,
                doneTimestamp: Double? = nil,
                requirements: [String: Any]? = nil,
                description: String? = nil,
                assigneeObjectId: CoatyUUID? = nil) {
        self.creatorId = creatorId
        self.creationTimestamp = creationTimestamp
        self.status = status
        self.lastModificationTimestamp = lastModificationTimestamp
        self.dueTimestamp = dueTimestamp
        self.doneTimestamp = doneTimestamp
        self.requirements = requirements
        self.desc = description
        self.assigneeObjectId = assigneeObjectId
        super.init(coreType: .Task, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum TaskCodingKeys: String, CodingKey, CaseIterable {
        case creatorId
        case creationTimestamp
        case status
        case lastModificationTimestamp
        case dueTimestamp
        case doneTimestamp
        case requirements
        case description
        case assigneeObjectId
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TaskCodingKeys.self)
        self.creatorId = try container.decode(CoatyUUID.self, forKey: .creatorId)
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.status = try container.decode(TaskStatus.self, forKey: .status)
        self.lastModificationTimestamp = try container.decodeIfPresent(Double.self, forKey: .lastModificationTimestamp)
        self.dueTimestamp = try container.decodeIfPresent(Double.self, forKey: .dueTimestamp)
        self.doneTimestamp = try container.decodeIfPresent(Double.self, forKey: .doneTimestamp)
        self.requirements = try container.decodeIfPresent([String: Any].self, forKey: .requirements)
        self.desc = try container.decodeIfPresent(String.self, forKey: .description)
        self.assigneeObjectId = try container.decodeIfPresent(CoatyUUID.self, forKey: .assigneeObjectId)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: TaskCodingKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: TaskCodingKeys.self)
        try container.encode(creatorId.string, forKey: .creatorId)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(lastModificationTimestamp, forKey: .lastModificationTimestamp)
        try container.encodeIfPresent(dueTimestamp, forKey: .dueTimestamp)
        try container.encodeIfPresent(doneTimestamp, forKey: .doneTimestamp)
        try container.encodeIfPresent(requirements, forKey: .requirements)
        try container.encodeIfPresent(desc, forKey: .description)
        try container.encodeIfPresent(assigneeObjectId, forKey: .assigneeObjectId)
    }
}

/// Predefined status values of Task objects.
public enum TaskStatus: Int, Codable, CaseIterable {
    
    /// Initial state of a new task.
    case pending = 0
    
    /// Task is in progress.
    case inProgress = 1
    
    /// Task is completed.
    case done = 2
    
    /// Task is blocked, e.g. because of a problem.
    case blocked = 3
    
    /// Task is cancelled.
    case cancelled = 4
    
    /// Task Request.
    case request = 5
    
    /// Task Request Cancelled.
    case requestCancelled = 6
    
    public init?(stringValue: String) {
        switch stringValue {
        case "pending":
            self = .pending
        case "inProgress":
            self = .inProgress
        case "done":
            self = .done
        case "blocked":
            self = .blocked
        case "request":
            self = .request
        case "requestCancelled":
            self = .requestCancelled
        case "cancelled":
            self = .cancelled
        default:
            return nil
        }
    }
}

extension TaskStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .pending:
            return "pending"
        case .inProgress:
            return "inProgress"
        case .done:
            return "done"
        case .blocked:
            return "blocked"
        case .request:
            return "request"
        case .requestCancelled:
            return "requestCancelled"
        case .cancelled:
            return "cancelled"
        }
    }
}
