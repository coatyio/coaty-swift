//
//  AdvertiseEvent.swift
//  CoatySwift
//
//

import Foundation

class AdvertiseEvent<GenericAdvertise: Advertise>: CommunicationEvent<AdvertiseEventData<GenericAdvertise>> {
    
    /// TODO: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    override init(eventSource: CoatyObject, eventData: AdvertiseEventData<GenericAdvertise>) throws {
        try super.init(eventSource: eventSource, eventData: eventData)
    }
    
    // FIXME: Replace CoatyObject with Component object.
    static func withObject(eventSource: CoatyObject,
                           object: GenericAdvertise,
                           privateData: [String: String]? = nil) throws -> AdvertiseEvent {
        
        let advertiseEventData = AdvertiseEventData(object: object, privateData: privateData)
        return try .init(eventSource: eventSource, eventData: advertiseEventData)
    }
    
    // MARK: - Codable methods.
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

class AdvertiseEventData<GenericAdvertise: Advertise>: CommunicationEventData {
    var object: GenericAdvertise
    var privateData: [String: String]? // FIXME: Default value.
    
    init(object: GenericAdvertise, privateData: [String: String]? = nil) {
        self.object = object
        self.privateData = privateData
        // TODO: hasValidParameters() ?
        super.init()
    }
    
    static func createFrom(eventData: GenericAdvertise) -> AdvertiseEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case privateData
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decode(GenericAdvertise.self, forKey: .object)
        self.privateData = try container.decodeIfPresent([String: String].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.object, forKey: .object)
        try container.encode(self.privateData, forKey: .privateData)
    }
}
