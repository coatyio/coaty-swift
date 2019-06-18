// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Topic.swift
//  CoatySwift
//
//

import Foundation

/// Topic represents a Coaty topic as defined in the
/// [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-structure)
///
/// - TODO: Rename to CommunicationTopic to match Coaty-js implementation.
/// - TODO: Ability to generate readable topics.
class Topic {
    
    // MARK: - Public Attributes.
    
    var protocolVersion: Int
    /// event returns the entire event string including separators and filters,
    /// e.g. Advertise:Component or Advertise::org.example.object
    var event: String
    var eventType: CommunicationEventType
    var coreType: CoreType?
    var objectType: String?
    var associatedUserId: CoatyUUID?
    var sourceObjectId: CoatyUUID
    var messageToken: String
    var channelId: String?
    var callOperationId: String?
    
    /// String representation for the topic.
    var string: String { get {
        return "\(TOPIC_SEPARATOR)\(COATY)"
            + "\(TOPIC_SEPARATOR)\(PROTOCOL_VERSION)"
            + "\(TOPIC_SEPARATOR)\(event)"
            + "\(TOPIC_SEPARATOR)\(associatedUserId?.string ?? EMPTY_ASSOCIATED_USER_ID)"
            + "\(TOPIC_SEPARATOR)\(sourceObjectId)"
            + "\(TOPIC_SEPARATOR)\(messageToken)"
            + "\(TOPIC_SEPARATOR)"
        }
    }
    
    // MARK: - Initializers.
    
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
        let eventType = try Topic.extractEventType(event)
        self.eventType = eventType
        let objectType = Topic.extractObjectType(event)
        let coreType = Topic.extractCoreType(event)
        let channelId = Topic.extractChannelId(event)
        let callOperationId = Topic.extractCallOperationId(event)

        // Check if coreType or objectType have been set correctly.
        // TODO: Extract this and implement behavior for topic string convenience methods.
        if Topic.isEventTypeFilterRequired(forEvent: eventType) {
            if eventType == .Channel && channelId == nil {
                 throw CoatySwiftError.InvalidArgument("\(eventType.rawValue) requires a set channelId.")
            } else if eventType == .Call && callOperationId == nil {
                throw CoatySwiftError.InvalidArgument("\(eventType.rawValue) requires a set callOperationId.")
            } else if eventType != .Channel && eventType != .Call && objectType == nil && coreType == nil {
                throw CoatySwiftError.InvalidArgument("\(eventType.rawValue) requires a set eventTypeFilter.")
            }
            
            if eventType != .Channel && objectType != nil && coreType != nil {
                throw CoatySwiftError.InvalidArgument("You have to specify either the objectType or the coreType.")
            }
        }
        
        self.callOperationId = callOperationId
        self.channelId = channelId
        self.coreType = coreType
        self.objectType = objectType
        
        // Try to parse a associatedUserId, if none is set, the topic will contain "-" here and the
        // initializer will fail and return nil.
        guard let sanitizedAssociatedUserId = Topic.extractIdFromReadableString(associatedUserId) else {
            throw CoatySwiftError.InvalidArgument("Could not sanitize associatedUserId")
        }
        
        self.associatedUserId = CoatyUUID(uuidString: sanitizedAssociatedUserId)
        
        // Parse sourceObjectId.
        guard let sanitizedSourceObjectId = Topic.extractIdFromReadableString(sourceObjectId) else {
            throw CoatySwiftError.InvalidArgument("Could not sanitize sourceObjectId.")
        }
        
