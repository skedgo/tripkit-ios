//
//  TKUIServiceViewModel+Content.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreData
import UIKit

import TripKit

extension TKUIServiceViewModel {

  enum SectionGroup: Hashable {
    case incoming
    case info
    case main
  }
  
  struct Section: Hashable, Identifiable {
    var id: SectionGroup { group }
    
    let group: SectionGroup
    let items: [Item]
  }
  
  enum Item: Hashable, Identifiable {
    case timing(TimingItem)
    case info(TKUIServiceInfoView.Content)
    
    var id: String {
      switch self {
      case .timing(let timing): return timing.modelID.uriRepresentation().absoluteString
      case .info(let content): return content.id
      }
    }
  }
  
  /// For individual cells in a table view, representing a stop along the
  /// route
  struct TimingItem: Hashable {
    let modelID: NSManagedObjectID
    
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
    
    /// This is the accessibility of the stop-only, as the
    /// service accessibility is assumed covered by the title
    /// of the screen.
    let stopAccessibility: TKWheelchairAccessibility
  }
  
}

// MARK: - Creating sections

extension TKUIServiceViewModel {
  
  static func buildSections(for embarkation: StopVisits, disembarkation: StopVisits?) -> [Section] {
    guard let service = embarkation.service else {
      return [] // No longer available
    }
    
    let allVisits = service.visitsIncludingContinuation()
    
    var sections: [Section] = []
    if let split = allVisits.firstIndex(of: embarkation) {
      let incoming = allVisits[..<split]
      if !incoming.isEmpty {
        sections.append(Section(
          group: .incoming,
          items: incoming.compactMap { TimingItem($0, embarkation: embarkation, disembarkation: disembarkation) }.map { .timing($0) }
        ))
      }
      
      // Note, for DLS entries `disembarkation` will be nil, but the accessibility
      // is already handled then under `disembarkation`.
      var wheelchairAccessibility = embarkation.wheelchairAccessibility
      if let atEnd = disembarkation?.wheelchairAccessibility {
        wheelchairAccessibility = wheelchairAccessibility.combine(with: atEnd)
      }
      let infoItems = [
        TKUIServiceInfoView.Content(
          id: "accessibility",
          wheelchairAccessibility: wheelchairAccessibility,
          bicycleAccessibility: service.bicycleAccessibility,
          vehicleComponents: service.vehicle?.components ?? [[]],
          timestamp: service.vehicle?.lastUpdate
        ),
        TKUIServiceInfoView.Content(
          id: "alerts",
          alerts: service.allAlerts()
            .compactMap { alert in alert.title.map { .init(isCritical: alert.isCritical(), title: $0, body: alert.text) }}
        )
      ].filter { !$0.isEmpty }
      if !infoItems.isEmpty {
        sections.append(Section(group: .info, items: infoItems.map { .info($0) }))
      }
      
      let outgoing = allVisits[split...]
      if !outgoing.isEmpty {
        sections.append(Section(
          group: .main,
          items: outgoing.compactMap { TimingItem($0, embarkation: embarkation, disembarkation: disembarkation) }.map { .timing($0) }
        ))
      }
      
    } else {
      assertionFailure()
    }
    return sections
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
    return includingContinuations.flatMap(\.sortedVisits)
  }
}

extension TKUIServiceViewModel.TimingItem {
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
      modelID: visit.objectID,
      title: stop.title ?? stop.stopCode,
      timing: visit.timing,
      timeZone: visit.timeZone,
      realTimeStatus: visit.realTimeStatus,
      isVisited: isVisited,
      topConnection: topConnectionColor,
      bottomConnection: bottomConnectionColor,
      stopAccessibility: stop.wheelchairAccessibility
    )
  }
}
