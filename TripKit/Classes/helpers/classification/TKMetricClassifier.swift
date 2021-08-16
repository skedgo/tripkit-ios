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
    guard let token = group.classification else { return nil }
    return Classification(rawValue: token)
  }
  
  private struct MetricRange {
    var best: Trip?
    var min: Float? // min => best trip
    var max: Float? // max => worst trip
  }
  
  private var ranges: [Classification: MetricRange] = [:]
  
  @discardableResult
  private func register(_ trip: Trip, classification: Classification) -> Bool {
    guard let value = trip.value(for: classification) else { return false }
    
    var range = ranges[classification] ?? .init()
    if value < range.min ?? .infinity {
      range.min = value
      range.best = trip
    }
    if value > range.max ?? .leastNormalMagnitude {
      range.max = value
    }
    ranges[classification] = range
    return true
  }
}

extension TKMetricClassifier: TKTripClassifier {
  
  public func prepareForClassification(of tripGroups: Set<TripGroup>) {
    let trips = tripGroups.compactMap(\.representativeTrip)
    var anyHaveUnknownCost = false
    for trip in trips {
      if !register(trip, classification: .cheapest) {
        anyHaveUnknownCost = true
      }
      
      register(trip, classification: .recommended)
      register(trip, classification: .easiest)
      register(trip, classification: .fastest)
      register(trip, classification: .greenest)
      register(trip, classification: .healthiest)
    }
    
    // Recommended trip defines the max on everything else
    if let recommended = ranges[.recommended]?.best {
      ranges[.cheapest]?.max = recommended.value(for: .cheapest)
      ranges[.easiest]?.max = recommended.value(for: .easiest)
      ranges[.fastest]?.max = recommended.value(for: .fastest)
      ranges[.greenest]?.max = recommended.value(for: .greenest)
      ranges[.healthiest]?.max = recommended.value(for: .healthiest)
    }
    
    // No 'Cheapest' tag if we don't know the price of some trip.
    if anyHaveUnknownCost {
      ranges[.cheapest] = nil
    }
  }
  
  public func classification(of tripGroup: TripGroup) -> String? {
    // TODO: Order this by what the user cares about
    // recommended > fast > cheap > healthy > easy > green
    
    guard let trip = tripGroup.representativeTrip else { return nil }
    
    if matches(trip, classification: .recommended) {
      return TKMetricClassifier.Classification.recommended.rawValue
    }
    if matches(trip, classification: .fastest) {
      return TKMetricClassifier.Classification.fastest.rawValue
    }
    if matches(trip, classification: .cheapest) {
      return TKMetricClassifier.Classification.cheapest.rawValue
    }
    if matches(trip, classification: .healthiest) {
      return TKMetricClassifier.Classification.healthiest.rawValue
    }
    if matches(trip, classification: .easiest) {
      return TKMetricClassifier.Classification.easiest.rawValue
    }
    if matches(trip, classification: .greenest) {
      return TKMetricClassifier.Classification.greenest.rawValue
    }
    return nil
  }

  private func matches(_ trip: Trip, classification: Classification) -> Bool {
    guard
      let min = ranges[classification]?.min, let max = ranges[classification]?.max,
      let value = trip.value(for: classification)
    else { return false }
    
    guard min == value else { return false }
    
    // max has to be more than 25% of min, i.e., don't give the label
    // if everything is so clsoe
    return max > min * 1.25
  }

  
  private func matches(min: Float, max: Float, value: Float?) -> Bool {
    guard let value = value else { return false }
    guard min == value else { return false }
    
    // max has to be more than 25% of min, i.e., don't give the label
    // if everything is so clsoe
    return max > min * 1.25
  }
  
}

fileprivate extension Trip {
  func value(for classification: TKMetricClassifier.Classification) -> Float? {
    switch classification {
    case .cheapest: return totalPrice?.floatValue
    case .recommended: return totalScore
    case .fastest: return Float(minutes)
    case .easiest: return totalHassle
    case .healthiest: return totalCalories * -1 // inverted!
    case .greenest: return totalCarbon
    }
  }
}

fileprivate extension TripGroup {
  var representativeTrip: Trip? {
    self.trips
      .filter { !$0.isCanceled }
      .min { $0.totalScore < $1.totalScore }
  }
}
