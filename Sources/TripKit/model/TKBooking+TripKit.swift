//
//  TKBooking+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import Foundation

extension TKBooking.BookingInput {
  
  public var longText: String? {
    switch value {
    case .longText(let value): return value
    default: return nil
    }
  }
  
  public var singleSelection: String? {
    switch value {
    case .singleSelection(let value): return value
    default: return nil
    }
  }
  
  public var multipleSelections: [String]? {
    switch value {
    case .multipleSelections(let values): return values
    default: return nil
    }
  }
  
  public func displayTitle(for optionId: InputOption.ID) -> String? {
    return options?.first(where: { $0.id == optionId })?.title
  }
  
}

extension TKBooking.BookingInput.ReturnTripDateValue {
  
  public func toString(forJSONEncoding: Bool = true, timeZone: TimeZone = .autoupdatingCurrent) -> String {
    guard !forJSONEncoding else {
      return toJSONString()
    }
    
    switch self {
    case .unspecified: return ""
    case .oneWayTrip: return Loc.OneWayOnly
    case .date(let date):
      if forJSONEncoding {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
      } else {
        return TKStyleManager.format(date, for: timeZone, showDate: true, showTime: true)
      }
    }
  }
  
}

extension TKBooking.Fare {
  
  public func priceValue(locale: Locale = .current) -> String? {
    guard let price, let currencyCode else { return nil }
    return NSNumber(value: Float(price) / 100).toMoneyString(currencyCode: currencyCode, locale: locale)
  }

  public func noAmount() -> Bool {
    return amount ?? 0 == 0
  }
  
}
