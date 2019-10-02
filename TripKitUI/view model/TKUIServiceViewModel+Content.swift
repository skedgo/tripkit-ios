//
//  TKUIServiceViewModel+Content.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxDataSources

extension TKUIServiceViewModel {
  
  /// Section in a table view
  public struct Section: Equatable {
    /// Items in this section
    public var items: [Item]
  }
  
  /// For individual cells in a table view, representing a stop along the
  /// route
  public struct Item: Equatable {
    let dataModel: StopVisits
    
    /// Title of the stop
    public let title: String
    
    /// Timing at this stop
    public let timing: TKServiceTiming
    
    /// Time zone of the stop
    public let timeZone: TimeZone
    
    /// Real-time satatus of the departure
    public let realTimeStatus: StopVisitRealTime
    
    /// Whether this stop is at or after disembarkation, and, optionally,
    /// at or before the disembarkation
    public let isVisited: Bool
    
    /// Colour of line to draw of the beginning of the cell to this stop
    public let topConnection: UIColor?
    
    /// Colour of line to draw from the stop to the end of the cell
    public let bottomConnection: UIColor?
  }
  
}

// MARK: - Creating sections

extension TKUIServiceViewModel {
  
  static func buildSections(for embarkation: StopVisits, disembarkation: StopVisits?) -> [Section] {
    
    let items = embarkation.service
      .visitsIncludingContinuation()
      .map { Item($0, embarkation: embarkation, disembarkation: disembarkation) }
    
    return [Section(items: items)]
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
  fileprivate init(_ visit: StopVisits, embarkation: StopVisits, disembarkation: StopVisits?) {
    
    var isVisited = visit.index.intValue >= embarkation.index.intValue
    if let disembarkation = disembarkation, isVisited {
      isVisited = visit.index.intValue <= disembarkation.index.intValue
    }
    
    // TODO: Also make nil if there's nothing before of after this service
    let serviceColor = (visit.service.color as? UIColor) ?? .black
    
    let sortedVisits = visit.service.visitsIncludingContinuation()
    
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
      title: visit.stop.title ?? visit.stop.stopCode,
      timing: visit.timing,
      timeZone: visit.timeZone,
      realTimeStatus: visit.realTimeStatus(),
      isVisited: isVisited,
      topConnection: topConnectionColor,
      bottomConnection: bottomConnectionColor
    )
  }
}

// MARK: - RxDataSource protocol conformance

extension TKUIServiceViewModel.Item: IdentifiableType {
  public typealias Identity = String
  public var identity: Identity {
    return dataModel.objectID.uriRepresentation().absoluteString
  }
}

extension TKUIServiceViewModel.Section: AnimatableSectionModelType {
  public typealias Identity = String
  public typealias Item = TKUIServiceViewModel.Item
  
  public init(original: TKUIServiceViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity {
    return "single-section"
  }
}
