//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  LightExecutionInfo.swift
//  CoatySwift_Example
//
//

import Foundation
import CoatySwift

/// Represents execution information returned with a remote light control operation.
class LightExecutionInfo: Codable {
    
    /// Object Id of the Light object that has been controlled.
    var lightId: CoatyUUID
    
    /// The timestamp in UTC milliseconds when the light control operation has
    /// been triggered.
    var triggerTime: Double
    
    init(lightId: CoatyUUID, triggerTime: Double) {
        self.lightId = lightId
        self.triggerTime = triggerTime
    }
}
