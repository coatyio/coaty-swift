// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  EventFactory.swift
//  CoatySwift
//

import Foundation

public class AnyEventFactory {
    
}

public class EventFactory<Family: ObjectFamily>: AnyEventFactory {
    public var AdvertiseEvent = AdvertiseEventFactory<Family>.self
    public var DeadvertiseEvent = DeadvertiseEventFactory<Family>.self
    public var ChannelEvent = ChannelEventFactory<Family>.self
    public var DiscoverEvent = DisoverEventFactory<Family>.self
    public var ResolveEvent = ResolveEventFactory<Family>.self
    public var UpdateEvent = UpdateEventFactory<Family>.self
    public var CompleteEvent = CompleteEventFactory<Family>.self
    public var QueryEvent = QueryEventFactory<Family>.self
    public var RetrieveEvent = RetrieveEventFactory<Family>.self
    public var CallEvent = CallEventFactory<Family>.self
    public var ReturnEvent = ReturnEventFactory<Family>.self
}


