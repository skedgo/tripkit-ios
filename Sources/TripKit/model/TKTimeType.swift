//
//  TKTimeType.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
public enum TKTimeType: Int, Hashable {
  case leaveASAP = 0
  case leaveAfter
  case arriveBefore
  case `none`
}
