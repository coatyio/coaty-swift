//
//  ObjectJoinCondition.swift
//  CoatySwift
//

import Foundation

public class ObjectJoinCondition: Codable {
    var localProperty: String
    var isLocalPropertyArray: Bool?
    var asProperty: String
    var isOneToOneRelation: Bool?
    
    public init(localProperty: String, asProperty: String,
                isLocalPropertyArray: Bool? = nil, isOneToOneRelation: Bool? = nil) {
        self.localProperty = localProperty
        self.asProperty = asProperty
        self.isLocalPropertyArray = isLocalPropertyArray
        self.isOneToOneRelation = isOneToOneRelation
    }
}
