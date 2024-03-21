//
//  TKUIServiceViewModel+MapContent.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 20.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TripKit

extension TKUIServiceViewModel {
  
  /// All the content to display about a service on a map
  struct MapContent {
    
    /// Time point representing the embarkation
    let embarkation: TKUISemaphoreDisplayable
    
    /// Time point representing the disembarkation
    let disembarkation: TKUISemaphoreDisplayable?
    
    /// Shapes to draw representing the route that the service takes, with
    /// colour according to whether it is travelled or not
    let shapes: [TKDisplayableRoute]
    
    /// All stops along the route
    let stops: [TKUIModeAnnotation & TKUICircleDisplayable]
    
    /// Annotations for vehicles servicing the route
    ///
    /// - note: These are dynamic and change with real-time information
    let vehicles: [MKAnnotation]
  }
  
}

// MARK: - Creating map content

extension TKUIServiceViewModel {
  
  static func buildMapContent(for embarkation: StopVisits, disembarkation: StopVisits?) -> MapContent? {
    guard let service = embarkation.service else { return nil }
    
    let shapes = service.includingContinuations
      .flatMap { $0.shapes(embarkation: embarkation, disembarkation: disembarkation) }
    let vehicles = [service].compactMap { $0.vehicle } + Array(service.vehicleAlternatives ?? [])
    
    let stops = service.visitsIncludingContinuation()
      .map { ServiceVisit(visit: $0, embarkation: embarkation, disembarkation: disembarkation) }
    
    return MapContent(
      embarkation: ServiceEmbarkation(visit: embarkation, action: .embark)!,
      disembarkation: ServiceEmbarkation(visit: disembarkation, action: .disembark),
      shapes: shapes,
      stops: stops,
      vehicles: vehicles
    )
  }
}

extension TKUIServiceViewModel.MapContent {
  func findStop(_ item: TKUIServiceViewModel.Item) -> TKUIIdentifiableAnnotation? {
    return stops
      .compactMap { $0 as? TKUIServiceViewModel.ServiceVisit }
      .first { $0.visit == item.dataModel }
  }
}

// MARK: Visits along the way

extension TKUIServiceViewModel {
  
  class ServiceVisit: NSObject {
    fileprivate let visit: StopVisits
    let isVisited: Bool
    
    var color: UIColor { visit.service.color ?? .black }

    init(visit: StopVisits, embarkation: StopVisits, disembarkation: StopVisits?) {
      self.visit = visit
      
      if visit < embarkation {
        isVisited = false
      } else if let disembarkation = disembarkation, visit > disembarkation {
        isVisited = false
      } else {
        isVisited = true
      }
    }
  }
}

extension TKUIServiceViewModel.ServiceVisit: TKUICircleDisplayable {
  var circleColor: UIColor { color }
  var isTravelled: Bool { isVisited }
  var asLarge: Bool { false }
}

extension TKUIServiceViewModel.ServiceVisit: TKUIModeAnnotation {
  var title: String? { return visit.title }
  var subtitle: String? { return visit.subtitle }
  var coordinate: CLLocationCoordinate2D { return visit.coordinate }
  var modeInfo: TKModeInfo? { return visit.modeInfo }
  var clusterIdentifier: String? { return visit.clusterIdentifier }
}

extension TKUIServiceViewModel.ServiceVisit: TKUIIdentifiableAnnotation {
  var identity: String? { visit.stop.stopCode } // We assume you don't visit the same stop code again
}

// MARK: Embarkations

extension TKUIServiceViewModel {
  class ServiceEmbarkation: NSObject, MKAnnotation {
    enum Action {
      case embark
      case disembark
    }
    
    let visit: StopVisits
    let action: Action
    
    init?(visit: StopVisits?, action: Action) {
      guard let visit = visit else { return nil }
      self.visit = visit
      self.action = action
    }
    
    func triggerRealTimeKVO() {
      visit.triggerRealTimeKVO()
    }
    
    // MARK: - MKAnnotation
    
    var coordinate: CLLocationCoordinate2D { return visit.coordinate }

    // These shouldn't be necessary, but without it you might be getting
    // fatal crashes like the following in iOS 12:
    //
    // *** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<_TtCC12TripGoAppKit16ServiceViewModel18ServiceEmbarkation 0x28390dd00> valueForUndefinedKey:]: this class is not key value coding-compliant for the key subtitle.'
    let title: String? = nil
    let subtitle: String? = nil
  }
}

extension TKUIServiceViewModel.ServiceEmbarkation: TKUIModeAnnotation {
  var modeInfo: TKModeInfo? {
    return visit.modeInfo
  }
  
  var clusterIdentifier: String? {
    return nil
  }
}

extension TKUIServiceViewModel.ServiceEmbarkation: TKUISemaphoreDisplayable {
  var semaphoreMode: TKUISemaphoreView.Mode {
    switch (visit.timing, action) {
    case (.frequencyBased(let frequency, _, _, _), .embark):
      return .headWithFrequency(minutes: Int(frequency / 60))
    
    case (.timetabled(_, let departure), .embark) where departure != nil:
      return .headWithTime(departure!, visit.timeZone, isRealTime: visit.service.isRealTime)
      
    case (.timetabled(let arrival, let departure), .disembark) where arrival != nil || departure != nil:
      return .headWithTime(arrival ?? departure!, visit.timeZone, isRealTime: visit.service.isRealTime)
      
    default:
      return .headOnly
    }
  }
  
  var bearing: NSNumber? {
    switch action {
    case .embark: return visit.bearing
    case .disembark: return nil
    }
  }
  
  var isTerminal: Bool { return action == .disembark }
}
