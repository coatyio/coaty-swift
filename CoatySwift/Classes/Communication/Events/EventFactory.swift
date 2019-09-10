// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  EventFactory.swift
//  CoatySwift
//

import Foundation

public class EventFactoryInit {
    var identity: Component
    
    init(_ identity: Component) {
        self.identity = identity
    }
}

public class EventFactory<Family: ObjectFamily>: EventFactoryInit {
    
    public var AdvertiseEvent:      AdvertiseEventFactory<Family>
    public var DeadvertiseEvent:    DeadvertiseEventFactory<Family>
    public var ChannelEvent:        ChannelEventFactory<Family>
    public var DiscoverEvent:       DiscoverEventFactory<Family>
    public var ResolveEvent:        ResolveEventFactory<Family>
    public var UpdateEvent:         UpdateEventFactory<Family>
    public var CompleteEvent:       CompleteEventFactory<Family>
    public var QueryEvent:          QueryEventFactory<Family>
    public var RetrieveEvent:       RetrieveEventFactory<Family>
    public var CallEvent:           CallEventFactory<Family>
    public var ReturnEvent:         ReturnEventFactory<Family>

    override init(_ identity: Component) {
        self.AdvertiseEvent = AdvertiseEventFactory(identity)
        self.DeadvertiseEvent = DeadvertiseEventFactory(identity)
        self.ChannelEvent = ChannelEventFactory(identity)
        self.DiscoverEvent = DiscoverEventFactory(identity)
        self.ResolveEvent = ResolveEventFactory(identity)
        self.UpdateEvent = UpdateEventFactory(identity)
        self.CompleteEvent = CompleteEventFactory(identity)
        self.QueryEvent = QueryEventFactory(identity)
        self.RetrieveEvent = RetrieveEventFactory(identity)
        self.CallEvent = CallEventFactory(identity)
        self.ReturnEvent = ReturnEventFactory(identity)
        super.init(identity)
    }
}


