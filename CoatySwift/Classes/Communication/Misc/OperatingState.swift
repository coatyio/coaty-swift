//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  OperatingState.swift
//  CoatySwift
//
//

/// Operating state indicates the current state of a CommunicationManager.
public enum OperatingState {
    case initial
    case starting
    case started
    case stopping
    case stopped
}
