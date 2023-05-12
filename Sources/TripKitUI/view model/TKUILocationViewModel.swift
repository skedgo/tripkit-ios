//
//  TKUILocationViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 3/5/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

import TripKit

class TKUILocationViewModel {
  
  enum Section {
    case main
  }
  
  struct Item: Identifiable, Hashable {
    let id: String
    let title: String
    var subtitle: String?
    let image: UIImage?
  }
  
  init(for location: TKNamedCoordinate) {
    
    let realTimeInfo = TKLocationRealTime.streamRealTime(for: location)
      .map { $0 as TKAPI.LocationInfo? }
      .startWith(nil)
      .catchAndReturn(nil)
    
    self.sections = realTimeInfo
      .map { Self.build(for: location, info: $0) }
      .asDriver(onErrorJustReturn: [])
  }
  
  let sections: Driver<[(Section, [Item])]>
  
}

extension TKUILocationViewModel {
  
  static func build(for location: TKNamedCoordinate, info: TKAPI.LocationInfo?) -> [(Section, [Item])] {
    // LATER: Add things like bike pods, car share pods, free-floating vehicle info, etc.
    var items: [Item] = []
    
    if let address = location.address {
      items.append(.init(
        id: "main-address",
        title: address,
        image: .iconPin
      ))
    }
    
    if let w3w = info?.details?.w3w {
      items.append(.init(
        id: "main-w3w",
        title: w3w,
        subtitle: Loc.What3wordsAddress,
        image: TKStyleManager.image(named: "icon-what3word")
      ))
    }
    
    // TODO: Add DataSources, too

    return [(.main, items)]
  }
  
}
