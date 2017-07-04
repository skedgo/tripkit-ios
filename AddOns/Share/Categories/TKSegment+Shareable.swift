//
//  TKSegment+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKSegment: TKURLShareable {
  public var shareURL: URL? {
    get {
      let isEnd = self.order() == .end
      guard let coordinate = isEnd ? end?.coordinate : start?.coordinate else { return nil }
      let time = isEnd ? arrivalTime : departureTime
      return TKShareHelper.meetURL(for: coordinate, atTime: time)
    }
  }
  
}
