//
//  AdvertiseEvent.swift
//  CoatySwift
//
//

/// AdvertiseEvent provides a generic implementation for all AdvertiseEvents.
/// Note that this class should preferably initialized via its withObject() method.
public class AdvertiseEvent<GenericAdvertise: CoatyObject>: CommunicationEvent<AdvertiseEventData<GenericAdvertise>> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: Component, eventData: AdvertiseEventData<GenericAdvertise>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }
    
    /// Convenience factory method that configures an instance of and AdvertiseEvent with
    /// an object and privateData. Note that the event source should be the controller that
    /// creates the AdvertiseEvent.
    /// FIXME: Replace CoatyObject with Component object.
    static func withObject(eventSource: Component,
                           object: GenericAdvertise,
                           privateData: [String: Any]? = nil) -> AdvertiseEvent {
        
        let advertiseEventData = AdvertiseEventData(object: object, privateData: privateData)
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


/// AdvertiseEventData provides a wrapper object that stores the entire message payload data
/// for an AdvertiseEvent including the object itself as well as the associated private data.
public class AdvertiseEventData<S: CoatyObject>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: S
    var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    init(object: S, privateData: [String: Any]? = nil) {
        self.object = object
        self.privateData = privateData
        // TODO: hasValidParameters() ?
        super.init()
    }
    
    static func createFrom(eventData: S) -> AdvertiseEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case privateData
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decode(S.self, forKey: .object)
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.object, forKey: .object)
        try container.encodeIfPresent(self.privateData, forKey: CodingKeys.privateData)
    }
}
