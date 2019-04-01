//
//  ReturnEvent.swift
//  CoatySwift
//

import Foundation

public class ReturnEvent<Family: ObjectFamily>: CommunicationEvent<ReturnEventData<Family>> {
}

public class ReturnEventData<Family: ObjectFamily>: CommunicationEventData {
}
