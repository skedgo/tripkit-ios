//
//  TripRequest+Classify.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TripRequest {
  public func updateTripGroupClassifications(using classifier: TKTripClassifier) {
    guard let groups = self.tripGroups else { return }
    classifier.prepareForClassification(of: groups)
    for group in groups {
      let newClassification = classifier.classification(of: group)
      let oldClassification = group.classification
      if oldClassification == nil || newClassification != oldClassification {
        group.classification = newClassification
      }
    }
  }
}
