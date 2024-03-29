//
//  TKUITripOverviewViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift

import TripKit

extension TKUITripOverviewViewModel {
  
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
    case alert(AlertItem)
    case impossible(TKSegment, title: String)
  }
  
  struct TimeInfo: Equatable {
    let actualTime: Date
    var timetableTime: Date? = nil
  }
  
  struct TerminalItem: Equatable {
    static func == (lhs: TKUITripOverviewViewModel.TerminalItem, rhs: TKUITripOverviewViewModel.TerminalItem) -> Bool {
      // Check the segment, plus anything that can change with real-time data
      return lhs.segment.templateHashCode == rhs.segment.templateHashCode
          && lhs.time == rhs.time
    }
    
    let title: String
    let subtitle: String?

    let time: TimeInfo?
    let timeZone: TimeZone
    let timesAreFixed: Bool

    let connection: Line?
    let isStart: Bool

    let actions: [TKUICardAction<TKUITripOverviewCard, TKSegment>]
    let segment: TKSegment
  }
  
  struct StationaryItem: Equatable {
    static func == (lhs: TKUITripOverviewViewModel.StationaryItem, rhs: TKUITripOverviewViewModel.StationaryItem) -> Bool {
      // Check the segment, plus anything that can change with real-time data
      // Note: Platforms go into subtitles and can change in real-time, too
      return lhs.segment.templateHashCode == rhs.segment.templateHashCode
          && lhs.startTime == rhs.startTime
          && lhs.endTime == rhs.endTime
          && lhs.subtitle == rhs.subtitle
          && lhs.endSubtitle == rhs.endSubtitle
    }
    
    let title: String
    let subtitle: String?
    let endSubtitle: String?
    
    let startTime: TimeInfo?
    let endTime: TimeInfo?
    let timeZone: TimeZone
    let timesAreFixed: Bool
    let isContinuation: Bool

    let topConnection: Line?
    let bottomConnection: Line?
    
    let actions: [TKUICardAction<TKUITripOverviewCard, TKSegment>]
    let segment: TKSegment
  }
  
  struct MovingItem: Equatable {
    static func == (lhs: TKUITripOverviewViewModel.MovingItem, rhs: TKUITripOverviewViewModel.MovingItem) -> Bool {
      // Check the segment, plus anything that can change with real-time data
      return lhs.segment.templateHashCode == rhs.segment.templateHashCode
          && lhs.accessories == rhs.accessories
    }
    
    let title: String
    let notes: String?
    
    let icon: UIImage?
    let iconURL: URL?
    let iconIsTemplate: Bool
    let iconIsBranding: Bool
    
    let connection: Line?
    
    let actions: [TKUICardAction<TKUITripOverviewCard, TKSegment>]
    let accessories: [SegmentAccessory]
    let segment: TKSegment
  }
  
  struct AlertItem: Equatable {
    static func == (lhs: TKUITripOverviewViewModel.AlertItem, rhs: TKUITripOverviewViewModel.AlertItem) -> Bool {
      return lhs.segment.alerts == rhs.segment.alerts
    }
    
    var isCritical: Bool { alerts.first?.isCritical() ?? false }
    var connection: Line? = nil
    var alerts: [Alert] { segment.alerts }
    
    fileprivate let segment: TKSegment
  }
  
  enum SegmentAccessory: Equatable {
    case wheelchairAccessibility(TKWheelchairAccessibility)
    case bicycleAccessibility(TKBicycleAccessibility)
    case averageOccupancy(TKAPI.VehicleOccupancy, title: String)
    case carriageOccupancies([[TKAPI.VehicleOccupancy]])
    case pathFriendliness(TKSegment)
    case roadTags(TKSegment)
  }
}

extension TKUITripOverviewViewModel.Item {
  
  var segment: TKSegment? {
    switch self {
    case .terminal: return nil
    case .stationary(let item): return item.segment
    case .moving(let item): return item.segment
    case .alert(let item): return item.segment
    case .impossible(let segment, _): return segment
    }
  }
  
}

// MARK: - Creating sections

extension TKUITripOverviewViewModel {
  
  static func buildSections(for trip: Trip) -> [Section] {
    // TODO: Split by date
    
    let segments = trip.segments(with: .inDetails)
    let items = segments
      .enumerated()
      .flatMap { (tuple) -> [TKUITripOverviewViewModel.Item] in
        let (index, current) = tuple
        let previous = index > 0 ? segments[index - 1] : nil
        let next = index + 1 < segments.count ? segments[index + 1]: nil
        var items = build(segment: current, previous: previous, next: next)
        if current.isImpossible {
          // Makes most sense before the departure, so inject in beginning
          items.insert(.impossible(current, title: Loc.YouMightNotMakeThisTransfer), at: 0)
        }
        return items
      }
    
    return [Section(items: items, index: 0)]
  }
  
