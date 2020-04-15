//
//  TKMetricClassifier.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKMetricClassifier: NSObject {
  
  public enum Classification: String {
    case recommended
    case cheapest
    case fastest
    case easiest
    case healthiest
    case greenest
  }
  
  public static func classification(for group: TripGroup) -> Classification? {
    guard let token = group.classification as? String else { return nil }
    return Classification(rawValue: token)
  }
  
  private var weighted: (min: Float?, max: Float?)?
  private var prices: (min: Float?, max: Float?)?
  private var hassles: (min: Float, max: Float)?
  private var durations: (min: Float, max: Float)?
  private var calories: (min: Float, max: Float)?
  private var carbons: (min: Float, max: Float)?
}

extension TKMetricClassifier: TKTripClassifier {
  
  public func prepareForClassifiction(of tripGroups: Set<TripGroup>) {
    let trips = tripGroups.compactMap { $0.visibleTrip }
    var anyHaveUnknownCost = false
    for trip in trips {
      if let price = trip.totalPrice?.floatValue {
        prices = (min(prices?.min ?? .infinity, price), max(prices?.max ?? .leastNormalMagnitude, price))
      } else {
        anyHaveUnknownCost = true
      }
      
      weighted = (min(weighted?.min ?? .infinity, trip.totalScore),
                  max(weighted?.max ?? .leastNormalMagnitude, trip.totalScore))
      hassles = (min(hassles?.min ?? .infinity, trip.totalHassle),
                 max(hassles?.max ?? .leastNormalMagnitude, trip.totalHassle))
      durations = (min(durations?.min ?? .infinity, trip.calculateDuration().floatValue),
                   max(durations?.max ?? .leastNormalMagnitude, trip.calculateDuration().floatValue))
      
      // inverted!
      calories = (min(calories?.min ?? .infinity, trip.totalCalories * -1),
                  max(calories?.max ?? .leastNormalMagnitude, trip.totalCalories * -1))
      
      carbons = (min(carbons?.min ?? .infinity, trip.totalCarbon),
                 max(carbons?.max ?? .leastNormalMagnitude, trip.totalCarbon))
    }
    if anyHaveUnknownCost {
      prices = nil
    }
  }
  
  public func classification(of tripGroup: TripGroup) -> (NSCoding & NSObjectProtocol)? {
    // TODO: Order this by what the user cares about
    // recommended > fast > cheap > healthy > easy > green
    
    guard let trip = tripGroup.visibleTrip else { return nil }
    
    if let min = weighted?.min, let max = weighted?.max, matches(min: min, max: max, value: trip.totalScore) {
      return TKMetricClassifier.Classification.recommended.rawValue as NSString
    }
    if let min = durations?.min, let max = durations?.max, matches(min: min, max: max, value: trip.calculateDuration().floatValue) {
      return TKMetricClassifier.Classification.fastest.rawValue as NSString
    }
    if let min = prices?.min, let max = prices?.max, matches(min: min, max: max, value: trip.totalPrice?.floatValue) {
      return TKMetricClassifier.Classification.cheapest.rawValue as NSString
    }
    if let min = calories?.min, let max = calories?.max, matches(min: min, max: max, value: trip.totalCalories * -1) { // inverted!
      return TKMetricClassifier.Classification.healthiest.rawValue as NSString
    }
    if let min = hassles?.min, let max = hassles?.max, matches(min: min, max: max, value: trip.totalHassle) {
      return TKMetricClassifier.Classification.easiest.rawValue as NSString
    }
    if let min = carbons?.min, let max = carbons?.max, matches(min: min, max: max, value: trip.totalCarbon) {
      return TKMetricClassifier.Classification.greenest.rawValue as NSString
    }
    return nil
  }
  
  private func matches(min: Float, max: Float, value: Float?) -> Bool {
    guard let value = value else { return false }
    guard min == value else { return false}
    
    // max has to be more than 25% of min, i.e., don't give the label
    // if everything is so clsoe
    return max > min * 1.25
  }
  
}
