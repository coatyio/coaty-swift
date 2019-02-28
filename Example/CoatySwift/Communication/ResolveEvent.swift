//
//  ResolveEvent.swift
//  CoatySwift
//

import Foundation

// TODO: COMMENT ME I'M BEGGING YOU
/// AdvertiseEventData provides a wrapper object that stores the entire message payload data
/// for an AdvertiseEvent including the object itself as well as the associated private data.
class ResolveEventData<S: Resolve>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    var object: S?
    var relatedObjects: [S]?
    var privateData: [String: Any]?
    
    // MARK: - Initializers.
    
    private init(_ object: S?, _ relatedObjects: [S]?, _ privateData: [String: Any]? = nil) {
        self.object = object
        self.relatedObjects = relatedObjects
        self.privateData = privateData
        // TODO: hasValidParameters() ?
        super.init()
    }
    
    convenience init(object: S, privateData: [String: Any]? = nil) {
        self.init(object, nil, privateData)
    }
    
    convenience init(relatedObjects: [S], privateData: [String: Any]? = nil) {
        self.init(nil, relatedObjects, privateData)
    }
    
    convenience init(object: S, relatedObjects: [S], privateData: [String: Any]? = nil) {
        self.init(object, relatedObjects, privateData)
    }
    
    static func createFrom(eventData: S) -> ResolveEventData {
        return .init(object: eventData)
    }
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case object
        case relatedObjects
        case privateData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decodeIfPresent(S.self, forKey: .object)
        self.relatedObjects = try container.decodeIfPresent([S].self, forKey: .relatedObjects)
        try? self.privateData = container.decodeIfPresent([String: Any].self, forKey: .privateData)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.object, forKey: .object)
        try container.encodeIfPresent(self.relatedObjects, forKey: .relatedObjects)
        try container.encodeIfPresent(self.privateData, forKey: .privateData)
    }
}
