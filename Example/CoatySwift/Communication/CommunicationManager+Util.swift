//
//  Communication+Util.swift
//  CoatySwift_Example
//
//  Created by Sandra Grujovic on 27.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension CommunicationManager {
    
    func convertToTupleFormat(rawMessage: (String, String)) throws -> (Topic, String) {
        let (topic, payload) = rawMessage
        return try (Topic(topic), payload)
    }
    
    func isAdvertise(rawMesssage: (Topic, String)) -> Bool {
        let (topic, _) = rawMesssage
        
        // FIXME: Implement getter for communicationEventType on Topic.swift.
        // FIXME: Use CommunicationEventTypes.
        return topic.event.contains("Advertise")
    }
}
