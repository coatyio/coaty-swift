// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  QueryEvent.swift
//  CoatySwift
//

import Foundation


public class QueryEventFactory<Family: ObjectFamily> {
    
    /// Create a QueryEvent instance for querying the given object types, filter, and join conditions.
    /// The object filter and join conditions are optional.
    ///
    /// - Parameters:
    ///     - eventSource: the event source component
    ///     - objectTypes: restrict results by object types (logical OR).
    ///     - objectFilter: restrict results by object filter (optional).
    ///     - objectJoinConditions: join related objects into results (optional).
    public static func withObjectTypes(eventSource: Component,
                                       objectTypes: [String],
                                       objectFilter: ObjectFilter? = nil,
                                       objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(objectTypes: objectTypes,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }
    
    /// Create a QueryEvent instance for querying the given core types, filter, and join conditions.
    /// The object filter and join conditions are optional.
    ///
    /// - Parameters:
    ///     - eventSource: the event source component
    ///     - coreTypes: restrict results by core types (logical OR).
    ///     - objectFilter: restrict results by object filter (optional).
    ///     - objectJoinConditions: join related objects into results (optional).
    public static func withCoreTypes(eventSource: Component,
                                     coreTypes: [CoreType],
                                     objectFilter: ObjectFilter? = nil,
                                     objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEvent<Family> {
        
        let queryEventData = QueryEventData<Family>.createFrom(coreTypes: coreTypes,
                                                               objectFilter: objectFilter,
                                                               objectJoinConditions: objectJoinConditions)
        
        return .init(eventSource: eventSource, eventData: queryEventData)
    }

}

/// QueryEvent provides a generic implementation for all Query Events.
public class QueryEvent<Family: ObjectFamily>: CommunicationEvent<QueryEventData<Family>> {
    
    // MARK: - Internal attributes.
    
    /// Provides a complete handler for reacting to query events.
    internal var retrieveHandler: ((RetrieveEvent<Family>) -> Void)?
    
    /// Respond to an observed Query event by sending the given Retrieve event.
    ///
    /// - Parameter retrieveEvent: a Retrieve event.
    public func retrieve(retrieveEvent: RetrieveEvent<Family>) {
        if let retrieveHandler = retrieveHandler {
            retrieveHandler(retrieveEvent)
        }
    }
    
    // MARK: - Initializers.
    
    /// - NOTE: This method should never be called directly by application programmers.
    /// Inside the framework, calling is ok.
    fileprivate override init(eventSource: Component, eventData: QueryEventData<Family>) {
        super.init(eventSource: eventSource, eventData: eventData)
    }

    // MARK: - Codable methods.
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
    
    /// Throws an error if the given Retrieve event data does not correspond to
    /// the event data of this Query event.
    ///
    /// - Parameter eventData:  event data for Retrieve response event
    /// - Returns: boolean that indicates whether the object is valid
    internal func ensureValidResponseParameters(eventData: RetrieveEventData<Family>) -> Bool {
        for object in eventData.objects {
            if let coreTypes = self.data.coreTypes {
                let coreTypeValid = coreTypes.contains { type -> Bool in
                    type == object.coreType
                }
                
                if !coreTypeValid {
                    LogManager.log.warning("retrieved coreType not contained in Query coreTypes")
                    return false
                }
            }
            
            if let objectTypes = self.data.objectTypes {
                let objectTypeValid = objectTypes.contains { type -> Bool in
                    type == object.objectType
                }
                
                if !objectTypeValid {
                    LogManager.log.warning("retrieved objectType not contained in Query objectTypes")
                    return false
                }
            }
        }
        
        return true
    }
}


/// QueryEventData provides a wrapper object that stores the entire message payload data
/// for a QueryEvent.
public class QueryEventData<Family: ObjectFamily>: CommunicationEventData {
    
    // MARK: - Public attributes.
    
    /// Restrict objects by object types (logical OR).
    /// Should not be used in combination with coreTypes.
    public var objectTypes: [String]?
    
    /// Restrict objects by core types (logical OR).
    /// Should not be used in combination with objectTypes.
    public var coreTypes: [CoreType]?
    
    /// Restrict objects by an object filter.
    public var objectFilter: ObjectFilter?
    
    /// Join related objects by join conditions.
    /// - TODO: Only one of the two methods should be public.
    public var objectJoinConditions: [ObjectJoinCondition]?
    
    /// Join related objects by join conditions.
    /// - TODO: Only one of the two methods should be public.
    public var objectJoinCondition: ObjectJoinCondition?
    
    // MARK: - Initializers.
    
    /// Create a QueryEventData instance for the given type, filter, and join conditions.
    /// Exactly one of objectTypes or coreTypes parameters must be specified (use undefined
    /// for the other parameter). The object filter and join conditions are optional.
    ///
    /// - Parameters:
    ///     - objectTypes: Restrict results by object types (logical OR).
    ///     - coreTypes: Restrict results by core types (logical OR).
    ///     - objectFilter: Restrict results by object filter (optional).
    ///     - objectJoinConditions: Join related objects into results (optional).
    private init(objectTypes: [String]? = nil,
                 coreTypes: [CoreType]? = nil,
                 objectFilter: ObjectFilter? = nil,
                 objectJoinConditions: [ObjectJoinCondition]? = nil,
                 objectJoinCondition: ObjectJoinCondition? = nil) {
        
        self.objectTypes = objectTypes
        self.coreTypes = coreTypes
        self.objectFilter = objectFilter
        self.objectJoinConditions = objectJoinConditions
        self.objectJoinCondition = objectJoinCondition
        super.init()
    }
    
    // MARK: - Factory methods.
    
    /// TODO: Comment.
    public static func createFrom(objectTypes: [String],
                           objectFilter: ObjectFilter? = nil,
                           objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEventData {
        // TODO: Double check this.
        if objectJoinConditions?.count == 1 {
            return .init(objectTypes: objectTypes,
                         coreTypes: nil,
                         objectFilter: objectFilter,
                         objectJoinConditions: nil,
                         objectJoinCondition: objectJoinConditions![0])
        } else {
            return .init(objectTypes: objectTypes,
                         coreTypes: nil,
                         objectFilter: objectFilter,
                         objectJoinConditions: objectJoinConditions,
                         objectJoinCondition: nil)
            }
    }
    
    /// TODO: Comment.
    public static func createFrom(coreTypes: [CoreType],
                                  objectFilter: ObjectFilter? = nil,
                                  objectJoinConditions: [ObjectJoinCondition]? = nil) -> QueryEventData {
        // TODO: Double check this.
        if objectJoinConditions?.count == 1 {
            return .init(objectTypes: nil,
                         coreTypes: coreTypes,
                         objectFilter: objectFilter,
                         objectJoinConditions: nil,
                         objectJoinCondition: objectJoinConditions![0])
        } else {
            return .init(objectTypes: nil,
                         coreTypes: coreTypes,
                         objectFilter: objectFilter,
                         objectJoinConditions: objectJoinConditions,
                         objectJoinCondition: nil)
        }
    }
    
    
    // MARK: - Codable methods.
    
    enum CodingKeys: String, CodingKey {
        case objectTypes
        case coreTypes
        case objectFilter
        case objectJoinConditions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objectTypes = try container.decodeIfPresent([String].self, forKey: .objectTypes)
        self.coreTypes = try container.decodeIfPresent([CoreType].self, forKey: .coreTypes)
        self.objectFilter = try container.decodeIfPresent(ObjectFilter.self, forKey: .objectFilter)
        
        do {
            self.objectJoinConditions = try container.decodeIfPresent([ObjectJoinCondition].self,
                                                                  forKey: .objectJoinConditions)
        } catch { /* Surpress error. */ }
        
        do {
            self.objectJoinCondition = try container.decodeIfPresent(ObjectJoinCondition.self,
                                                                 forKey: .objectJoinConditions)
        } catch { /* Surpress error. */ }

        
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.objectTypes, forKey: .objectTypes)
        try container.encodeIfPresent(self.coreTypes, forKey: .coreTypes)
        try container.encodeIfPresent(self.objectFilter, forKey: .objectFilter)
        
        // There is only one of them set.
        try container.encodeIfPresent(self.objectJoinConditions, forKey: .objectJoinConditions)
        try container.encodeIfPresent(self.objectJoinCondition, forKey: .objectJoinConditions)
    }
    
}
