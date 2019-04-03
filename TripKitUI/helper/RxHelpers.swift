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
import RxDataSources

extension Driver where S == DriverSharingStrategy {
  
  func startWithOptional(_ element: Element?) -> Driver<Element?> {
    return map { $0 as Element? }.startWith(element)
  }
  
}

extension Signal where S == SignalSharingStrategy {
  
  func startWithOptional(_ element: Element?) -> Observable<Element?> {
    return map { $0 as Element? }.asObservable().startWith(element)
  }
  
}


extension TableViewSectionedDataSource where S : SectionModelType, S.Item : Equatable {
  
  func indexPath(of needle: S.Item?) -> IndexPath? {
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
