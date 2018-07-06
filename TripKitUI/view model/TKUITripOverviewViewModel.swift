//
//  TKUITripOverviewViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

#if TK_NO_MODULE
#else
  import TripKit
#endif

class TKUITripOverviewViewModel {
  
  init(trip: Trip) {
    self.trip = trip
    
    self.sections = Driver.just(TKUITripOverviewViewModel.buildSections(for: trip))
  }

  let trip: Trip
  
  let sections: Driver<[Section]>
  
}


