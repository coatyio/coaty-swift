//
//  Communication+Util.swift
//  CoatySwift
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