        // Parse associatedUserId.
        guard let sourceObjectIdAsUUID = CoatyUUID(uuidString: sanitizedSourceObjectId) else {
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
    /// - Parameters:
    ///   - topic: string representation of a Coaty communication topic.
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
    
    // MARK: - Helper methods.
    
    /// Helper method that creates a topic string with wildcards.
    /// See [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-filters)
    /// - Parameters:
    ///   - coatyVersion: the current Coaty version.
    ///   - eventType: CommunicationEventType (e.g. Advertise)
    ///   - eventTypeFilter: may either be a core type (e.g. Component) or an object type
    ///     (e.g. org.example.object)
    ///   - associatedUserId: an optional UUID String, if the parameter is ommitted it is replaced
    ///     with a wildcard.
    ///   - sourceObject: the Coaty object that issued the method call, if the parameter is ommitted
    ///     it is replaced with a wildcard.
    ///   - messageToken: if ommitted it is replaced with a wildcard.
    /// - Returns: A topic string with correct wildcards.
    private static func createTopicStringByLevels(coatyVersion: Int?,
                                                  eventType: CommunicationEventType,
                                                  eventTypeFilter: String? = nil,
                                                  associatedUserId: String? = nil,
                                                  sourceObject: CoatyObject? = nil,
                                                  messageToken: String? = nil) throws -> String {
    
        // Select the correct separator.
        var event = eventType.rawValue
        
        if let eventTypeFilter = eventTypeFilter {
            // Support creation of channel and corresponding channelId.
            if eventType == .Channel {
                let separator = CORE_TYPE_SEPARATOR
                event = eventType.rawValue + separator + eventTypeFilter
            } else if eventType == .Call {
                let separator = CORE_TYPE_SEPARATOR
                event = eventType.rawValue + separator + eventTypeFilter
            } else {
                let separator = isCoreType(eventTypeFilter) ? CORE_TYPE_SEPARATOR : OBJECT_TYPE_SEPARATOR
                event = eventType.rawValue + separator + eventTypeFilter
            }
        }
        
        // Build correct version string.
        var versionString = WILDCARD_TOPIC
        if let version = coatyVersion {
            versionString = "\(version)"
        }
        
        return "\(TOPIC_SEPARATOR)\(COATY)"
            + "\(TOPIC_SEPARATOR)\(versionString)"
            + "\(TOPIC_SEPARATOR)\(event)"
            + "\(TOPIC_SEPARATOR)\(associatedUserId ?? WILDCARD_TOPIC)"
            + "\(TOPIC_SEPARATOR)\(sourceObject?.objectId.string ?? WILDCARD_TOPIC)"
            + "\(TOPIC_SEPARATOR)\(messageToken ?? WILDCARD_TOPIC)"
            + "\(TOPIC_SEPARATOR)"
    }
    
    /// Convenience Method to create a topic string that can be used for publications.
    /// See [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-filters)
    /// - Parameters:
    ///   - eventType: CommunicationEventType (e.g. Advertise)
    ///   - eventTypeFilter: may either be a core type (e.g. Component) or an object type
    ///     (e.g. org.example.object)
    ///   - associatedUserId: an optional UUID String, if the parameter is ommitted it is replaced
    ///     with a wildcard.
    ///   - sourceObject: the Coaty object that issued the method call, if the parameter is ommitted
    ///     it is replaced with a wildcard.
    ///   - messageToken: if ommitted it is replaced with a wildcard.
    /// - Returns: A topic string that can be used for publications.
    static func createTopicStringByLevelsForPublish(eventType: CommunicationEventType,
                                                    eventTypeFilter: String? = nil,
                                                    associatedUserId: String? = nil,
                                                    sourceObject: CoatyObject? = nil,
                                                    messageToken: String? = nil) throws -> String {
        
        return try createTopicStringByLevels(coatyVersion: PROTOCOL_VERSION,
                                         eventType: eventType,
                                         eventTypeFilter: eventTypeFilter,
                                         associatedUserId: associatedUserId,
                                         sourceObject: sourceObject,
                                         messageToken: messageToken)
    }
    
    /// Convenience Method to create a topic string that can be used for subscriptions.
    /// See [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-filters)
    /// - Parameters:
    ///   - eventType: CommunicationEventType (e.g. Advertise)
    ///   - eventTypeFilter: may either be a core type (e.g. Component) or an object type
    ///     (e.g. org.example.object)
    ///   - associatedUserId: an optional UUID String, if the parameter is ommitted it is replaced
    ///     with a wildcard.
    ///   - sourceObject: the Coaty object that issued the method call, if the parameter is ommitted
    ///     it is replaced with a wildcard.
    ///   - messageToken: if ommitted it is replaced with a wildcard.
    /// - Returns: A topic string that can be used for subscriptions.
    static func createTopicStringByLevelsForSubscribe(eventType: CommunicationEventType,
                                                      eventTypeFilter: String? = nil,
                                                      associatedUserId: String? = nil,
                                                      sourceObject: CoatyObject? = nil,
                                                      messageToken: String? = nil) throws -> String {
        
        return try createTopicStringByLevels(coatyVersion: nil,
                                         eventType: eventType,
                                         eventTypeFilter: eventTypeFilter,
                                         associatedUserId: associatedUserId,
                                         sourceObject: sourceObject,
                                         messageToken: messageToken)
    }
    
    static func createTopicStringByLevelsForChannel(channelId: String? = nil,
                                                    associatedUserId: String? = nil,
                                                    sourceObject: CoatyObject? = nil,
                                                    messageToken: String? = nil) throws -> String {
        
        return try createTopicStringByLevels(coatyVersion: nil,
                                         eventType: .Channel,
                                         eventTypeFilter: channelId,
                                         associatedUserId: associatedUserId,
                                         sourceObject: sourceObject,
                                         messageToken: messageToken)
    }
    
    static func createTopicStringByLevelsForCall(operationId: String? = nil,
                                                    associatedUserId: String? = nil,
                                                    sourceObject: CoatyObject? = nil,
                                                    messageToken: String? = nil) throws -> String {
        
        return try createTopicStringByLevels(coatyVersion: PROTOCOL_VERSION,
                                             eventType: .Call,
                                             eventTypeFilter: operationId,
                                             associatedUserId: associatedUserId,
                                             sourceObject: sourceObject,
                                             messageToken: messageToken)
    }
    
    // MARK: - Parsing helper methods.
    
    /// Checks whether the eventTypeFilter field has to be set for a specific event type.
    ///
    /// - Parameter event: the event type
    /// - Returns: whether the eventTypeFilter field has to be set or not.
    private static func isEventTypeFilterRequired(forEvent event: CommunicationEventType) -> Bool {
        // Events that require an eventTypeFilter to be set.
        // TODO: Are these all events?
        let events: [CommunicationEventType] = [.Advertise, .Channel, .Call]
        return events.contains(event)
    }
    
    private static func isCoreType(_ eventTypeFilter: String) -> Bool {
        return CoreType(rawValue: eventTypeFilter) != nil
    }
    
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
        if !event.contains(CORE_TYPE_SEPARATOR) {
            return nil
        }
        
        // Take the second element (the core type) and return it.
        let eventTypeComponents = event.components(separatedBy: CORE_TYPE_SEPARATOR).dropFirst()
        guard let coreTypeString = eventTypeComponents.first else {
            return nil
        }
        
        return CoreType(rawValue: coreTypeString)
    }
    
