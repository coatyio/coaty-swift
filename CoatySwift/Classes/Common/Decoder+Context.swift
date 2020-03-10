//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  Decoder+Context.swift
//  CoatySwift
//
//

import Foundation

extension Decoder {
    
    /// Get context data stored on decoder's user info indexed by the given key.
    func getContext(forKey key: String) -> Any? {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        return userInfo[infoKey]
    }
    
    /// Push the given context data for recursive decoding.
    func pushContext(_ context: Any?, forKey key: String) {
        guard let contextStack = getContext(forKey: key) as? NSMutableArray else {
            return
        }
        contextStack.add(context ?? NSNull())
    }
    
    /// Pop the latest context data for recursive decoding.
    func popContext(forKey key: String) -> Void {
        guard let contextStack = getContext(forKey: key) as? NSMutableArray else {
            return
        }
        contextStack.removeLastObject()
    }
    
    /// Get the latest context data for recursive decoding.
    func currentContext(forKey key: String) -> Any? {
        guard let contextStack = getContext(forKey: key) as? NSMutableArray else {
            return nil
        }
        return contextStack.lastObject as Any?
    }
    
    /// Push the given context data for recursive decoding, execute the given action and pop the pushed context.
    func withContext<T>(_ context: Any?, forKey key: String, action: () throws -> T) rethrows -> T {
        pushContext(context, forKey: key)
        defer {
            popContext(forKey: key)
        }
        return try action()
    }
    
}

extension JSONDecoder {
    
    /// Set context data to be accessible on decoder's user info indexed by the given key.
    func setContext(_ context: Any?, forKey key: String) {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        userInfo[infoKey] = context
    }
    
    /// Set up context data for recursive decoding.
    func initPushContext(forKey key: String) {
        setContext([] as NSMutableArray, forKey: key)
    }
    
}
