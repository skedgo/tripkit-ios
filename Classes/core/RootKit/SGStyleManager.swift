//
//  SGStyleManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SGKColor {
  
  @objc public static var routeDashColorNonTravelled: SGKColor {
    return SGKColor.lightGray.withAlphaComponent(0.25)
  }
  
}

// MARK: - Formatting

extension SGStyleManager {

  private static var exerciseFormatter: EnergyFormatter = {
    let formatter = EnergyFormatter()
    formatter.isForFoodEnergyUse = false // For exercise
    formatter.numberFormatter.maximumSignificantDigits = 2
    formatter.numberFormatter.usesSignificantDigits = true
    return formatter
  }()

  @objc(exerciseStringForCalories:)
  public static func exerciseString(calories: Double) -> String {
    return exerciseFormatter.string(fromValue: calories, unit: .kilocalorie)
  }
  
}
