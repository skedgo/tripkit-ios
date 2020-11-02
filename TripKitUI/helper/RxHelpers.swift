//
//  RxHelpers.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Signal where SharingStrategy == SignalSharingStrategy {
  
  func startOptional() -> Signal<Element?> {
    return map { $0 as Element? }
      .startWith(nil)
  }
  
}

extension Driver where SharingStrategy == DriverSharingStrategy {
  
  func startOptional() -> Driver<Element?> {
    return map { $0 as Element? }
      .startWith(nil)
  }
  
}

extension TableViewSectionedDataSource where Section : SectionModelType, Section.Item : Equatable {
  
  func indexPath(of needle: Section.Item?) -> IndexPath? {
    guard let needle = needle else { return nil }
    for (section, s) in self.sectionModels.enumerated() {
      for (item, i) in s.items.enumerated() {
        if i == needle {
          return IndexPath(item: item, section: section)
        }
      }
    }
    return nil
  }
  
}
