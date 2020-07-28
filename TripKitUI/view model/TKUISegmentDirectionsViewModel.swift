//
//  TKUISegmentDirectionsViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class TKUISegmentDirectionsViewModel {
  
  static func canShowInstructions(for segment: TKSegment) -> Bool {
    guard segment.isSelfNavigating else { return false }
    return !segment.shapes.isEmpty
  }
  
  init(segment: TKSegment) {
    self.sections = TKUISegmentDirectionsViewModel
      .buildSections(for: segment)
      .asDriver(onErrorJustReturn: [])
  }
  
  let sections: Driver<[Section]>
  
}
