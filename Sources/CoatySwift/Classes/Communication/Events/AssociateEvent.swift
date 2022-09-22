//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  AsssociateEvent.swift
//  CoatySwift
//
//

import Foundation

/// Associate event
public class AssociateEvent: CommunicationEvent<AssociateEventData> {
    
    // MARK: - Internal attributes.
    
    /// The name of the IO context.
    var ioContextName: String?
    
    // MARK: - Static Factory Methods.
    
    /// Create an AssociateEvent instance for associating or disassociating the
    /// given IO source and IO actor.
    ///
    /// - Parameters:
    ///     - ioContextName: the name of an IO context the given IO source and
    ///     actor belong to
    ///     - ioSourceId: the IO source object Id to associate/disassociate
    ///     - ioActorId: the IO actor object Id to associate/disassociate
    ///     - associatingRoute: the IO route used by IO source for publishing and
    ///     by IO actor for subscribing, or undefined if used for disassocation
    ///     - isExternalRoute: indicates whether the associating route is
    ///     external (optional)
    ///     - updateRate: the recommended update rate (in millis) for publishing
    ///     IO source values (optional)
    public static func with(ioContextName: String,
                            ioSourceId: CoatyUUID,
                            ioActorId: CoatyUUID,
                            associatingRoute: String?,
                            isExternalRoute: Bool? = nil,
                            updateRate: Int? = nil) -> AssociateEvent {
        let associateEventData = AssociateEventData(ioSourceId: ioSourceId,
                                                    ioActorId: ioActorId,
                                                    associatingRoute: associatingRoute,
                                                    isExternalRoute: isExternalRoute,
                                                    updateRate: updateRate)
        return .init(eventType: .Associate,
                     eventData: associateEventData,
                     ioContextName: ioContextName)
    }
    
    // MARK: - Initializers.
    
    fileprivate override init(eventType: CommunicationEventType, eventData: AssociateEventData) {
        super.init(eventType: eventType, eventData: eventData)
    }
    
    /// Create an AssociateEvent instance for associating or disassociating the
    /// IO source and IO actor given in event data.
    ///
    /// The context name must be a non-empty string that does not contain the
    /// following characters: `NULL (U+0000)`, `# (U+0023)`, `+ (U+002B)`, `/
    /// (U+002F)`.
    ///
    /// - Parameters:
    ///     - eventType: type of the event
    ///     - eventData: data associated with this Associate event
    ///     - ioContextName: the name of the IO context
    fileprivate init(eventType: CommunicationEventType,
                     eventData: AssociateEventData,
                     ioContextName: String) {
        
        super.init(eventType: eventType, eventData: eventData)
        self.ioContextName = ioContextName
    }
    
    // MARK: - Codable methods.
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}


/// Defines event data format to associate or disassociate an IO source with an IO actor.
public class AssociateEventData: CommunicationEventData {
    
    // MARK: - Attributes.
    
    /// The object Id of the IO source object to associate/disassociate.
    public var ioSourceId: CoatyUUID
    
    /// The object Id of the IO actor object to associate/disassociate
    public var ioActorId: CoatyUUID
    
    /// The IO route used by IO source for publishing and
    /// by IO actor for subscribing, or nil if used for disassocation
    public var associatingRoute: String?
    
    /// Indicates whether the associating route is external (optional)
    public var isExternalRoute: Bool?
    
    /// The recommended update rate (in millis) for publishing IO source values (optional)
    public var updateRate: Int?
    
    // MARK: - Initializers.
    
    /// Create a new AssociateEventData instance.
    ///
    /// - Parameters:
    ///     - ioSourceId: the object Id of the IO source object to
    ///     associate/disassociate
    ///     - ioActorId: the object Id of the IO actor object to
    ///     associate/disassociate
    ///     - associatingRoute: the IO route used by IO source for publishing and
    ///     by IO actor for subscribing, or nil if used for disassocation
    ///     - isExternalRoute: indicates whether the associating route is
    ///     external (optional)
    ///     - updateRate: The recommended update rate (in millis) for publishing
    ///     IO source values (optional)
    init(ioSourceId: CoatyUUID,
         ioActorId: CoatyUUID,
         associatingRoute: String?,
         isExternalRoute: Bool?,
         updateRate: Int?) {
        self.ioSourceId = ioSourceId
        self.ioActorId = ioActorId
        self.associatingRoute = associatingRoute
        self.isExternalRoute = isExternalRoute
        self.updateRate = updateRate
        super.init()
    }
    
    // MARK: - Codable methods.
    
    enum AssociateKeys: String, CodingKey {
        case ioSourceId
        case ioActorId
        case associatingRoute
        case isExternalRoute
        case updateRate
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssociateKeys.self)
        
        // Decode attributes.
        ioSourceId = try container.decode(CoatyUUID.self, forKey: .ioSourceId)
        ioActorId = try container.decode(CoatyUUID.self, forKey: .ioActorId)
        associatingRoute = try container.decodeIfPresent(String.self, forKey: .associatingRoute)
        isExternalRoute = try container.decodeIfPresent(Bool.self, forKey: .isExternalRoute)
        updateRate = try container.decodeIfPresent(Int.self, forKey: .updateRate)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: AssociateKeys.self)
        
        // Encode attributes.
        try container.encodeIfPresent(ioSourceId, forKey: .ioSourceId)
        try container.encodeIfPresent(ioActorId, forKey: .ioActorId)
        try container.encodeIfPresent(associatingRoute, forKey: .associatingRoute)
        try container.encodeIfPresent(isExternalRoute, forKey: .isExternalRoute)
        try container.encodeIfPresent(updateRate, forKey: .updateRate)
    }
}
