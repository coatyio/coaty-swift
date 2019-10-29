//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CallEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates CallEvents.
public class CallEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
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
    public func with(operation: String, parameters: [String: AnyCodable],
                     filter: ContextFilter? = nil) -> CallEvent<Family> {
        let callEventdata = CallEventData<Family>.createFrom(parameters: parameters,
                                                             filter: filter)
        return .init(eventSource: self.identity,
                     eventData: callEventdata,
                     operation: operation)
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
    public func with(operation: String, parameters: [AnyCodable],
                     filter: ContextFilter? = nil) -> CallEvent<Family> {
        let callEventdata = CallEventData<Family>.createFrom(parameters: parameters,
                                                             filter: filter)
        
        return .init(eventSource: self.identity, eventData: callEventdata, operation: operation)
    }

}

/// Defines criteria for filtering Coaty objects. Used in combination with Call
/// events, and with the `ObjectMatcher` functionality.
public typealias ContextFilter = ObjectFilter

/// Defines a filter condition for filtering Coaty objects. Used in combination
/// with Call events, and with the `ObjectMatcher` functionality.
public typealias ContextFilterCondition = ObjectFilterCondition

/// CallEvent provides a generic implementation for invoking remote operations.
public class CallEvent<Family: ObjectFamily>: CommunicationEvent<CallEventData<Family>> {
    
    // MARK: - Internal attributes.
    
    internal var operation: String?
    
    /// Provides a Return handler for reacting to Call events.
    internal var returnHandler: ((ReturnEvent<Family>) -> Void)?

    // MARK: - Initializers.
    
    /// Respond to an observed Call event by sending the given Return event.
    ///
    /// - Parameter returnEvent: a Return event.
    public func returned(returnEvent: ReturnEvent<Family>) {
        if let returnHandler = returnHandler {
            returnHandler(returnEvent)
        }
    }
    
    fileprivate override init(eventSource: Identity, eventData: CallEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    fileprivate init(eventSource: Identity, eventData: CallEventData<Family>, operation: String) {
        
        if !CommunicationTopic.isValidEventTypeFilter(filter: operation) {
            LogManager.log.warning("\(operation) is not a valid operation name.")
        }
        
        super.init(eventSource: eventSource, eventData: eventData)
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
public class CallEventData<Family: ObjectFamily>: CommunicationEventData {
    
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
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case parameters
        case filter
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.parameterDictionary = try container.decodeIfPresent([String: AnyCodable].self,
                                                                     forKey: .parameters)
        } catch { /* Surpress error. */ }
        
        do {
            self.parameterArray = try container.decodeIfPresent([AnyCodable].self,
                                                                forKey: .parameters)
        } catch { /* Surpress error. */ }
    
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
