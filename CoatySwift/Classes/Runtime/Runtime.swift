// ! Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Runtime.swift
//  CoatySwift
//

import Foundation

/// Provides access to runtime data of a Coaty container, including
/// shared configuration options, as well as platform and framework meta
/// information.
public class Runtime {
    
    // TODO: These constants are injected while building the framework.
    // Auto-generated constants!
    private (set) public static var FRAMEWORK_PACKAGE_NAME = "coaty"
    private (set) public static var FRAMEWORK_PACKAGE_VERSION = "1.4.1"
    private (set) public static var FRAMEWORK_BUILD_DATE = 1554114439732
    
    /// Common options specified in container configuration.
    private (set) public var commonOptions: CommonOptions?
    
    /// Database options specified in container configuration.
    private (set) public var databaseOptions: DatabaseOptions?
    
    init(commonOptions: CommonOptions? = nil, databaseOptions: DatabaseOptions? = nil) {
        self.commonOptions = commonOptions
        self.databaseOptions = databaseOptions
    }

}

