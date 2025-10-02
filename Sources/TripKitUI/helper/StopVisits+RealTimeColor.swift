//
//  StopVisits+RealTimeColor.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 02.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension StopVisits.RealTime {
  var color: UIColor {
    switch self {
      case .canceled: return .tkStateError
      case .early, .late: return .tkStateWarning
      case .onTime: return .tkStateSuccess
      case .notApplicable, .notAvailable: return .tkLabelSecondary
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return .tkLabelSecondary
    }
  }
}
