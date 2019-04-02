//
//  ReturnEvent.swift
//  CoatySwift
//

import Foundation

public class ReturnEvent<Family: ObjectFamily>: CommunicationEvent<ReturnEventData<Family>> {
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    private override init(eventSource: Component, eventData: ReturnEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // MARK: - Factory methods.

    /// Create a ReturnEvent instance for a remote operation call that successfully yields a result.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - result: the result value to be returned (any JSON data type)
    ///   - executionTime: the time interval needed for execution of the operation (optional)
    public static func fromResult(eventSource: Component,
                           result: AnyCodable,
                           executionTime: ReturnExecutionTime?) -> ReturnEvent<Family> {
        let returnEventData = ReturnEventData<Family>.createFrom(result: result,
                                                                 executionTime: executionTime,
                                                                 error: nil)
        return .init(eventSource: eventSource, eventData: returnEventData)
    }
    
    ///
    /// Create a ReturnEvent instance for a remote operation call that yields an error.
    ///
    /// The error code given is an integer that indicates the error type
    /// that occurred, either a predefined error or an application defined one. Predefined error
    /// codes are defined by the `RemoteCallErrorCode` enum. Predefined error
    /// codes are within the range -32768 to -32000. Application defined error codes must be
    /// defined outside this range.
    ///
    /// The error message provides a short description of the error. Predefined error messages
    /// exist for all predefined error codes (see enum `RemoteCallErrorMessage`).
    ///
    /// - Parameters:
    ///   - eventSource: the event source component.
    ///   - error: The error including the code that indicates the error type and the message string
    ///            providing a short description of the error.
    ///   - executionTime: the time interval needed for execution of the operation until
    ///                    the error occurred (optional).
    public static func fromError(eventSource: Component,
                          error: ReturnError,
                          executionTime: ReturnExecutionTime?) -> ReturnEvent<Family> {
        let returnEventData = ReturnEventData<Family>.createFrom(result: nil,
                                                                 executionTime: executionTime,
                                                                 error: error)
        return .init(eventSource: eventSource, eventData: returnEventData)
    }
    
    
    
    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
    
}

public class ReturnEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The result value to be returned (any JSON data type). The value is `nil`,
    /// if operation execution yielded an error.
    public var result: ReturnResult?

    /// The time interval needed for execution of the operation (optional).
    /// The value is `nil`, if the execution time has not been tracked.
    ///
    /// In case execution yields an error, the execution time (if provided)
    /// should represent the time period until the error occurred.
    public var executionTime: ReturnExecutionTime?
    
    
    /// The error object to be returned in case the operation call yielded an error (optional).
    /// The value is `nil` if the operation executed successfully.
    ///
    /// The error object consists of two properties: `code`, `message`.
    ///
    /// The error code given is an integer that indicates the error type
    /// that occurred, either a predefined error or an application defined one. Predefined error
    /// codes are defined by the `RemoteCallErrorCode` enum. Predefined error
    /// codes are within the range -32768 to -32000. Application defined error codes must be
    /// defined outside this range.
    ///
    /// The error message provides a short description of the error. Predefined error messages
    /// exist for all predefined error codes (see enum `RemoteCallErrorMessage`).
    public var error: ReturnError?
    
    // MARK: - Initializers.
    
    private init(result: ReturnResult?, executionTime: ReturnExecutionTime?, error: ReturnError?) {
        self.result = result
        self.executionTime = executionTime
        self.error = error
        super.init()
    }
    
    // MARK: - Factory methods.
    
    internal static func createFrom(result: ReturnResult?,
                                    executionTime: ReturnExecutionTime?,
                                    error: ReturnError?) -> ReturnEventData {
        
        return .init(result: result, executionTime: executionTime, error: error)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case error
        case result
        case executionTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.executionTime = try container.decodeIfPresent(ReturnExecutionTime.self, forKey: .executionTime)
        self.result = try container.decodeIfPresent(ReturnResult.self, forKey: .result)
        self.error = try container.decodeIfPresent(ReturnError.self, forKey: .error)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.executionTime, forKey: .executionTime)
        try container.encodeIfPresent(self.result, forKey: .result)
        try container.encodeIfPresent(self.error, forKey: .error)
    }
}

// MARK: - ReturnEvent internal classes.

public typealias ReturnResult = AnyCodable

public class ReturnExecutionTime: Codable {
    public var start: Double?
    public var end: Double?
    public var duration: Double?
    
    private init(start: Double? = nil, end: Double? = nil, duration: Double? = nil) {
        self.start = start
        self.end = end
        self.duration = duration
    }
    
    public init(start: Double, end: Double) {
        self.start = start
        self.end = end
    }
    
    public init(start: Double, duration: Double) {
        self.start = start
        self.duration = duration
    }
    
    public init(duration: Double, end: Double? = nil) {
        self.duration = duration
        self.end = end
        
    }
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
        case duration
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.start = try container.decodeIfPresent(Double.self, forKey: .start)
        self.end = try container.decodeIfPresent(Double.self, forKey: .end)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let start = start, let end = end {
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)
            return
        }
        
        if let start = start, let duration = duration {
            try container.encode(start, forKey: .start)
            try container.encode(duration, forKey: .duration)
            return
        }
        
        if let duration = duration, let end = end {
            try container.encode(duration, forKey: .duration)
            try container.encode(end, forKey: .end)
            return
        }
        
        if let duration = duration {
            try container.encode(duration, forKey: .duration)
            return
        }
    }
}

/// Defines error codes for pre-defined remote call errors.
///
/// The integer error codes from and including -32768 to -32000 are reserved for pre-defined errors
/// encountered while executing a remote call. Any code within this range, but not defined explicitly
/// below is reserved for future use. The remaining integers are available for application defined errors.
///
/// The predefined error messages corresponding to these predefined error codes are defined by enum
/// `RemoteCallErrorMessage`.
public enum RemoteCallErrorCode: Int {
    case invalidParameters = -32602
}

/// Defines error messages for pre-defined remote call errors.
///
/// The predefined error codes corresponding to these predefined error messages are defined by enum
/// `RemoteCallErrorCode`.
public enum RemoteCallErrorMessage: String {
    case invalidParameters = "Invalid params"
}


public class ReturnError: Codable {
    
    public var errorCode: Int
    public var errorMessage: String
    
    public init(errorCode: Int, errorMessage: String) {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
    
    public init(errorCode: RemoteCallErrorCode = .invalidParameters,
         errorMessage: RemoteCallErrorMessage = .invalidParameters) {
        self.errorCode = RemoteCallErrorCode.invalidParameters.rawValue
        self.errorMessage = RemoteCallErrorMessage.invalidParameters.rawValue
    }
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.errorCode = try container.decode(Int.self, forKey: .code)
        self.errorMessage = try container.decode( String.self, forKey: .message )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.errorCode, forKey: .code)
        try container.encodeIfPresent(self.errorMessage, forKey: .message)
    }
    
}
