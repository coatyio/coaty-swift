//
//  Task.swift
//  CoatySwift
//

import Foundation

// TODO: Comment me.
public enum TaskStatus: Int, Codable {
    case pending = 0
    case inProgress
    case done
    case blocked
    case cancelled
    case request
    case requestCancelled
}

open class Task: CoatyObject {
    
    // MARK: - Attributes.
    
    /**
     * Object ID of user who created the task
     */
    open var creatorId: UUID
    
    /**
     * Timestamp when task was issued/created.
     * Value represents the number of milliseconds since the epoc in UTC.
     * (see Date.getTime(), Date.now())
     */
    open var creationTimestamp: Double
    
    /**
     * Timestamp when task has been changed (optional).
     * Value represents the number of milliseconds since the epoc in UTC.
     * (see Date.getTime(), Date.now())
     */
    open var lastModificationTimestamp: Double?
    
    /**
     * Timestamp when task should be due (optional).
     * Value represents the number of milliseconds since the epoc in UTC.
     * (see Date.getTime(), Date.now())
     */
    open var dueTimestamp: Double?
    
    /**
     * Timestamp when task has been done (optional).
     * Value represents the number of milliseconds since the epoc in UTC.
     * (see Date.getTime(), Date.now())
     */
    open var doneTimestamp: Double?
    
    /**
     * The amount of time (in milliseconds) the task will
     * take or should took to complete (optional).
     */
    open var duration: Double?
    
    /**
     * Status of task
     */
    open var status: TaskStatus
    
    /**
     * Required competencies / roles needed for this task (optional).
     * The requirements specified are combined by logical AND, i.e. all
     * requirements must be fullfilled.
     */
    open var requirements: [String]?
    
    /**
     * Description of the task (optional)
     */
    open var description: [String]?
    
    /**
     * Associated workflow Id (optional)
     */
    open var workflowId: UUID?

    // MARK: - Initializers.
    
    public required init(coreType: CoreType, objectType: String, objectId: UUID, name: String) {
        fatalError("init(coreType:objectType:objectId:name:) has not been implemented")
    }
    
    public init(objectType: String,
                objectId: UUID,
                name: String,
                creatorId: UUID,
                creationTimestamp: Double,
                status: TaskStatus,
                lastModificationTimestamp: Double? = nil,
                dueTimestamp: Double? = nil,
                doneTimestamp: Double? = nil,
                requirements: [String]? = nil,
                description: [String]? = nil,
                workflowId: UUID? = nil) {
        self.creatorId = creatorId
        self.creationTimestamp = creationTimestamp
        self.status = status
        self.lastModificationTimestamp = lastModificationTimestamp
        self.dueTimestamp = dueTimestamp
        self.doneTimestamp = doneTimestamp
        self.requirements = requirements
        self.description = description
        self.workflowId = workflowId
        super.init(coreType: .Task, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case creatorId
        case creationTimestamp
        case status
        case lastModificationTimestamp
        case dueTimestamp
        case doneTimestamp
        case requirements
        case description
        case workflowId
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.creatorId = try container.decode(UUID.self, forKey: .creatorId)
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.status = try container.decode(TaskStatus.self, forKey: .status)
        self.lastModificationTimestamp = try container.decodeIfPresent(Double.self, forKey: .lastModificationTimestamp)
        self.dueTimestamp = try container.decodeIfPresent(Double.self, forKey: .dueTimestamp)
        self.doneTimestamp = try container.decodeIfPresent(Double.self, forKey: .doneTimestamp)
        self.requirements = try container.decodeIfPresent([String].self, forKey: .requirements)
        self.description = try container.decodeIfPresent([String].self, forKey: .description)
        self.workflowId = try container.decodeIfPresent(UUID.self, forKey: .workflowId)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(lastModificationTimestamp, forKey: .lastModificationTimestamp)
        try container.encodeIfPresent(dueTimestamp, forKey: .dueTimestamp)
        try container.encodeIfPresent(doneTimestamp, forKey: .doneTimestamp)
        try container.encodeIfPresent(requirements, forKey: .requirements)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(workflowId, forKey: .workflowId)
    }
}
