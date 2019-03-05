import Quick
import Nimble
@testable import CoatySwift

class CommunicationTests: QuickSpec {
    
    override func spec() {
        describe("Communication") {
            
            describe("Communication Topic") {
                
                let identity = Component(name: "CommunicationManager")
                let messageToken = "7d6dd7e6-4f3d-4cdf-92f5-3d926a55663d"
                    
                    // let topicNoUser = Topic.createTopicStringByLevelsForPublish(eventType: .Advertise, eventTypeFilter: "CoatyObject", associatedUserId: nil, sourceObject: identity, messageToken: "7d6dd7e6-4f3d-4cdf-92f5-3d926a55663d")
                it("creates correct topic string for subscriptions") {
                    let subscriptionTopic = "/coaty/+/Advertise:Component/+/+/+/"
                    
                    expect {
                        try Topic.createTopicStringByLevelsForSubscribe(eventType: .Advertise,
                                                                        eventTypeFilter: "Component",
                                                                        associatedUserId: nil,
                                                                        sourceObject: nil,
                                                                        messageToken: nil)
                    }.to(equal(subscriptionTopic))
                }
                
                it("creates correct topic string for publications") {
                    let publicationTopic = "/coaty/\(PROTOCOL_VERSION)/Advertise:Component/-/\(identity.objectId)/\(messageToken)/"

                    expect {
                        try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise,
                                                                      eventTypeFilter: "Component",
                                                                      associatedUserId: "-",
                                                                      sourceObject: identity,
                                                                      messageToken: messageToken)
                    }.to(equal(publicationTopic))
                }
                
                it("throws on wrong protocol version") {
                    expect {
                        try Topic.init(protocolVersion: 0,
                                       event: CommunicationEventType.Advertise.rawValue,
                                       associatedUserId: "-",
                                       sourceObjectId: identity.objectId.uuidString,
                                       messageToken: messageToken)
                    }.to(throwError())
                }
                
                /*it("throws on missing eventTypeFilter for event that needs it") {
                    expect {
                        try Topic.createTopicStringByLevelsForPublish(eventType: .Advertise, eventTypeFilter: nil, associatedUserId: "-", sourceObject: identity, messageToken: messageToken)
                        }.to(throwError())
                }*/
                
                it("throws on invalid topic structure format") {
                    expect {
                        try Topic.init("/coaty/\(PROTOCOL_VERSION)/Advertise:Component/-/\(identity.objectId)/\(messageToken)/additionalLevel/")
                    }.to(throwError())
                    
                    expect {
                        try Topic.init("/coaty/\(PROTOCOL_VERSION)/Unknown:Component/-/\(identity.objectId)/\(messageToken)/")
                    }.to(throwError())
                    
                    expect {
                        try Topic.init("/coaty/\(PROTOCOL_VERSION)/Advertise:UnknownCoreType/-/\(identity.objectId)/\(messageToken)/")
                    }.to(throwError())
                    
                    /* expect {
                        try Topic.init("/coaty/\(PROTOCOL_VERSION)/Advertise::Malformatted#ObjectType/-/\(identity.objectId)/\(messageToken)/")
                    }.to(throwError())
                */
                }
            }
           
        }
    }
}
