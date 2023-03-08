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
    
  /// formats the NSNumber to a readable currency formatted string that auto handles the decimal places.
  public func toMoneyString(currencyCode: String) -> String {
    let formatter = moneyFormatter(with: currencyCode)
    return formatter.string(from: self)!
  }
  
  /// formats the NSNumber to a readable currency formatted string that forces the number of decimal places.
  public func toMoneyString(currencyCode: String, decimalPlaces: Int = 0) -> String {
    let formatter = moneyFormatter(with: currencyCode)
    formatter.currencySymbol = nil
    
    if decimalPlaces == 0 {
      formatter.roundingIncrement = NSNumber(value: 1)
    }
    formatter.maximumFractionDigits = decimalPlaces
    formatter.minimumFractionDigits = decimalPlaces
    
    return formatter.string(from: self)!
  }
  
  private func moneyFormatter(with currencyCode: String) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.zeroSymbol = NSLocalizedString("Free", tableName: "Shared", bundle: .tripKit, comment: "Free as in beer")
    formatter.usesGroupingSeparator = true
    
    return formatter
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
