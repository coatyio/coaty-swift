//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  AdvertiseEvent.swift
//  CoatySwift
//
//

/// AdvertiseEvent provides a generic implementation for advertising
/// CoatyObjects.
public class AdvertiseEvent: CommunicationEvent<AdvertiseEventData> {

    // MARK: - Static Factory Methods.

    /// Create an AdvertiseEvent with an object and optional privateData.
    ///
    /// The object type of the given object must be a non-empty string that does not contain
    /// the following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`,
    /// `/ (U+002F)`.
    ///
    /// - Parameters:
    ///     - object: The object to be advertised
    ///     - privateData: Associated private data to be published (optional).
    /// - Returns: an Advertise event with the given parameters
    /// - Throws: if object type of given object is invalid
    public static func with(object: CoatyObject,
                            privateData: [String: Any]? = nil) throws -> AdvertiseEvent {
        let advertiseEventData = AdvertiseEventData(object: object, privateData: privateData)
        return try .init(eventType: .Advertise, eventData: advertiseEventData, objectType: advertiseEventData.object.objectType)
    }

    // MARK: - Initializers.

    fileprivate override init(eventType: CommunicationEventType, eventData: AdvertiseEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    fileprivate init(eventType: CommunicationEventType, eventData: AdvertiseEventData, objectType: String) throws {
        guard CommunicationTopic.isValidEventTypeFilter(filter: objectType) else {
            throw CoatySwiftError.InvalidArgument("Invalid object type: \(objectType)")
        }
        
        super.init(eventType: eventType, eventData: eventData)
    }
    
    // MARK: - Codable methods.
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// Defines event data format for advertising objects.
public class AdvertiseEventData: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// The object to be advertised.
    public var object: CoatyObject

    /// Associated private data to be published (optional).
    public var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    init(object: CoatyObject, privateData: [String: Any]? = nil) {
        self.object = object
        self.privateData = privateData
        super.init()
    }
    
    static func createFrom(eventData: CoatyObject) -> AdvertiseEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decode(AnyCoatyObjectDecodable.self, forKey: .object).object
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.object, forKey: .object)
        try container.encodeIfPresent(self.privateData, forKey: CodingKeys.privateData)
    }
}
