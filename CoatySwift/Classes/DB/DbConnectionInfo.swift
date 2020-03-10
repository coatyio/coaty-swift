//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  DbConnectionInfo.swift
//  CoatySwift
//

import Foundation

/// Describes information used to connect to a specific database server using
/// a specific database adapter.
public class DbConnectionInfo {
    
    // MARK: - Attributes.
    
    /// The name of the adapter used to interact with a specific database server.
    ///
    /// The name of the adapter specified here must be associated with the
    /// constructor function of a built-in adapter type or a custom
    /// adapter type by using the `DbAdapterFactory.registerAdapter` method
    /// or by specifying the adapter type as optional argument when
    /// creating a new `DbContext` or `DbLocalContext`.
    public var adapter: String
    
    /// Adapter-specific configuration options (optional).
    public var adapterOptions: [String: Any]?
    
    /// An adapter-specific connection string or Url containing connection
    /// details (optional).
    /// Use alternatively to or in combination with `connectionOptions`.
    public var connectionString: String?
    
    /// Adapter-specific connection options (optional).
    /// Use alternatively to or in combination with `connectionString`.
    public var connectionOptions: Any?
    
    // MARK: - Initializers.
    
    /// Default initializer for a `DbConnectionInfo` object.
    public init(adapter: String, adapterOptions: [String: Any]? = nil,
         connectionString: String? = nil, connectionOptions: Any? = nil) {
        self.adapter = adapter
        self.adapterOptions = adapterOptions
        self.connectionString = connectionString
        self.connectionOptions = connectionOptions
    }
}
