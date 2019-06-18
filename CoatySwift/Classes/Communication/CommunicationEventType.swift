// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationEventType.swift
//  CoatySwift
//
//

/// CommunicationEventType provides the different cases to discover, distribute, and share data.
/// See coaty-js/src/com/communication-event.ts
public enum CommunicationEventType: String {
    case Raw = "Raw"
    case Advertise = "Advertise"
    case Deadvertise = "Deadvertise"
    case Channel = "Channel"
    case Discover = "Discover"
    case Resolve = "Resolve"
    case Query = "Query"
    case Retrieve = "Retrieve"
    case Update = "Update"
    case Complete = "Complete"
    case Associate = "Associate"
    case IoValue = "IoValue"
    case Call = "Call"
    case Return = "Return"
}
