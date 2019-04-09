//
//  CoatySwiftError.swift
//  CoatySwift
//
//

import Foundation

/// The base error for all CoatySwift related errors.
public enum CoatySwiftError: Error {
    case InvalidArgument(String)
    case DecodingFailure(String)
    case InvalidConfiguration(String)
}
