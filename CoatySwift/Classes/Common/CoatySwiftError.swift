//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CoatySwiftError.swift
//  CoatySwift
//
//

import Foundation

/// The base error type for all CoatySwift related errors.
public enum CoatySwiftError: Error {
    
    /// Invalid argument error.
    case InvalidArgument(String)
    
    /// Decoding of a Coaty object or event failed.
    case DecodingFailure(String)
    
    /// Invalid configuration option.
    case InvalidConfiguration(String)
    
    /// An error that occured during runtime.
    case RuntimeError(String)
}
