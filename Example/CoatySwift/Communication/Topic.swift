//
//  Topic.swift
//  CoatySwift
//
//

import Foundation

/// Topic represents a Coaty topic as defined in
/// https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-structure
/// TODO: Ability to generate readable topics.
class Topic {
    
    // MARK: - Attributes.
    
    var protocolVersion: Int
    var event: String
    var coreType: CoreType?
    var objectType: String?
    var associatedUserId: UUID?
    var sourceObjectId: UUID
    var messageToken: String
    
    /// String representation for the topic.
    var string: String { get {
        return "\(TOPIC_SEPARATOR)\(COATY)"
            + "\(TOPIC_SEPARATOR)\(PROTOCOL_VERSION)"
            + "\(TOPIC_SEPARATOR)\(event)"
            + "\(TOPIC_SEPARATOR)\(associatedUserId?.uuidString ?? EMPTY_ASSOCIATED_USER_ID)"
            + "\(TOPIC_SEPARATOR)\(sourceObjectId)"
            + "\(TOPIC_SEPARATOR)\(messageToken)"
            + "\(TOPIC_SEPARATOR)"
        }
    }
    
    /// This initializer checks all required conditions to return a valid Coaty Topic.
    /// Note that it also accepts arguments taken from readable topics.
    init(protocolVersion: Int, event: String, associatedUserId: String, sourceObjectId: String,
         messageToken: String) throws {
        
        // Check if protocol version is compatible.
        if protocolVersion != PROTOCOL_VERSION {
            throw CoatySwiftError.InvalidArgument("Unsupported protocol version.")
        }
        
        self.protocolVersion = protocolVersion
        
        // Initialize event fields.
        self.event = event
        let coreType = Topic.extractCoreType(event)
        let objectType = Topic.extractObjectType(event)
        
        // Check if event could be parsed.
        if (coreType == nil && objectType == nil) {
            throw CoatySwiftError.InvalidArgument("Event could not be parsed.")
        }
        
        // Fill either coreType or objectType.
        if (coreType == nil && objectType == nil) || (coreType != nil && objectType != nil) {
            throw CoatySwiftError.InvalidArgument("You can only specify coreType OR objectType.")
        }
        
        self.coreType = coreType
        self.objectType = objectType
        
        // Try to parse a associatedUserId, if none is set, the topic will contain "-" here and the
        // initializer will fail and return nil.
        guard let sanitizedAssociatedUserId = Topic.extractIdFromReadableString(associatedUserId) else {
            throw CoatySwiftError.InvalidArgument("Could not sanitize associatedUserId")
        }
        
        self.associatedUserId = UUID.init(uuidString: sanitizedAssociatedUserId)
        
        // Parse sourceObjectId.
        guard let sanitizedSourceObjectId = Topic.extractIdFromReadableString(sourceObjectId) else {
            throw CoatySwiftError.InvalidArgument("Could not sanitize sourceObjectId.")
        }
        
        // Parse associatedUserId
        guard let sourceObjectIdAsUUID = UUID.init(uuidString: sanitizedSourceObjectId) else {
            throw CoatySwiftError.InvalidArgument("Invalid sourceObjectId.")
        }
        
        self.sourceObjectId = sourceObjectIdAsUUID
        
        // FIXME: Parse messageToken. The documentation is unclear about the format of a message token.
        // Is it a UUID? How about readable versions?
        // guard let messageTokenAsUUID = UUID.init(uuidString: messageToken) else {
        //     throw CoatySwiftError.InvalidArgument("Invalid messageToken.")
        // }
        
        self.messageToken = messageToken
    }
    
    
    /// Initializes a Topic object from a string value.
    /// The expected structure therefore looks like:
    /// /coaty/<ProtocolVersion>/<Event>/<AssociatedUserId>/<SourceObjectId>/<MessageToken>/
    convenience init(_ topic: String) throws {
        var topicLevels = topic.components(separatedBy: TOPIC_SEPARATOR)
        
        // .components() returns empty strings at the beginning and the end.
        // e.g. /a/b/c/ => ["", "a", "b", "c", ""]
        topicLevels = Array(topicLevels.dropFirst())
        topicLevels = Array(topicLevels.dropLast())
        
        // Check if all topic fields are available.
        if topicLevels.count != 6 {
            throw CoatySwiftError.InvalidArgument("Wrong amount of topic levels.")
        }
        
        guard let protocolVersion = Int(topicLevels[1]) else {
            throw CoatySwiftError.InvalidArgument("Invalid protocol version.")
        }
        
        let event = topicLevels[2]
        let associatedUserId = topicLevels[3]
        let sourceObjectId = topicLevels[4]
        let messageToken = topicLevels[5]
        
        try self.init(protocolVersion: protocolVersion,
                      event: event,
                      associatedUserId: associatedUserId,
                      sourceObjectId: sourceObjectId,
                      messageToken: messageToken
        )
    }
    
    // MARK: - Parsing helper methods.
    
    private static func extractObjectType(_ event: String) -> String? {
        // Object types are separated as follows: "Advertise::<coreType>".
        if !event.contains(OBJECT_TYPE_SEPARATOR) {
            return nil
        }
        
        // Take the second element (the object type) and return it.
        let eventTypeComponents = event.components(separatedBy: OBJECT_TYPE_SEPARATOR).dropFirst()
        return eventTypeComponents.first
    }
    
    private static func extractCoreType(_ event: String) -> CoreType? {
        // Core types are separated as follows: "Advertise:<coreType>".
        if !event.contains(FILTER_SEPARATOR) {
            return nil
        }
        
        // Take the second element (the core type) and return it.
        let eventTypeComponents = event.components(separatedBy: FILTER_SEPARATOR).dropFirst()
        guard let coreTypeString = eventTypeComponents.first else {
            return nil
        }
        
        return CoreType(rawValue: coreTypeString)
    }
    
    /// Returns the Id from a string that was created using readable topic names.
    private static func extractIdFromReadableString(_ readable: String) -> String? {
        return readable.components(separatedBy: READABLE_TOPIC_SEPARATOR).last
    }
}