  private static func build(segment: TKSegment, previous: TKSegment?, next: TKSegment?) -> [TKUITripOverviewViewModel.Item] {
    
    switch segment.order {
    case .start, .end:
      return [
        .terminal(segment.toTerminal(previous: previous, next: next))
      ]
      
    case .regular:
      if segment.isStationary {
        return [
          .stationary(segment.toStationary(previous: previous, next: next)),
        ]

      } else if let next = next, !next.isStationary {
        var items: [TKUITripOverviewViewModel.Item] = [.moving(segment.toMoving())]
        
        if !segment.alerts.isEmpty {
          items.append(.alert(segment.toAlert()))
        }
        if segment.isCanceled {
          items.append(.impossible(segment, title: Loc.ServiceHasBeenChancelled))
        }
        
        items.append(.stationary(segment.toStationaryBridge(to: next)))
        return items
        
      } else {
        var items: [TKUITripOverviewViewModel.Item] = [.moving(segment.toMoving())]
        
        if !segment.alerts.isEmpty {
          items.append(.alert(segment.toAlert()))
        }
        if segment.isCanceled {
          items.append(.impossible(segment, title: Loc.ServiceHasBeenChancelled))
        }

        return items
      }
    }
  }
  
}

fileprivate extension TKSegment {
  /// - [xt] Add timetable start + end times to real-time segments
  /// - [xt] Add platforms to stationary segment
  /// - [xt] Remove platforms from moving segment
  /// - [xt] Remove all times except PT arrival/departure and ETA
  /// - [xt] Make sure terminal segments take name of stations if starting/ending at a station
  /// - [xt] Ignore simple 'wait' text
  /// - [x ] Make sure durations make sense and add up
  /// - [ ] Fix size of data attribution => @Brian
  /// - [xt] Test changing at a station/platform
  /// - [xt] Test continuation
  /// - [xt] Test impossible segment, due to time overlap
  /// - [xt] Test impossible segment, due to cancelled services]
  /// - [ ] Test frequency-based trip
  
  func platformInfo(previous: TKSegment? = nil, next: TKSegment?) -> (String?, String?) {
    
    func toPlatform(_ code: String) -> String? {
      // TODO: Instead tweak backend to provide these
      guard !code.isEmpty else { return nil }
      return code.count < 5 ? "Platform \(code)" : code
    }

    if isTerminal {
      if order == .start, let segment = next {
        return (segment.scheduledStartPlatform.flatMap(toPlatform), nil)
      } else if order == .end, let segment = previous {
        return (segment.scheduledEndPlatform.flatMap(toPlatform), nil)
      } else {
        return (nil, nil)
      }
      
    } else if type == .scheduled, !(next?.isContinuation == true) {
      // Scheduled to something that's not a continuation
      return (scheduledEndPlatform.flatMap(toPlatform), nil)
    
    } else if let next = next, next.type == .scheduled, !next.isContinuation {
      let endOfThis = scheduledEndPlatform.flatMap(toPlatform) ?? previous?.scheduledEndPlatform.flatMap(toPlatform)
      let startOfNext = next.scheduledStartPlatform.flatMap(toPlatform)
      return (endOfThis, startOfNext)
    
    } else {
      return (nil, nil)
    }
  }
  
  var departureTimeInfo: TKUITripOverviewViewModel.TimeInfo? {
    guard type == .scheduled else { return nil }
    return TKUITripOverviewViewModel.TimeInfo(actualTime: departureTime, timetableTime: self.scheduledTimetableStartTime)
  }
  
  var arrivalTimeInfo: TKUITripOverviewViewModel.TimeInfo? {
    guard type == .scheduled else { return nil }
    return TKUITripOverviewViewModel.TimeInfo(actualTime: arrivalTime, timetableTime: self.scheduledTimetableEndTime)
  }
  
  @MainActor
  func toTerminal(previous: TKSegment?, next: TKSegment?) -> TKUITripOverviewViewModel.TerminalItem {
    let isStart = order == .start
    let subtitle = platformInfo(previous: previous, next: next)
    
    return TKUITripOverviewViewModel.TerminalItem(
      title: titleWithoutTime ?? "",
      subtitle: subtitle.0 ?? subtitle.1,
      time: isStart ? next?.departureTimeInfo : previous?.arrivalTimeInfo,
      timeZone: timeZone,
      timesAreFixed: trip.departureTimeIsFixed,
      connection: (isStart ? next : previous)?.line,
      isStart: isStart,
      actions: TKUITripOverviewCard.config.segmentActionsfactory?(self) ?? [],
      segment: self
    )
  }
  
  /// Create a stationary item for a stationary segment
  @MainActor
  func toStationary(previous: TKSegment?, next: TKSegment?) -> TKUITripOverviewViewModel.StationaryItem {
    assert(isStationary)
    
    let platforms = platformInfo(previous: previous, next: next)
    var subtitle: String
    var endSubtitle: String?
    if stationaryType == .transfer, let previous = previous, previous.isPublicTransport {
      // We ignore the title provided by backend, but we guarantee we
      // show both dots by having both start and end
      subtitle = platforms.0 ?? ""
      endSubtitle = platforms.1 ?? ""
    
    } else {
      if stationaryType == .transfer {
        subtitle = "" // this is the departure, so ignore the "wait" information
      } else {
        subtitle = titleWithoutTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      }
      endSubtitle = nil
      
      if stationaryType == .wait {
        if !subtitle.isEmpty {
          subtitle.append(" · ")
        }
        subtitle.append(arrivalTime.durationSince(departureTime))
      }
      if let platform = platforms.0 ?? platforms.1 {
        if !subtitle.isEmpty {
          subtitle += "\n"
        }
        subtitle += platform
      }
    }
    
    return TKUITripOverviewViewModel.StationaryItem(
      title: (start?.title ?? nil) ?? Loc.Location,
      subtitle: subtitle,
      endSubtitle: endSubtitle,
      startTime: previous?.arrivalTimeInfo,
      endTime: next?.departureTimeInfo,
      timeZone: timeZone,
      timesAreFixed: trip.departureTimeIsFixed,
      isContinuation: false,
      topConnection: previous?.line,
      bottomConnection: next?.line,
      actions: TKUITripOverviewCard.config.segmentActionsfactory?(self) ?? [],
      segment: self
    )
  }
  
  /// Create a stationary item (bridge) for a non-stationary segment
  @MainActor
  func toStationaryBridge(to next: TKSegment) -> TKUITripOverviewViewModel.StationaryItem {
    assert(!isStationary && !next.isStationary)
    
    let subtitles = platformInfo(next: next)
    return TKUITripOverviewViewModel.StationaryItem(
      title: (next.start?.title ?? end?.title ?? nil) ?? Loc.Location,
      subtitle: subtitles.0 ?? subtitles.1,
      endSubtitle: nil,
      startTime: next.isContinuation ? nil : arrivalTimeInfo,
      endTime: next.isContinuation ? nil : next.departureTimeInfo,
      timeZone: timeZone,
      timesAreFixed: trip.departureTimeIsFixed,
      isContinuation: next.isContinuation,
      topConnection: line,
      bottomConnection: next.line,
      actions: [], // no actions for bridges
      segment: next.isContinuation ? self : next // Since this is marking the
                    // start of "next", it makes most sense to display that
                    // when tapping on it (unless it's a continuation)
    )
  }
  
  @MainActor
  func toAlert() -> TKUITripOverviewViewModel.AlertItem {
    return TKUITripOverviewViewModel.AlertItem(connection: line, segment: self)
  }
  
  @MainActor
  func toMoving() -> TKUITripOverviewViewModel.MovingItem {
    var accessories: [TKUITripOverviewViewModel.SegmentAccessory] = []
    
    let vehicle = realTimeVehicle
    let occupancies = vehicle?.components?.map { $0.map { $0.occupancy ?? .unknown } }
    if let occupancies = occupancies, occupancies.count > 1 {
      accessories.append(.carriageOccupancies(occupancies))
    } else if let occupancy = vehicle?.averageOccupancy {
      accessories.append(.averageOccupancy(occupancy.0, title: occupancy.title))
    }
    
    if let accessibility = wheelchairAccessibility, accessibility.showInUI() {
      accessories.append(.wheelchairAccessibility(accessibility))
    }
    
    if let accessibility = bicycleAccessibility, accessibility.showInUI() {
      accessories.append(.bicycleAccessibility(accessibility))
    }
    
    if canShowPathFriendliness {
      accessories.append(.pathFriendliness(self))
    }
    
    // Save to always add this as it'll only show if there's information
    accessories.append(.roadTags(self))
    
    return TKUITripOverviewViewModel.MovingItem(
      title: titleWithoutTime ?? "",
      notes: notesWithoutPlatforms,
      icon: isContinuation ? nil : tripSegmentModeImage,
      iconURL: isContinuation ? nil : tripSegmentModeImageURL,
      iconIsTemplate: tripSegmentModeImageIsTemplate,
      iconIsBranding: tripSegmentModeImageIsBranding,
      connection: line,
      actions: TKUITripOverviewCard.config.segmentActionsfactory?(self) ?? [],
      accessories: accessories,
      segment: self
    )
  }
  
  var line: TKUITripOverviewViewModel.Line? {
    guard !isStationary, !isWalking else { return nil }
    return TKUITripOverviewViewModel.Line(color: color)
  }
}

// MARK: - RxDataSource protocol conformance

extension TKUITripOverviewViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .terminal(let item): return item.isStart ? "Start" : "End"
    case .stationary(let item): return "stationary-item-hashCode:" + String(describing: item.segment.templateHashCode)
    case .moving(let item): return "moving-item-hashCode:" + String(describing: item.segment.templateHashCode)
    case .alert(let item): return "alert-item-hashCode:" + String(describing: item.segment.templateHashCode)
    case .impossible: return "Impossible"
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
