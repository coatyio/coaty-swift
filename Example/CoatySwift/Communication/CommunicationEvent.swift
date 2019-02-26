//
//  CommunicationEvent.swift
//  CoatySwift_Example
//
//  Created by Sandra Grujovic on 25.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

enum CommunicationEventType {
    case Raw
    case Advertise
    case Deadvertise
    case Channel
    case Discover
    case Resolve
    case Query
    case Retrieve
    case Update
    case Complete
    case Associate
    case IoValue
}

class CommunicationEventData: Codable {
    
}

/* class CommunicationEvent<T:CommunicationEventData> {
    
    // MARK: - Public attributes.
    var eventType: CommunicationEventType
    
    // MARK: - Private attributes.
    
    // private var eventSource: CoatyObject.Type
    private var eventSourceId: UUID
    private var eventData: T
    private var eventUserId: String // or UUID?
    
    // MARK: - Initializer.
    
    init() {
        
    }
    
}*/ 

