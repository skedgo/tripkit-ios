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

  /// How many tickets of this fare to buy when someone selects it, i.e.,
  /// moves from "none" to "some": the `min`, or one if there's none.
  public var amountWhenSelected: Int {
    let wanted = Swift.max(min ?? 1, 1)
    return Swift.min(wanted, max ?? wanted)
  }

  /// Makes sure that an amount is something that can be purchased: either
  /// none, as `min` only applies once a fare is selected, or between
  /// `amountWhenSelected` and `max`.
  public func validAmount(_ amount: Int) -> Int {
    guard amount > 0 else { return 0 }
    return Swift.min(Swift.max(amount, amountWhenSelected), max ?? .max)
  }

  /// Resolves a +/-1 step from a stepper to the next valid amount, which skips
  /// over the amounts below `min` that can't be purchased, e.g., from 0 to 2
  /// and back to 0 if `min` is 2.
  ///
  /// - Parameters:
  ///   - stepped: Amount a stepper arrived at
  ///   - previous: Amount the stepper was at before the step
  public func validAmount(stepped: Int, from previous: Int) -> Int {
    guard stepped > 0 else { return 0 }
    if stepped < amountWhenSelected {
      // Below the minimum: Move up to the minimum when going up, or go to none
      return stepped > previous ? amountWhenSelected : 0
    } else {
      return validAmount(stepped)
    }
  }

}
