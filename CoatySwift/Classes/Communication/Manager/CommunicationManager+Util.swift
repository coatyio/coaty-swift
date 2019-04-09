//
//  Communication+Util.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {
    
    func convertToTupleFormat(rawMessage: (String, String)) throws -> (Topic, String) {
        let (topic, payload) = rawMessage
        return try (Topic(topic), payload)
    }
    
    func isAdvertise(rawMessage: (Topic, String)) -> Bool {
        let (topic, _) = rawMessage
        return topic.eventType == CommunicationEventType.Advertise
    }
    
    func isResolve(rawMessage: (Topic, String)) -> Bool {
        let (topic, _) = rawMessage
        return topic.eventType == CommunicationEventType.Resolve
    }
    
    func isUpdate(rawMessage: (Topic, String)) -> Bool {
        let (topic, _) = rawMessage
        return topic.eventType == CommunicationEventType.Update
    }
    
    func isComplete(rawMessage: (Topic, String)) -> Bool {
        let (topic, _) = rawMessage
        return topic.eventType == CommunicationEventType.Complete
    }
    
    func isChannel(rawMessageWithTopic: (Topic, String)) -> Bool {
        let (topic, _) = rawMessageWithTopic
        return topic.eventType == .Channel
    }
    
    func isDiscover(rawMessageWithTopic: (Topic, String)) -> Bool {
        let (topic, _) = rawMessageWithTopic
        return topic.eventType == .Discover
    }
    
    func isRetrieve(rawMessageWithTopic: (Topic, String)) -> Bool {
        let (topic, _) = rawMessageWithTopic
        return topic.eventType == .Retrieve
    }
    
    func isCall(rawMessageWithTopic: (Topic, String)) -> Bool {
        let (topic, _) = rawMessageWithTopic
        return topic.eventType == .Call
    }
    
    func isReturn(rawMessageWithTopic: (Topic, String)) -> Bool {
        let (topic, _) = rawMessageWithTopic
        return topic.eventType == .Return
    }
    
    /// Convenience method for creating an observable that has a simple cleanup method where
    /// it unsubscribes from the given MQTT topic.
    ///
    /// - Parameters:
    ///   - observable: the event observable.
    ///   - topic: the topic to unsubscribe from in the future.
    /// - Returns: a wrapped observable with a self cleanup method.
    func createSelfCleaningObservable<T>(observable: Observable<T>, topic: String) -> Observable<T> {
        return ObservableWrapper().createObservable(observable: observable, cleanup: {
            self.unsubscribe(topic: topic)
        })
    }

}

/// Observable Wrapper convenience class that manages the cleanup of an observable
/// by checking whether there are subscribers still subscribed to it and if none are,
/// performing a cleanup method.
class ObservableWrapper {

    /// Amount of subscribers currently subscribed to the wrapped observable.
    private var subscriberCount = 0

    /// Queue to synchronize `subscriberCount` access.
    private var queue = DispatchQueue(label: "com.siemens.coatyswift.observableWrapperQueue")
    
    /// Convenience creation of a wrapper observable for observing state changes in
    /// subscribers and unsubscribers.
    func createObservable<T>(observable: Observable<T>,
                                    cleanup: @escaping () -> ()) -> Observable<T> {
        
        
        return Observable.create { (observer) -> Disposable in
            let sub = observable.subscribe({ (event) in
                observer.on(event)
            })
            
            self.queue.sync {
                self.subscriberCount += 1
            }
            
            let disposable = Disposables.create {
                self.queue.sync {
                    self.subscriberCount -= 1
                    if self.subscriberCount == 0 {
                        sub.dispose()
                        cleanup()
                    }
                }
            }
            
            return disposable
        }
    }
}
