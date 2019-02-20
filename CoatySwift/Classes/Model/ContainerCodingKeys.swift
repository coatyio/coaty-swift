//
//  ContainerCodingKeys.swift
//  CoatySwift
//
//

import Foundation

/// ContainerCodingKeys defines the keys that used in the top level JSON encoding of Coaty objects.
/// This container is required to achieve the Coaty message structure:
/// {"object": <>, "privateData": <>}
enum ContainerCodingKeys: String, CodingKey {
    case object
    case privateData
}
