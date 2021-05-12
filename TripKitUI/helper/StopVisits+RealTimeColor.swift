//
//  StopVisits+RealTimeColor.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 02.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKStopVisitRealTime {
  var color: UIColor {
    switch self {
      case .cancelled: return .tkStateError
      case .early, .late: return .tkStateWarning
      case .onTime: return .tkStateSuccess
      case .notApplicable, .notAvailable: return .tkLabelSecondary
    }
  }
}
