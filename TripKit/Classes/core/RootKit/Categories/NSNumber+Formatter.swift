//
//  NSNumber+Formatter.swift
//  TripKit
//
//  Created by Adrian Schönig on 10.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension NSNumber {
  
  private static let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.maximumSignificantDigits = 2
    formatter.usesSignificantDigits = true
    formatter.roundingMode = .up
    return formatter
  }()
  
  @objc(toMoneyStringWithCurrencyCode:)
  public func toMoneyString(currencyCode: String) -> String {
    guard ceil(floatValue) >= 1 else {
      return NSLocalizedString("Free", tableName: "Shared", bundle: .tripKit, comment: "Free as in beer")
    }
    
    let formatter = Self.formatter
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.roundingIncrement = NSNumber(value: 1)
    return formatter.string(from: self)!
  }
  
  @objc(toCarbonString)
  public func toCarbonString() -> String {
    guard floatValue > 0 else {
      return NSLocalizedString("No CO₂", tableName: "Shared", bundle: .tripKit, comment: "Indicator for no carbon emissions")
    }
    
    let formatter = Self.formatter
    formatter.numberStyle = .decimal
    formatter.currencyCode = nil
    formatter.roundingIncrement = NSNumber(value: 0.1)
    return NSString(format: "%@kg CO₂", formatter.string(from: self)!) as String
  }
  
}
