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
  
  // TODO: Better name / distinction from toMoneyString
  public func toCurrencyString(currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.currencySymbol = nil
    formatter.zeroSymbol = NSLocalizedString("Free", tableName: "Shared", bundle: .tripKit, comment: "Free as in beer")
    formatter.roundingIncrement = NSNumber(value: 1)
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter.string(from: self)!
  }
  
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
      // Should really be as below, but it breaks Xcode export
      // See https://developer.apple.com/forums/thread/696752?login=true
      //
      // Should be: "No\u{00a0}CO₂" (i.e., non-breaking unicode)
      return NSLocalizedString("No CO₂", tableName: "Shared", bundle: .tripKit, comment: "Indicator for no carbon emissions. Note the space is non-breaking white space!")
    }
    
    let formatter = Self.formatter
    formatter.numberStyle = .decimal
    formatter.currencyCode = nil
    formatter.currencySymbol = nil
    formatter.roundingIncrement = NSNumber(value: 0.1)
    formatter.zeroSymbol = nil
    // Should be "%@kg\u{00a0}CO₂" (i.e., non-breaking unicode)
    return NSString(format: "%@kg CO₂", formatter.string(from: self)!) as String
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
