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
    @objc public var primaryColor: UIColor?
    
    @objc public var secondaryFont: UIFont?
    @objc public var secondaryColor: UIColor?
    
    @objc public var costColor: UIColor?
    
    @objc
    public override init() {
      super.init()
    }

    @objc
    public func timeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      
      let attributed = NSMutableAttributedString()
      
      let duration = arrival.durationSince(departure)
      if focusOnDuration {
        append(duration, to: attributed, isPrimary: true)
        
        let secondaryText: String
        if isArriveBefore {
          let timeText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
          secondaryText = " (\(Loc.Departs(atTime: timeText)))"
        } else {
          let timeText = TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
          secondaryText = " (\(Loc.Arrives(atTime: timeText)))"
        }
        append(secondaryText, to: attributed, isPrimary: false)
      
      } else {
        append(TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone), to: attributed, isPrimary: true)
        append(" - ", to: attributed, isPrimary: true)
        append(TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone), to: attributed, isPrimary: true)
        
        append(" (\(duration))", to: attributed, isPrimary: false)
      }
      
      return attributed
    }
    
    @objc
    public func costString(costs: [NSNumber: String]) -> NSAttributedString {
      let attributed = NSMutableAttributedString()
      if let price = costs[.price] {
        append(price, to: attributed)
        append(" ⋅ ", to: attributed, color: costColor)
      }
      append(costs[.calories], to: attributed)
      append(" ⋅ ", to: attributed, color: costColor)
      append(costs[.carbon], to: attributed)
      return attributed
    }

    private func append(_ string: String?, to attributed: NSMutableAttributedString, isPrimary: Bool) {
      append(string, to: attributed, font: isPrimary ? primaryFont : secondaryFont, color: isPrimary ? primaryColor : secondaryColor)
    }
    
    private func append(_ string: String?, to attributed: NSMutableAttributedString, font: UIFont? = nil, color: UIColor? = nil) {
      guard let string = string else { return }
      
      var attributes = [NSAttributedString.Key: Any]()
      if let font = font {
        attributes[.font] = font
      }
      if let foreground = color {
        attributes[.foregroundColor] = foreground
      }
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
