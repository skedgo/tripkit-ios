//
//  TKUITripOverviewViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxDataSources

extension TKUITripOverviewViewModel {
  
  func segment(for item: Item) -> TKSegment? {
    switch item {
    case .start, .end: return nil
    case .stationary(let item): return item.segment
    case .moving(let item): return item.segment
    }
  }
  
  struct Section {
    var header: String {
      // Sections are grouped by dates
      return ""
    }
    
    var items: [Item]
    
    fileprivate let index: Int
  }
  
  struct Line: Equatable {
    let color: UIColor?
  }
  
  enum Item: Equatable {
    case start(TerminalItem)
    case stationary(StationaryItem)
    case moving(MovingItem)
    case end(TerminalItem)
  }
  
  struct TerminalItem: Equatable {
    let title: String
    let subtitle: String?
    let connection: Line?
  }
  
  struct StationaryItem: Equatable {
    let title: String
    let subtitle: String?
    
    let time: Date?
    
    let topConnection: Line?
    let bottomConnection: Line?
    
    fileprivate let segment: TKSegment
  }
  
  struct MovingItem: Equatable {
    let title: String
    let notes: String?
    
    let icon: UIImage?
    let iconURL: URL?
    let iconIsTemplate: Bool
    
    let connection: Line?
    
    let action: SegmentAction?
    
    fileprivate let segment: TKSegment
  }
  
  enum SegmentAction {
    case addAlarm
    case removeAlarm
    case shareETA
  }
}

// MARK: - Creating sections

extension TKUITripOverviewViewModel {
  
  static func buildSections(for trip: Trip) -> [Section] {
    // TODO: Split by date
    
    let segments = trip
      .segments(with: .inDetails)
      .compactMap { $0 as? TKSegment }
    
    let items = segments
      .enumerated()
      .flatMap { (tuple) -> [TKUITripOverviewViewModel.Item] in
        let (index, current) = tuple
        let previous = index > 0 ? segments[index - 1] : nil
        let next = index + 1 < segments.count ? segments[index + 1]: nil
        return build(segment: current, previous: previous, next: next)
      }
    
    return [Section(items: items, index: 0)]
  }
  
  private static func build(segment: TKSegment, previous: TKSegment?, next: TKSegment?) -> [TKUITripOverviewViewModel.Item] {
    
    switch segment.order() {
    case .start:
      return [.start(TKUITripOverviewViewModel.TerminalItem(
        title: segment.title ?? "", subtitle: nil, connection: next?.line)
      )]
      
    case .end:
      return [.end(TKUITripOverviewViewModel.TerminalItem(
        title: segment.title ?? "", subtitle: nil, connection: previous?.line)
      )]
      
    case .regular:
      if segment.isStationary() {
        return [
          .stationary(segment.toStationary(previous: previous, next: next)),
        ]

      } else if let next = next, !next.isStationary() {
        return [
          .moving(segment.toMoving()),
          .stationary(segment.toStationaryBridge(to: next))
        ]
        
      } else {
        return [
          .moving(segment.toMoving()),
        ]
      }
    }
  }
  
}

fileprivate extension TKSegment {
  func toStationary(previous: TKSegment?, next: TKSegment?) -> TKUITripOverviewViewModel.StationaryItem {
    return TKUITripOverviewViewModel.StationaryItem(
      title: (start?.title ?? nil) ?? Loc.Location,
      subtitle: title,
      time: departureTime,
      topConnection: previous?.line,
      bottomConnection: next?.line,
      segment: self
    )
  }
  
  func toStationaryBridge(to next: TKSegment) -> TKUITripOverviewViewModel.StationaryItem {
    return TKUITripOverviewViewModel.StationaryItem(
      title: (next.start?.title ?? end?.title ?? nil) ?? Loc.Location,
      subtitle: nil,
      time: arrivalTime,
      topConnection: line,
      bottomConnection: next.line,
      segment: next // Since this is marking the start of "next", it makes most
                    // sense to display that when tapping on it.
    )
  }
  
  func toMoving() -> TKUITripOverviewViewModel.MovingItem {
    return TKUITripOverviewViewModel.MovingItem(
      title: title ?? "",
      notes: notes(),
      icon: (self as STKTripSegment).tripSegmentModeImage,
      iconURL: (self as STKTripSegment).tripSegmentModeImageURL,
      iconIsTemplate: (self as STKTripSegment).tripSegmentModeImageIsTemplate,
      connection: line,
      action: nil,
      segment: self
    )
  }
  
  var line: TKUITripOverviewViewModel.Line? {
    guard !isStationary() else { return nil }
    return TKUITripOverviewViewModel.Line(color: color())
  }
}

// MARK: - RxDataSource protocol conformance

extension TKUITripOverviewViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .start: return "Start"
    case .end: return "End"
    case .stationary(let item): return String(describing: item.segment.templateHashCode())
    case .moving(let item): return String(describing: item.segment.templateHashCode())
    }
  }
}

extension TKUITripOverviewViewModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUITripOverviewViewModel.Item
  
  init(original: TKUITripOverviewViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity {
    // Note: Can't just use the header (aka date) in case of funky
    // real-time issues where a later segment starts the previous day
    return header + "\(index)"
  }
}
