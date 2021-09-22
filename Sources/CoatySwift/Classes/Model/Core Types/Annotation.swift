//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  Annotation.swift
//  CoatySwift
//
//

import Foundation

/// Represents an annotation
open class Annotation: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.Annotation.objectType, with: self)
    }
    
    // MARK: Attributes.
    
    /// Specific type of this annotation object
    public var type: AnnotationType

    /// UUID of User who created the annotation
    public var creatorId: CoatyUUID

    /// Timestamp when annotation was issued/created.
    /// Value represents the number of milliseconds since the epoc in UTC.
    /// (see Date.getTime(), Date.now())
    public var creationTimestamp: Double

    /// Status of storage
    public var status: AnnotationStatus

    /// Array of annotation media variants (optional). A variant is an object
    /// with a description key and a download url
    public var variants: [AnnotationVariant]?
    
    // MARK: Initializers.
    
    /// Default initializer for a n`Annotation` object.
    public init(type: AnnotationType,
                creatorId: CoatyUUID,
                creationTimestamp: Double,
                status: AnnotationStatus,
                name: String = "AnnotationObject",
                objectType: String = Annotation.objectType,
                objectId: CoatyUUID = .init(),
                variants: [AnnotationVariant]? = nil) {
        self.type = type
        self.creatorId = creatorId
        self.creationTimestamp = creationTimestamp
        self.status = status
        self.variants = variants
        super.init(coreType: .Annotation, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: Codable methods.
    
    enum AnnotationKeys: String, CodingKey, CaseIterable {
        case type
        case creatorId
        case creationTimestamp
        case status
        case variants
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnnotationKeys.self)
        self.type = try container.decode(AnnotationType.self, forKey: .type)
        self.creatorId = try container.decode(CoatyUUID.self, forKey: .creatorId)
        self.creationTimestamp = try container.decode(Double.self, forKey: .creationTimestamp)
        self.status = try container.decode(AnnotationStatus.self, forKey: .status)
        self.variants = try container.decodeIfPresent([AnnotationVariant].self, forKey: .variants)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: AnnotationKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: AnnotationKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(creationTimestamp, forKey: .creationTimestamp)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(variants, forKey: .variants)
    }

}

/// Variant object composed of a description key and a download url
public class AnnotationVariant: Codable {

    // MARK: Attributes.
    
    /// Description key of  annotation variant
    public var variant: String

    /// Dowload url for annotation variant
    public var downloadUrl: String
    
    // MARK: Initializers.
    
    public init(variant: String, downloadUrl: String) {
        self.variant = variant
        self.downloadUrl = downloadUrl
    }
    
    // MARK: Codable methods.
    
    enum AnnotationVariantKeys: String, CodingKey {
        case variant
        case downloadUrl
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnnotationVariantKeys.self)
        self.variant = try container.decode(String.self, forKey: .variant)
        self.downloadUrl = try container.decode(String.self, forKey: .downloadUrl)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnnotationVariantKeys.self)
        try container.encode(variant, forKey: .variant)
        try container.encode(downloadUrl, forKey: .downloadUrl)
    }
}

/// Defines all annotation types
public enum AnnotationType: Int, Codable {
    case text
    case image
    case audio
    case video
    case object3D
    case pdf
    case webDocumentUrl
    case liveDataUrl
}


public enum AnnotationStatus: Int, Codable {

    /// Set when annotation media has only been stored on the creator's local device
    case storedLocally

    /// Set when Advertise event for publishing annotation media is being sent
    case storageRequest

    /// Set when annotation media was stored by a service component subscribing for annotations
    case published

    /// Set when annotation media is outdated, i.e. should no longer be in use by application
    case outdated
}
