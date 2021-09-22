//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationEventType.swift
//  CoatySwift
//
//

/// Predefined event types used by Coaty communication event patterns.
internal enum CommunicationEventType: String {
    // Event types for Coaty one-way messages
    case Advertise = "ADV"
    case Deadvertise = "DAD"
    case Channel = "CHN"
    case Associate = "ASC"
    case IoValue = "IOV"

    // Event types for Coaty two-way messages
    case Discover = "DSC"
    case Resolve = "RSV"
    case Query = "QRY"
    case Retrieve = "RTV"
    case Update = "UPD"
    case Complete = "CPL"
    case Call = "CLL"
    case Return = "RTN"
    
    static func from(_ string: String) -> CommunicationEventType? {
        switch string {
        case "ADV":
            return CommunicationEventType.Advertise
        case "DAD":
            return CommunicationEventType.Deadvertise
        case "CHN":
            return CommunicationEventType.Channel
        case "ASC":
            return CommunicationEventType.Associate
        case "IOV":
            return CommunicationEventType.IoValue
        case "DSC":
            return CommunicationEventType.Discover
        case "RSV":
            return CommunicationEventType.Resolve
        case "QRY":
            return CommunicationEventType.Query
        case "RTV":
            return CommunicationEventType.Retrieve
        case "UPD":
            return CommunicationEventType.Update
        case "CPL":
            return CommunicationEventType.Complete
        case "CLL":
            return CommunicationEventType.Call
        case "RTN":
            return CommunicationEventType.Return
        default:
            return nil
        }
    }
    
    var isOneWay: Bool {
        return self == CommunicationEventType.Advertise ||
            self == CommunicationEventType.Deadvertise ||
            self == CommunicationEventType.Channel ||
            self == CommunicationEventType.Associate ||
            self == CommunicationEventType.IoValue
    }
}
