//
//  TKUIServiceViewModel+Content.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension TKUIServiceViewModel {
  
  /// Section in a table view
  enum Section: Hashable {
    case single
  }
  
  /// For individual cells in a table view, representing a stop along the
  /// route
  struct Item: Hashable {
    let dataModel: StopVisits
    
    /// Title of the stop
    let title: String
    
    /// Timing at this stop
    let timing: TKServiceTiming
    
    /// Time zone of the stop
    let timeZone: TimeZone
    
    /// Real-time satatus of the departure
    let realTimeStatus: StopVisits.RealTime
    
    /// Whether this stop is at or after disembarkation, and, optionally,
    /// at or before the disembarkation
    let isVisited: Bool
    
    /// Colour of line to draw of the beginning of the cell to this stop
    let topConnection: UIColor?
    
    /// Colour of line to draw from the stop to the end of the cell
    let bottomConnection: UIColor?
  }
  
}

// MARK: - Creating sections

extension TKUIServiceViewModel {
  
  static func buildSections(for embarkation: StopVisits, disembarkation: StopVisits?) -> [(Section, [Item])] {
    
    let items = embarkation.service
      .visitsIncludingContinuation()
      .compactMap { Item($0, embarkation: embarkation, disembarkation: disembarkation) }
    
    return [(.single, items)]
  }
  
}

extension Service {
  var includingContinuations: [Service] {
    var services: [Service] = []
    var serviceToShow: Service? = self
    while serviceToShow != nil {
      services.append(serviceToShow!)
      serviceToShow = serviceToShow?.continuation
    }
    return services
  }
  
  func visitsIncludingContinuation() -> [StopVisits] {
    return includingContinuations.flatMap { $0.sortedVisits }
  }
}

extension TKUIServiceViewModel.Item {
  fileprivate init?(_ visit: StopVisits, embarkation: StopVisits, disembarkation: StopVisits?) {
    guard
      let service = visit.service,
      let embarkationService = embarkation.service,
      let stop = visit.stop
    else { return nil }
    
    var isVisited = visit >= embarkation
    if let disembarkation = disembarkation, isVisited {
      isVisited = visit <= disembarkation
    }
    
    // Important to use service from `embarkation`, not the one from `visit`,
    // as `visit.service` might be a continuation of `embarkation.service`
    let sortedVisits = embarkationService.visitsIncludingContinuation()

    let serviceColor = service.color ?? .black

    let topConnectionColor: UIColor?
    if visit == sortedVisits.first {
      topConnectionColor = nil
    } else {
      topConnectionColor = (isVisited && visit != embarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    }
    
    let bottomConnectionColor: UIColor?
    if visit == sortedVisits.last {
      bottomConnectionColor = nil
    } else {
      bottomConnectionColor = (isVisited && visit != disembarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    }
    
    self.init(
      dataModel: visit,
      title: stop.title ?? stop.stopCode,
      timing: visit.timing,
      timeZone: visit.timeZone,
      realTimeStatus: visit.realTimeStatus,
      isVisited: isVisited,
      topConnection: topConnectionColor,
      bottomConnection: bottomConnectionColor
    )
  }
}
