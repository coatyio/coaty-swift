//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationTopic.swift
//  CoatySwift
//
//

import Foundation

/// Encapsulates the internal representation of messaging topics used by the
/// [Coaty communication
/// infrastructure](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-structure).
class CommunicationTopic {

    // MARK: - Internal Attributes.
    
    var protocolVersion: Int
    var namespace: String
    var eventType: CommunicationEventType
    var eventTypeFilter: String? = nil
    var sourceId: CoatyUUID
    var correlationId: String? = nil
    
    // MARK: - Initializers.
    
    /// Creates a valid Topic object from a given MQTT publication topic string.
    ///
    /// - Parameters:
    ///   - topic: string representation of a Coaty publication topic.
    init(_ topic: String) throws {
        // .components() returns empty strings at the beginning/end
        // if string starts with/ends with the separator.
        // e.g. /a/b/c/ => ["", "a", "b", "c", ""]
        let topicLevels = topic.components(separatedBy: TOPIC_SEPARATOR)
        
        guard topicLevels.count >= 5 else {
            throw CoatySwiftError.InvalidArgument("Invalid topic.")
        }
        
        let protocolName = topicLevels[0]
        let version = topicLevels[1]
        let namespace = topicLevels[2]
        let eventName = topicLevels[3]
        let sourceId = topicLevels[4]
        let corrId: String? = topicLevels.count == 6 ? topicLevels[5] : nil
        let postfix: String? = topicLevels.count >= 7 ? topicLevels[6] : nil

        guard protocolName == PROTOCOL_NAME && version != "" && namespace != "" && eventName != "" && sourceId != "" else {
            throw CoatySwiftError.InvalidArgument("Invalid topic.")
        }
        guard (corrId == nil && postfix == nil) || (corrId != nil && corrId != "" && postfix == nil) else {
            throw CoatySwiftError.InvalidArgument("Invalid topic.")
        }
        // No need to validate protocol version as subscriptions are filtered by PROTOCOL_VERSION.
        // guard let protocolVersion = Int(version) else {
        //    throw CoatySwiftError.InvalidArgument("Invalid topic protocol version.")
        // }
        // guard protocolVersion == PROTOCOL_VERSION else {
        //    throw CoatySwiftError.InvalidArgument("Unsupported topic protocol version \(protocolVersion).")
        // }
        guard let sourceIdAsUUID = CoatyUUID(uuidString: sourceId) else {
            throw CoatySwiftError.InvalidArgument("Invalid topic sourceId.")
        }

        guard let (eventType, eventTypeFilter) = try CommunicationTopic.extractEventType(eventName) else {
            throw CoatySwiftError.InvalidArgument("Invalid topic event type: \(eventName)")
        }

        if eventType.isOneWay {
            if corrId != nil {
                throw CoatySwiftError.InvalidArgument("Topic has correlation id for one-way \(eventType) event")
            }
            if (eventType == .Advertise || eventType == .Channel || eventType == .Associate) &&
                (eventTypeFilter == nil || eventTypeFilter!.isEmpty) {
                throw CoatySwiftError.InvalidArgument("Topic missing event filter for \(eventType) event")
            }
            if  eventType != .Advertise && eventType != .Channel && eventType != .Associate && eventTypeFilter != nil {
                throw CoatySwiftError.InvalidArgument("Topic has event filter for \(eventType) event")
            }
        } else {
            if corrId == nil {
                throw CoatySwiftError.InvalidArgument("Topic missing correlation id for two-way event: \(eventType)")
            }
            if (eventType == .Call || eventType == .Update) &&
                (eventTypeFilter == nil || eventTypeFilter!.isEmpty) {
                throw CoatySwiftError.InvalidArgument("Topic missing event filter for \(eventType) event")
            }
            if eventType != .Call && eventType != .Update && eventTypeFilter != nil {
                throw CoatySwiftError.InvalidArgument("Topic has event filter for \(eventType) event")
            }
        }

        self.protocolVersion = PROTOCOL_VERSION
        self.namespace = namespace
        self.eventType = eventType
        self.eventTypeFilter = eventTypeFilter
        self.sourceId = sourceIdAsUUID
        self.correlationId = corrId
    }
    
    // MARK: - Utility methods.

    /// Determines whether the given data is valid as an event type filter.
    ///
    /// - Parameter filter: an event type filter
    /// - Returns: true if the given topic name is a valid event type filter; false otherwise
    static func isValidEventTypeFilter(filter: String) -> Bool {
        return self.isValidPublicationTopic(filter) && !filter.contains("/")
    }


    /// Determines whether the given name is a valid topic name for publication.
    ///
    /// - Parameter name: a string
    /// - Returns: true if the given name can be used for publication; false otherwise
    static func isValidPublicationTopic(_ name: String) -> Bool {
        return name.count > 0
            && !name.contains("\u{0000}")
            && !name.contains("#")
            && !name.contains("+")
    }

    /// Determines whether the given name is a valid topic filter for subscribing.
    ///
    /// - Parameter name: a string
    /// - Returns: true if the given name can be used for subscriptions; false otherwise
    static func isValidSubscriptionTopic(_ name: String) -> Bool {
        return name.count > 0
            && !name.contains("\u{0000}")
    }
    
    /// Determines whether the given topic should be dispatched to raw observers.
    ///
    /// - Parameter topic: an incoming topic string
    /// - Returns: false if the topic starts with "coaty/"; true otherwise
    static func isRawTopic(topic: String) -> Bool {
        return !topic.hasPrefix(PROTOCOL_NAME_PREFIX)
    }
    
