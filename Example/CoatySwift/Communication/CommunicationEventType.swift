//
//  CommunicationEventType.swift
//  CoatySwift
//
//

/// CommunicationEventType provides the different cases to discover, distribute, and share data.
/// See coaty-js/src/com/communication-event.ts
enum CommunicationEventType: String {
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
