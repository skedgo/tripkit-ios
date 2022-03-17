//
//  InMemoryHistoryManager.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 29/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

final class InMemoryHistoryManager {
  
  struct History {
    let annotation: MKAnnotation
    let date: Date
  }
  
  static let shared = InMemoryHistoryManager()
  
  var history: BehaviorSubject<[History]> = .init(value: [])
  var selection: Signal<History> = .empty()

  func add(_ annotation: MKAnnotation) {
    let mostRecent = History(annotation: annotation, date: Date())
    
    guard
      var histories = try? history.value(),
      histories.first(where: { $0 == mostRecent }) == nil else {
      print("search result is already in history, skip")
      return
    }
    
    histories.append(mostRecent)
    print("recent searches count: \(histories.count)")
    
    history.onNext(histories)
  }
  
}

extension InMemoryHistoryManager.History: Equatable {
  
  static func == (lhs: InMemoryHistoryManager.History, rhs: InMemoryHistoryManager.History) -> Bool {
    return lhs.annotation.coordinate.latitude == rhs.annotation.coordinate.latitude &&
      lhs.annotation.coordinate.longitude == rhs.annotation.coordinate.longitude
  }
  
}
