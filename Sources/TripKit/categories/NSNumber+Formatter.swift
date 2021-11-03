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
  
  public func toMoneyString(currencyCode: String) -> String {
    let formatter = Self.formatter
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.currencySymbol = nil
    formatter.zeroSymbol = NSLocalizedString("Free", tableName: "Shared", bundle: .tripKit, comment: "Free as in beer")
    formatter.roundingIncrement = NSNumber(value: 1)
    return formatter.string(from: self)!
  }
  
  public func toCarbonString() -> String {
    guard floatValue > 0 else {
      return NSLocalizedString("No\u{00a0}CO₂", tableName: "Shared", bundle: .tripKit, comment: "Indicator for no carbon emissions")
    }
    
    let formatter = Self.formatter
    formatter.numberStyle = .decimal
    formatter.currencyCode = nil
    formatter.currencySymbol = nil
    formatter.roundingIncrement = NSNumber(value: 0.1)
    formatter.zeroSymbol = nil
    return NSString(format: "%@kg\u{00a0}CO₂", formatter.string(from: self)!) as String
  }
  
  func toScoreString() -> String {
    let formatter = Self.formatter
    formatter.numberStyle = .currency
    formatter.currencyCode = nil
    formatter.currencySymbol = "❦"
    formatter.roundingIncrement = NSNumber(value: 0.1)
    formatter.zeroSymbol = nil
    return formatter.string(from: self)!
  }
  
}
