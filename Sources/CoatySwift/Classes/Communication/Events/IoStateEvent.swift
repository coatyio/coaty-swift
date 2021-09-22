//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  IoStateEvent.swift
//  CoatySwift
//
//

import Foundation


/// IoState event.
///
/// This event is internally emitted by the observable returned by
/// `CommunicationManager.observeIoState`.
///
/// - Warning: IoStateEvent is not a MQTT event. For internal use in framework only.
public class IoStateEvent {
    
    // MARK: - Attributes.
    
    internal var eventData: IoStateEventData
    
    // MARK: - Initializers.
    
    internal init(eventData: IoStateEventData) {
        self.eventData = eventData
    }
    
    // MARK: - Static functions.
    
    /// Create an IoStateEvent instance for describing an IO state.
    ///
    /// - Warning: For internal use in framework only.
    ///
    /// - Parameter hasAssociations: determines whether the related IO source/actor has
    /// associations
    /// - Parameter updateRate: the recommended update rate (in millis) for publishing
    /// IO source values (optional)
    internal static func with(hasAssociations: Bool, updateRate: Int? = nil) -> IoStateEvent {
        return IoStateEvent(eventData: IoStateEventData(hasAssociations: hasAssociations,
                                                        updateRate: updateRate))
    }
}

/// Defines event data format for association/disassociation related to a
/// specific IO source/actor.
///
/// This data is emitted by the observable returned by
/// `CommunicationManager.observeIoState`.
public class IoStateEventData: CommunicationEventData {
    
    // MARK: - Attributes.
    
    private var _hasAssociations: Bool
    
    private var _updateRate: Int? = nil
    
    // MARK: - Initializers.
    
    /// Create a new IoStateEventData instance.
    ///
    /// - Warning: For internal use in framework only.
    ///
    /// - Parameters:
    ///     - hasAssociations: determines whether the related IO source/actor has
    ///     associations
    ///     - updateRate: The recommended update rate (in millis) for publishing
    ///     IO source values (optional)
    init(hasAssociations: Bool, updateRate: Int?) {
        self._hasAssociations = hasAssociations
        self._updateRate = updateRate
        
        super.init()
    }
    
    // MARK: - Getters.
    
    /// Determines whether the related IO source/actor has associations.
    public func hasAssociations() -> Bool {
        return self._hasAssociations
    }
    
    /// The recommended update rate (in millis) for publishing IO source values
    /// (optional).
    ///
    /// The value is only specified for association events that are observed by
    /// an IO source; otherwise undefined.
    public func updateRate() -> Int? {
        return self._updateRate
    }
    
    // MARK: - Codable methods.
    
    enum IoStateKeys: String, CodingKey {
        case hasAssociatons
        case updateRate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IoStateKeys.self)
        
        // Decode attributes.
        _hasAssociations = try container.decode(Bool.self, forKey: .hasAssociatons)
        _updateRate = try container.decode(Int?.self, forKey: .updateRate)
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: IoStateKeys.self)
        
        // Encode attributes.
        try container.encode(_hasAssociations, forKey: .hasAssociatons)
        try container.encodeIfPresent(_updateRate, forKey: .updateRate)
    }
    
}
