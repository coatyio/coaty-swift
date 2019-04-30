//
//  RxOptional.swift
//  CoatySwift
//
//

import Foundation
import RxSwift

/// This implementation is taken from [here](https://github.com/RxSwiftCommunity/RxOptional/blob/1c37ab2d84823babc0d09ebe0b70ade3bee25829/Source/Observable%2BOptional.swift), and was released under the MIT License by the RxSwiftCommunity on github.

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    /// Cast `Optional<Wrapped>` to `Wrapped?`
    public var value: Wrapped? {
        return self
    }
}

public extension ObservableType where E: OptionalType {
    /**
     Unwraps and filters out `nil` elements.
     - returns: `Observable` of source `Observable`'s elements, with `nil` elements filtered out.
     */
    
    func filterNil() -> Observable<E.Wrapped> {
        return self.flatMap { element -> Observable<E.Wrapped> in
            guard let value = element.value else {
                return Observable<E.Wrapped>.empty()
            }
            return Observable<E.Wrapped>.just(value)
        }
    }

}
