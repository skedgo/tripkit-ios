//
//  InMemoryHistoryManager.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 29/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit

class InMemoryHistoryManager {
  
  struct History {
    let annotation: MKAnnotation
    let date: Date
  }
  
  static let shared = InMemoryHistoryManager()
  
  var history: [History] = []
  
  func add(_ annotation: MKAnnotation) {
    let mostRecent = History(annotation: annotation, date: Date())
    
    guard history.first(where: { $0 == mostRecent }) == nil else {
      print("search result is already in history, skip")
      return
    }
    
    history.append(mostRecent)
    
    print("recent searches count: \(history.count)")
  }
  
}

extension InMemoryHistoryManager.History: Equatable {
  
  static func == (lhs: InMemoryHistoryManager.History, rhs: InMemoryHistoryManager.History) -> Bool {
    return lhs.annotation.coordinate.latitude == rhs.annotation.coordinate.latitude &&
      lhs.annotation.coordinate.longitude == rhs.annotation.coordinate.longitude
  }
  
}
