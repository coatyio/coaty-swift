//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  AdvertiseEvent.swift
//  CoatySwift
//
//

/// A Factory that creates AdvertiseEvents.
public class AdvertiseEventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    /// Convenience factory method that configures an instance of and AdvertiseEvent with
    /// an object and privateData. Note that the event source should be the controller that
    /// creates the AdvertiseEvent.
    /// - NOTE: It is required to delegate the call to `.withObject()` in order to create
    ///   AdvertiseEvents during the bootstrapping process.
    public func with(object: CoatyObject, privateData: [String: Any]? = nil) -> AdvertiseEvent<Family> {
        
        return AdvertiseEvent<Family>.withObject(eventSource: self.identity,
                                                 object: object, privateData: privateData)
    }
}

/// AdvertiseEvent provides a generic implementation for advertising CoatyObjects.
/// Note that this class should preferably be initialized via its withObject() method.
public class AdvertiseEvent<Family: ObjectFamily>: CommunicationEvent<AdvertiseEventData<Family>> {
    
    override init(eventSource: Identity, eventData: AdvertiseEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of an AdvertiseEvent with
    /// an object and privateData. Note that the event source should be the controller that
    /// creates the AdvertiseEvent.
    internal static func withObject(eventSource: Identity,
                           object: CoatyObject,
                           privateData: [String: Any]? = nil) -> AdvertiseEvent {
        
        let advertiseEventData = AdvertiseEventData<Family>(object: object, privateData: privateData)
        return .init(eventSource: eventSource, eventData: advertiseEventData)
    }
    
    // MARK: - Codable methods.
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// AdvertiseEventData provides the entire message payload data of an
/// `AdvertiseEvent` including the object itself as well as associated
/// private data.
public class AdvertiseEventData<Family: ObjectFamily>: CommunicationEventData {
    
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
        guard let object = try container.decode(ClassWrapper<Family, CoatyObject>.self, forKey: .object).object else {
            throw CoatySwiftError.DecodingFailure("No object found while decoding an Advertise Event.")
        }
        self.object = object
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.object, forKey: .object)
        try container.encodeIfPresent(self.privateData, forKey: CodingKeys.privateData)
    }
}
