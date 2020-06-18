//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CallEvent.swift
//  CoatySwift
//

import Foundation

/// Defines criteria for filtering Coaty objects. Used in combination with Call
/// events, and with the `ObjectMatcher` functionality.
public typealias ContextFilter = ObjectFilter

/// Defines a filter condition for filtering Coaty objects. Used in combination
/// with Call events, and with the `ObjectMatcher` functionality.
public typealias ContextFilterCondition = ObjectFilterCondition

/// CallEvent provides a generic implementation for invoking remote operations.
public class CallEvent: CommunicationEvent<CallEventData> {
    
    // MARK: - Internal attributes.
    
    internal var operation: String?
    
    /// Provides a Return handler for reacting to Call events.
    internal var returnHandler: ((ReturnEvent) -> Void)?

    // MARK: - Static Factory Methods.

    /// Create a CallEvent instance for invoking a remote operation call with the given
    /// operation name, parameters (optional), and a context filter (optional).
    ///
    /// Parameters must be by-name through a JSON object.
    /// If a context filter is specified, the given remote call is only executed if
    /// the filter conditions match a context object provided by the remote end.
    ///
    /// - Parameters:
    ///     - operation: a non-empty string containing the name of the operation to be invoked
    ///     - parameters: holds the parameter values to be used during the invocation of
    ///       the operation (optional)
    ///     - filter: a context filter that must match a given context object at the remote
    ///       end (optional)
    /// - Returns: a Call event with the given parameters
    /// - Throws: if operation name is invalid
    public static func with(operation: String, parameters: [String: AnyCodable],
                            filter: ContextFilter? = nil) throws -> CallEvent {
        let callEventdata = CallEventData.createFrom(parameters: parameters,
                                                     filter: filter)
        return try .init(eventType: .Call, eventData: callEventdata, operation: operation)
    }
    
    /// Create a CallEvent instance for invoking a remote operation call with the given
    /// operation name, parameters (optional), and a context filter (optional).
    ///
    /// Parameters must be by-position through a JSON array.
    /// If a context filter is specified, the given remote call is only executed if
    /// the filter conditions match a context object provided by the remote end.
    ///
    /// - Parameters:
    ///     - operation: a non-empty string containing the name of the operation to be invoked
    ///     - parameters: holds the parameter values to be used during the invocation of
    ///       the operation (optional)
    ///     - filter: a context filter that must match a given context object at the remote
    ///       end (optional)
    /// - Returns: a Call event with the given parameters
    /// - Throws: if operation name is invalid
    public static func with(operation: String, parameters: [AnyCodable],
                            filter: ContextFilter? = nil) throws -> CallEvent {
        let callEventdata = CallEventData.createFrom(parameters: parameters,
                                                     filter: filter)
        return try .init(eventType: .Call, eventData: callEventdata, operation: operation)
    }

    /// Respond to a Call event with the given Return event.
    ///
    /// - Parameter returnEvent: a Return event.
    public func returned(returnEvent: ReturnEvent) {
        if let returnHandler = returnHandler {
            returnHandler(returnEvent)
        }
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: CallEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    fileprivate init(eventType: CommunicationEventType, eventData: CallEventData, operation: String) throws {
        guard CommunicationTopic.isValidEventTypeFilter(filter: operation) else {
            throw CoatySwiftError.InvalidArgument("Invalid call operation.")
        }
        
        super.init(eventType: eventType, eventData: eventData)
        self.typeFilter = operation
        self.operation = operation
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}



/// CallEventData provides the entire message payload data for a `CallEvent`.
public class CallEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// Parameter field that includes the array notation.
    public var parameterArray: [AnyCodable]?
    
    /// Parameter field that includes the object notation.
    public var parameterDictionary: [String: AnyCodable]?
    
    /// Defines conditions that must match a context object
    /// provided by the remote end in order to allow execution of the remote operation.
    public var filter: ContextFilter?
    
    // MARK: - Initializers.
    
    private init(_ parameterArray: [AnyCodable]? = nil,
                 _ paramaterDictionary: [String: AnyCodable]? = nil,
                 _ filter: ContextFilter? = nil) {
        super.init()
        self.parameterArray = parameterArray
        self.parameterDictionary = paramaterDictionary
        self.filter = filter
    }
    
    // MARK: - Factory methods.
    
    internal static func createFrom(parameters: [AnyCodable],
                                  filter: ContextFilter? = nil) -> CallEventData {
        return .init(parameters, nil, filter)
    }
    
    internal static func createFrom(parameters: [String: AnyCodable],
                                  filter: ContextFilter? = nil) -> CallEventData {
        return .init(nil, parameters, filter)
    }
    
    // MARK: - Access methods.
    
    /// Returns the value of the keyword parameter with the given name. Returns `nil`,
    /// if the given name is missing or if no keyword parameters have been specified.
    public func getParameterByName(name: String) -> Any? {
        guard let parameter = parameterDictionary?[name] else {
            return nil
        }
        
        return parameter.value
    }
    
    /// Returns the value of the positional parameter with the given index. Returns `nil`,
    /// if the given index is out of range or if no index parameters have been specified.
    public func getParameterByIndex(index: Int) -> Any? {
        guard let parameterArray = parameterArray, index >= 0, index < parameterArray.count else {
            return nil
        }
        
        return parameterArray[index].value
    }
    
    // MARK: - Filtering methods.
    
    /// Determines whether the given context object matches the context filter of
    /// this event data, returning false if it does not match, true otherwise.
    ///
    /// A match fails if:
    /// - context filter and context object are *both* specified and they do not
    ///   match (checked by using `ObjectMatcher.matchesFilter`), or
    /// - context filter is *not* specified *and* context object *is* specified.
    ///
    /// In all other cases, the match is considered successfull.
    ///
    /// Note that there is no need to use this operation in application code.
    /// When observing incoming Call events (via
    /// `CommunicationManager.observeCall`), the communication manager takes care
    /// to invoke this function automatically and to filter out events that do
    /// not match a given context.
    ///
    /// - Parameters:
    ///     - context: a CoatyObject to match against the context filter specified in event data (optional).
    /// - Returns: A boolean value indicating whether the context object matches the context filter.
    internal func matchesFilter(context: CoatyObject?) -> Bool {
        if (self.filter != nil && context != nil) {
            return ObjectMatcher.matchesFilter(obj: context, filter: self.filter)
        }
        if (self.filter == nil && context != nil) {
            return false
        }
        return true
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case parameters
        case filter
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.parameterDictionary = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .parameters)
        self.parameterArray = try? container.decodeIfPresent([AnyCodable].self, forKey: .parameters)
        self.filter = try container.decodeIfPresent(ContextFilter.self, forKey: .filter)
        
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.filter, forKey: .filter)
        try container.encodeIfPresent(self.parameterArray, forKey: .parameters)
        try container.encodeIfPresent(self.parameterDictionary, forKey: .parameters)
    }
    
}

