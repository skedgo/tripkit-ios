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
      guard
        let coordinate = isEnd ? end?.coordinate : start?.coordinate,
        let time = isEnd ? arrivalTime : departureTime
        else { return nil }
      
      return TKShareHelper.createMeetURL(coordinate: coordinate, at: time)
    }
  }
  
}
