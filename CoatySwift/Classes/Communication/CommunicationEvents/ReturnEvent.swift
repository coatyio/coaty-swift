//
//  ReturnEvent.swift
//  CoatySwift
//

import Foundation

/// A Factory that creates ReturnEvents.
public class ReturnEventFactory<Family: ObjectFamily> {
    
    /// Create a ReturnEvent instance for a remote operation call that successfully yields a result.
    ///
    /// - Parameters:
    ///   - eventSource: the event source component
    ///   - result: the result value to be returned (any JSON data type)
    ///   - executionTime: the time interval needed for execution of the operation (optional)
    public static func withResult(eventSource: Component,
                                  result: AnyCodable,
                                  executionInfo: ExecutionInfo?) -> ReturnEvent<Family> {
        let returnEventData = ReturnEventData<Family>.createFrom(result: result,
                                                                 executionInfo: executionInfo,
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
    public static func withError(eventSource: Component,
                                 error: ReturnError,
                                 executionInfo: ExecutionInfo?) -> ReturnEvent<Family> {
        let returnEventData = ReturnEventData<Family>.createFrom(result: nil,
                                                                 executionInfo: executionInfo,
                                                                 error: error)
        return .init(eventSource: eventSource, eventData: returnEventData)
    }
    
}

public class ReturnEvent<Family: ObjectFamily>: CommunicationEvent<ReturnEventData<Family>> {
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    fileprivate override init(eventSource: Component, eventData: ReturnEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
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

    /// Defines additional information about the execution environment (any JSON value)
    /// such as the execution time of the operation or the ID of the operated control unit (optional).
    public var executionInfo: ExecutionInfo?
    
    
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
    
    private init(result: ReturnResult?, executionInfo: ExecutionInfo?, error: ReturnError?) {
        self.result = result
        self.executionInfo = executionInfo
        self.error = error
        super.init()
    }
    
    // MARK: - Factory methods.
    
    internal static func createFrom(result: ReturnResult?,
                                    executionInfo: ExecutionInfo?,
                                    error: ReturnError?) -> ReturnEventData {
        
        return .init(result: result, executionInfo: executionInfo, error: error)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case error
        case result
        case executionInfo
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.executionInfo = try container.decodeIfPresent(ExecutionInfo.self, forKey: .executionInfo)
        self.result = try container.decodeIfPresent(ReturnResult.self, forKey: .result)
        self.error = try container.decodeIfPresent(ReturnError.self, forKey: .error)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.executionInfo, forKey: .executionInfo)
        try container.encodeIfPresent(self.result, forKey: .result)
        try container.encodeIfPresent(self.error, forKey: .error)
    }
}

// MARK: - ReturnEvent internal classes.

public typealias ReturnResult = AnyCodable
public typealias ExecutionInfo = AnyCodable

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
    
    public var code: Int
    public var message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    public init(code: RemoteCallErrorCode = .invalidParameters,
         message: RemoteCallErrorMessage = .invalidParameters) {
        self.code = RemoteCallErrorCode.invalidParameters.rawValue
        self.message = RemoteCallErrorMessage.invalidParameters.rawValue
    }
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(Int.self, forKey: .code)
        self.message = try container.decode( String.self, forKey: .message )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.code, forKey: .code)
        try container.encodeIfPresent(self.message, forKey: .message)
    }
    
}
