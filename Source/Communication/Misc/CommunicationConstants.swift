//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  CommunicationConstants.swift
//  CoatySwift
//
//

import Foundation

// MARK: - Constants for topic parsing.

let TOPIC_SEPARATOR = "/"
let SINGLE_TOPIC_LEVEL_WILDCARD = "+"
let MULTI_TOPIC_LEVEL_WILDCARD = "#"
let PROTOCOL_NAME = "coaty"
let PROTOCOL_NAME_PREFIX = PROTOCOL_NAME + TOPIC_SEPARATOR
let PROTOCOL_VERSION = 3
let DEFAULT_NAMESPACE = "-"
let EVENT_TYPE_FILTER_SEPARATOR = ":"