    /// Determines whether the given MQTT topic matches the given MQTT topic filter.
    ///
    /// Examples:
    /// * topic filter a/b/# match topics a/b/c/d, a/b/c, ...
    /// * topic filter a/+/+ match topic a/b/c, but _not_ a/b/c/d, ...
    /// * topic filter a/+/b match topic a/c/b and a//b
    /// * topic filters / and +/ and /+ and +/+ match topic /
    ///
    /// - Note: Matching assumes that both topic and filter are valid according
    ///         to the MQTT 3.1.1 specification. Otherwise, the result is not defined.
    ///
    /// - Parameters:
    ///     - topic: a valid MQTT topic name
    ///     - filter: a valid MQTT topic filter
    /// - Returns:true if topic matches filter; otherwise false
    static func matches(_ topic: String, _ filter: String) -> Bool {
        if topic.isEmpty || filter.isEmpty {
            return false
        }
        
        let patternLevels = filter.components(separatedBy: TOPIC_SEPARATOR)
        let topicLevels = topic.components(separatedBy: TOPIC_SEPARATOR)

        let patternLength = patternLevels.count
        let topicLength = topicLevels.count
        let lastIndex = patternLength - 1

        for i in 0...lastIndex {
            let currentPatternLevel = patternLevels[i]
            let currentLevel = i < topicLength ? topicLevels[i] : nil
            let currentLevelEmpty = currentLevel?.isEmpty ?? true
            
            if currentLevelEmpty && currentPatternLevel.isEmpty {
                continue
            }

            if currentLevelEmpty && currentPatternLevel == SINGLE_TOPIC_LEVEL_WILDCARD {
                continue
            }

            if currentLevelEmpty && currentPatternLevel != MULTI_TOPIC_LEVEL_WILDCARD {
                return false
            }

            if currentPatternLevel == MULTI_TOPIC_LEVEL_WILDCARD {
                return i == lastIndex
            }

            if currentPatternLevel != SINGLE_TOPIC_LEVEL_WILDCARD && currentPatternLevel != currentLevel {
                return false
            }
        }

        return patternLength == topicLength
    }
    
    /// Gets the topic event level consisting of the given event type and optional event type filter.
    static func getEventLevel(eventType: CommunicationEventType, eventTypeFilter: String?) -> String {
        var eventLevel = eventType.rawValue
        
        if eventTypeFilter != nil {
            eventLevel += EVENT_TYPE_FILTER_SEPARATOR + eventTypeFilter!
        }
        
        return eventLevel
    }

    /// Convenience Method to create a topic string that can be used for publications.
    /// See [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-structure)
    /// - Parameters:
    ///   - namepace: the messaging namespace
    ///   - sourceId: UUID from which this event originates
    ///   - eventType: CommunicationEventType
    ///   - eventTypeFilter: optional event filter
    ///   - correlationId: correlation ID for two-way message, or nil for one-way message
    /// - Returns: a topic string that can be used for publication
    static func createTopicStringByLevelsForPublish(namespace: String,
                                                    sourceId: CoatyUUID,
                                                    eventType: CommunicationEventType,
                                                    eventTypeFilter: String? = nil,
                                                    correlationId: String? = nil) -> String {
        let eventLevel = getEventLevel(eventType: eventType, eventTypeFilter: eventTypeFilter)
        var topic = "\(PROTOCOL_NAME)"
            + "\(TOPIC_SEPARATOR)\(PROTOCOL_VERSION)"
            + "\(TOPIC_SEPARATOR)\(namespace)"
            + "\(TOPIC_SEPARATOR)\(eventLevel)"
            + "\(TOPIC_SEPARATOR)\(sourceId.string)"

        if !eventType.isOneWay {
            topic += "\(TOPIC_SEPARATOR)\(correlationId!)"
        }

        return topic;
    }
    
    /// Convenience Method to create a topic string that can be used for subscriptions.
    /// See [Communication Protocol](https://coatyio.github.io/coaty-js/man/communication-protocol/#topic-filters)
    /// - Parameters:
    ///   - eventType: CommunicationEventType
    ///   - eventTypeFilter: optional event filter
    ///   - namespace: the messaging namespace or nil for wildcard namespacing
    ///   - correlationId: correlation ID for response message subscription, or nil
    ///     for request message subscription with wildcard
    /// - Returns: a topic string that can be used for subscriptions
    static func createTopicStringByLevelsForSubscribe(eventType: CommunicationEventType,
                                                      eventTypeFilter: String? = nil,
                                                      namespace: String? = nil,
                                                      correlationId: String? = nil) -> String {
        let eventLevel = getEventLevel(eventType: eventType, eventTypeFilter: eventTypeFilter)
        var topic = "\(PROTOCOL_NAME)"
            + "\(TOPIC_SEPARATOR)\(PROTOCOL_VERSION)"
            + "\(TOPIC_SEPARATOR)\(namespace ?? SINGLE_TOPIC_LEVEL_WILDCARD)"
            + "\(TOPIC_SEPARATOR)\(eventLevel)"
            + "\(TOPIC_SEPARATOR)\(SINGLE_TOPIC_LEVEL_WILDCARD)"

        if !eventType.isOneWay {
            topic += "\(TOPIC_SEPARATOR)\(correlationId ?? SINGLE_TOPIC_LEVEL_WILDCARD)"
        }

        return topic;
    }
    
    // MARK: - Parsing helper methods.
    
    private static func extractEventType(_ eventName: String) throws -> (CommunicationEventType, String?)? {
        let index = eventName.firstIndex(of: EVENT_TYPE_FILTER_SEPARATOR[EVENT_TYPE_FILTER_SEPARATOR.startIndex])
        let eventType = index == nil ? eventName : String(eventName[..<index!])
        let eventTypeFilter = index == nil ? nil : String(eventName[eventName.index(after: index!)...])
        
        guard let evType = CommunicationEventType.from(eventType) else {
            return nil;
        }
        return (evType, eventTypeFilter)
    }

}
