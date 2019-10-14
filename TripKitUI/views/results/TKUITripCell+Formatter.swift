//
//  TKUITripCell+Formatter.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKUITripCell {
  
  @objc(TKUITripCellFormatter)
  public class Formatter: NSObject {
    @objc public var primaryFont: UIFont?
    @objc public var primaryColor: UIColor = .tkLabelPrimary
    
    @objc public var secondaryFont: UIFont?
    @objc public var secondaryColor: UIColor = .tkLabelSecondary
    
    @objc public var costColor: UIColor = .tkLabelSecondary
    
    @objc
    public override init() {
      super.init()
    }
    
    @objc
    public func timeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      
      let titles = Trip.timeTitles(departure: departure, arrival: arrival, departureTimeZone: departureTimeZone, arrivalTimeZone: arrivalTimeZone, focusOnDuration: focusOnDuration, isArriveBefore: isArriveBefore)
      
      let attributed = NSMutableAttributedString()
      append(titles.title, to: attributed, isPrimary: true)
      append(" (\(titles.subtitle))", to: attributed, isPrimary: false)
      return attributed
    }
    
    public func primaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      let attributes = [
        NSAttributedString.Key.font: TKStyleManager.customFont(forTextStyle: .body),
        NSAttributedString.Key.foregroundColor: UIColor.tkLabelPrimary
      ]
      
      if focusOnDuration {
        return NSAttributedString(string: arrival.durationSince(departure), attributes: attributes)
      } else {
        var fullText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
        fullText.append(" - ")
        fullText.append(TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone))
        return NSAttributedString(string: fullText, attributes: attributes)
      }
    }
    
    public func secondaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      let attributes = [
          NSAttributedString.Key.font: TKStyleManager.customFont(forTextStyle: .subheadline),
          NSAttributedString.Key.foregroundColor: UIColor.tkLabelSecondary
      ]
      
      if focusOnDuration {
        if isArriveBefore {
          let timeText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
          let fullText = "\(Loc.Departs(atTime: timeText))"
          return NSAttributedString(string: fullText, attributes: attributes)
        } else {
          let timeText = TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
          let fullText = "\(Loc.Arrives(atTime: timeText))"
          return NSAttributedString(string: fullText, attributes: attributes)
        }
      } else {
        return NSAttributedString(string: arrival.durationSince(departure), attributes: attributes)
      }
    }
    
    @objc
    public func costString(costs: [NSNumber: String]) -> NSAttributedString {
      let attributed = NSMutableAttributedString()
      if let price = costs[.price] {
        append(price, to: attributed, color: costColor)
        append(" ⋅ ", to: attributed, color: costColor)
      }
      append(costs[.calories], to: attributed, color: costColor)
      append(" ⋅ ", to: attributed, color: costColor)
      append(costs[.carbon], to: attributed, color: costColor)
      return attributed
    }
    
    public func costAccessibilityLabel(costs: [NSNumber: String]) -> String {
      return [
          costs[.price],
          costs[.calories],
          costs[.carbon]?.replacingOccurrences(of: "CO₂", with: "C-O-2") // Don't say "Co subscript 2"
        ]
        .compactMap { $0 }
        .joined(separator: "; ")
    }

    private func append(_ string: String?, to attributed: NSMutableAttributedString, isPrimary: Bool) {
      append(string, to: attributed, font: isPrimary ? primaryFont : secondaryFont, color: isPrimary ? primaryColor : secondaryColor)
    }
    
    private func append(_ string: String?, to attributed: NSMutableAttributedString, font: UIFont? = nil, color: UIColor) {
      guard let string = string else { return }
      
      var attributes = [NSAttributedString.Key: Any]()
      if let font = font {
        attributes[.font] = font
      }
      attributes[.foregroundColor] = color

      let addition = NSAttributedString(string: string, attributes: attributes)
      attributed.append(addition)
    }
  }
  
}

fileprivate extension Dictionary where Key == NSNumber {
  
  subscript(cost: TKTripCostType) -> Value? {
    return self[NSNumber(value: cost.rawValue)]
  }
  
}
