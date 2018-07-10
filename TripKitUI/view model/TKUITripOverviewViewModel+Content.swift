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
    case .terminal: return nil
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
    case terminal(TerminalItem)
    case stationary(StationaryItem)
    case moving(MovingItem)
  }
  
  struct TerminalItem: Equatable {
    let title: String
    let subtitle: String?

    let time: Date?
    let timeZone: TimeZone
    
    let connection: Line?
    let isStart: Bool
  }
  
  struct StationaryItem: Equatable {
    let title: String
    let subtitle: String?
    
    let time: Date?
    let timeZone: TimeZone
    
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
    
    let accessories: [SegmentAccessory]
    
    fileprivate let segment: TKSegment
  }
  
  enum SegmentAccessory: Equatable {
    case wheelchairFriendly
    case averageOccupancy(API.VehicleOccupancy)
    case carriageOccupancies([[API.VehicleOccupancy]])
    case pathFriendliness(TKSegment)
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
    case .start, .end:
      return [
        .terminal(segment.toTerminal(previous: previous, next: next))
      ]
      
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
  func toTerminal(previous: TKSegment?, next: TKSegment?) -> TKUITripOverviewViewModel.TerminalItem {
    let isStart = order() == .start
    return TKUITripOverviewViewModel.TerminalItem(
      title: titleWithoutTime,
      subtitle: nil,
      time: time,
      timeZone: timeZone,
      connection: (isStart ? next : previous)?.line,
      isStart: isStart
    )
  }
  
  func toStationary(previous: TKSegment?, next: TKSegment?) -> TKUITripOverviewViewModel.StationaryItem {
    return TKUITripOverviewViewModel.StationaryItem(
      title: (start?.title ?? nil) ?? Loc.Location,
      subtitle: titleWithoutTime,
      time: departureTime,
      timeZone: timeZone,
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
      timeZone: timeZone,
      topConnection: line,
      bottomConnection: next.line,
      segment: next // Since this is marking the start of "next", it makes most
                    // sense to display that when tapping on it.
    )
  }
  
  func toMoving() -> TKUITripOverviewViewModel.MovingItem {
    var accessories: [TKUITripOverviewViewModel.SegmentAccessory] = []
    
    let vehicle = realTimeVehicle()
    let occupancies = vehicle?.components?.map { $0.map { $0.occupancy ?? .unknown } }
    if let occupancies = occupancies, occupancies.count > 1 {
      accessories.append(.carriageOccupancies(occupancies))
    } else if let occupancy = vehicle?.averageOccupancy, occupancy != .unknown {
      accessories.append(.averageOccupancy(occupancy))
    }
    
    if let accessible = reference?.isWheelchairAccessible, accessible && TKUserProfileHelper.showWheelchairInformation {
      accessories.append(.wheelchairFriendly)
    }
    
    if canShowPathFriendliness {
      accessories.append(.pathFriendliness(self))
    }
    
    return TKUITripOverviewViewModel.MovingItem(
      title: titleWithoutTime,
      notes: notes(),
      icon: (self as TKTripSegment).tripSegmentModeImage,
      iconURL: (self as TKTripSegment).tripSegmentModeImageURL,
      iconIsTemplate: (self as TKTripSegment).tripSegmentModeImageIsTemplate,
      connection: line,
      action: nil,
      accessories: accessories,
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
    case .terminal(let item): return item.isStart ? "Start" : "End"
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
