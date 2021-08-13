//
//  TKTripClassifier.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// A trip classifier is used to classify `TripGroup` instances within the same `TripRequest`.
///
/// Classifications should be string constants.
///
/// For an example see `TKMetricClassifier`
public protocol TKTripClassifier {
  
  /// Called before starting a classifiction of multiple trip groups.
  /// - Parameter groups: The set of trip groups that will be classified.
  func prepareForClassification(of tripGroups: Set<TripGroup>)
  
  /// - Parameter group: The classifiction of that particular trip group.
  func classification(of group: TripGroup) -> String?
  
}
