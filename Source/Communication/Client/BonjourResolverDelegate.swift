//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  BonjourResolverDelegate.swift
//  CoatySwift
//
//

import Foundation

protocol BonjourResolverDelegate {
    func didReceiveService(addresses: [String], port: Int)
}