    private static func extractChannelId(_ event: String) -> String? {
        if !event.contains("Channel\(CORE_TYPE_SEPARATOR)") {
            return nil
        }
        
        // Take the second element (the channelId) and return it.
        let eventTypeComponents = event.components(separatedBy: CORE_TYPE_SEPARATOR).dropFirst()
        return eventTypeComponents.first
    }
    
    private static func extractCallOperationId(_ event: String) -> String? {
        if !event.contains("Call\(CORE_TYPE_SEPARATOR)") {
            return nil
        }
        
        // Take the second element (the callOperationId) and return it.
        let eventTypeComponents = event.components(separatedBy: CORE_TYPE_SEPARATOR).dropFirst()
        return eventTypeComponents.first
    }
    
    private static func extractEventType(_ event: String) throws -> CommunicationEventType {
        if !(event.contains(CORE_TYPE_SEPARATOR) || event.contains(OBJECT_TYPE_SEPARATOR)) {
            guard let communicationEventType = CommunicationEventType(rawValue: event) else {
                throw CoatySwiftError.InvalidArgument("Event needs to contain a valid CommunicationEventType")
            }
            
            return communicationEventType
        }
        
        // This is required to parse Advertise events correct. (In the future: Channels).
        guard let communicationEventTypeString = event.components(
            separatedBy: CORE_TYPE_SEPARATOR).first else {
                throw CoatySwiftError.InvalidArgument("Event needs to contain a valid CommunicationEventType")
        }
        
        guard let communicationEventType = CommunicationEventType(
            rawValue: communicationEventTypeString) else {
                throw CoatySwiftError.InvalidArgument("Unknown CommunicationEventType")
        }
        
        return communicationEventType
    }
    
    /// Returns the Id from a string that was created using readable topic names.
    private static func extractIdFromReadableString(_ readable: String) -> String? {
        return readable.components(separatedBy: READABLE_TOPIC_SEPARATOR).last
    }
    
    /// Determines whether the given data is valid as an event type filter.
    ///
    /// - Parameter filter: an event type filter
    /// - Returns: true if the given topic name is a valid event type filter; false otherwise
    static func isValidEventTypeFilter(filter: String) -> Bool {
        return filter.count > 0
            && !filter.contains("\u{0000}")
            && !filter.contains("#")
            && !filter.contains("+")
            && !filter.contains("/")
    }
}
