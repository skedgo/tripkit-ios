//
//  TKUIServiceViewModel+MapContent.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 20.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public protocol ServiceMapContentVisited {
  var isVisited: Bool { get }
}

extension TKUIServiceViewModel {
  
  /// All the content to display about a service on a map
  public struct MapContent {
    
    /// Time point representing the embarkation
    public let embarkation: TKUISemaphoreDisplayable
    
    /// Time point representing the disembarkation
    public let disembarkation: TKUISemaphoreDisplayable?
    
    /// Shapes to draw representing the route that the service takes, with
    /// colour according to whether it is travelled or not
    public let shapes: [TKDisplayableRoute]
    
    /// All stops along the route
    public let stops: [TKUIModeAnnotation & ServiceMapContentVisited]
    
    /// Annotations for vehicles servicing the route
    ///
    /// - note: These are dynamic and change with real-time information
    public let vehicles: [MKAnnotation]
  }
  
}

// MARK: - Creating map content

extension TKUIServiceViewModel {
  
  static func buildMapContent(for embarkation: StopVisits, disembarkation: StopVisits?) -> MapContent? {
    
    let service = embarkation.service
    let shapes = service.includingContinuations
      .flatMap { $0.shapes(forEmbarkation: embarkation, disembarkingAt: disembarkation) }
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
  func findStop(_ item: TKUIServiceViewModel.Item) -> MKAnnotation? {
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

    init(visit: StopVisits, embarkation: StopVisits, disembarkation: StopVisits?) {
      self.visit = visit
      
      if visit.compare(embarkation) == .orderedAscending {
        isVisited = false
      } else if let disembarkation = disembarkation, visit.compare(disembarkation) == .orderedDescending {
        isVisited = false
      } else {
        isVisited = true
      }
    }
  }
}

extension TKUIServiceViewModel.ServiceVisit: ServiceMapContentVisited {}

extension TKUIServiceViewModel.ServiceVisit: TKUIModeAnnotation {
  var title: String? { return visit.title }
  var subtitle: String? { return visit.subtitle }
  var coordinate: CLLocationCoordinate2D { return visit.coordinate }
  var modeInfo: TKModeInfo! { return visit.modeInfo }
  var clusterIdentifier: String? { return visit.clusterIdentifier}
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
  var modeInfo: TKModeInfo! {
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
  
  var canFlipImage: Bool { return visit.canFlipImage }
  var isTerminal: Bool { return action == .disembark }
  var selectionIdentifier: String? { return visit.selectionIdentifier }
}
