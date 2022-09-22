//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CM+Util.swift
//  CoatySwift
//

import Foundation
import RxSwift

extension CommunicationManager {

    // MARK: - Utility methods.
    
    /// Gets an observer for communication state changes.
    public func getCommunicationState() -> Observable<CommunicationState> {
        return communicationState.asObserver()
    }
    
    /// Gets an observer for operating state changes.
    public func getOperatingState() -> Observable<OperatingState> {
        return operatingState.asObserver()
    }
    
    // MARK: - Dispatching Messages.
    
    func messagesFor(_ eventType: CommunicationEventType, _ eventTypeFilter: String? = nil) -> Observable<(CommunicationTopic, String)> {
        return client!.messages
            .filter { (topic, _) in
                topic.eventType == eventType &&
                topic.eventTypeFilter == eventTypeFilter }
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

    private var hasLastObserverUnsubscribed = false

    /// Queue to synchronize `subscriberCount` access.
    private var queue = DispatchQueue(label: "com.coatyswift.observableWrapperQueue")
    
    /// Convenience creation of a wrapper observable for observing state changes in
    /// subscribers and unsubscribers.
    func createObservable<T>(observable: Observable<T>,
                             cleanup: @escaping () -> ()) -> Observable<T> {
        return Observable.create { (observer) -> Disposable in
            let sub = observable.subscribe({ (event) in
                if self.hasLastObserverUnsubscribed {
                    // After all initial subscribers have unsubscribed resubscription is no longer possible.
                    observer.onError(CoatySwiftError.InvalidArgument("Resubscribing to an observed event is not supported"))
                } else {
                    observer.on(event)
                }
            })
            
            self.queue.sync {
                self.subscriberCount += 1
            }
            
            let disposable = Disposables.create {
                self.queue.sync {
                    sub.dispose()
                    self.subscriberCount -= 1
                    if self.subscriberCount == 0 {
                        self.hasLastObserverUnsubscribed = true
                        cleanup()
                    }
                }
            }
            
            return disposable
        }
    }
}
