//
//  TKUITripOverviewCardModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxDataSources

#if TK_NO_MODULE
#else
  import TripKit
#endif

class TKUITripOverviewCardModel {
  
  let trip: Trip
  
  init(trip: Trip) {
    self.trip = trip
  }
  
  
  struct Section {
    var header: String {
      // Sections are grouped by dates
      return items.first?.start.description ?? ""
    }
    
    var items: [SegmentOverview]

    fileprivate let index: Int
  }
  
  struct SegmentOverview {
    let start: Date
    let title: String
    let subtitle: String?
    
    let icon: UIImage?
    let iconURL: URL?
    
    let action: SegmentAction?
    
    fileprivate let index: Int
  }
  
  enum SegmentAction {
    case addAlarm
    case removeAlarm
    case shareETA
  }
  
  lazy var sections: Observable<[Section]> = {
    Observable.just(TKUITripOverviewCardModel.constructSections(for: self.trip))
  }()
  
  func segment(for overview: SegmentOverview) -> TKSegment {
    return trip.segments()[overview.index]
  }
  
}

// MARK: - Creating sections

fileprivate extension TKUITripOverviewCardModel {
  
  static func constructSections(for trip: Trip) -> [Section] {
    // TODO: Split by date
    let segments = trip.segments().enumerated()
      .map { TKUITripOverviewCardModel.SegmentOverview(segment: $1, index: $0) }
    
    return [Section(items: segments, index: 0)]
  }
  
}

fileprivate extension TKUITripOverviewCardModel.SegmentOverview {
  
  init(segment: TKSegment, index: Int) {
    self.init(
      start: segment.departureTime,
      title: segment.title ?? "",
      subtitle: segment.subtitle,
      icon: (segment as STKTripSegment).tripSegmentModeImage,
      iconURL: (segment as STKTripSegment).tripSegmentModeImageURL,
      action: nil,
      index: index
    )
  }
  
}

// MARK: - RxDataSource protocol conformance

func ==(lhs: TKUITripOverviewCardModel.SegmentOverview, rhs: TKUITripOverviewCardModel.SegmentOverview) -> Bool {
  guard lhs.title     == rhs.title      else { return false }
  guard lhs.subtitle  == rhs.subtitle   else { return false }
  guard lhs.start     == rhs.start      else { return false }
  return true
}
extension TKUITripOverviewCardModel.SegmentOverview: Equatable {
}

extension TKUITripOverviewCardModel.SegmentOverview: IdentifiableType {
  typealias Identity = Int
  var identity: Identity {
    return index
  }
}

extension TKUITripOverviewCardModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUITripOverviewCardModel.SegmentOverview
  
  init(original: TKUITripOverviewCardModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity {
    // Note: Can't just use the header (aka date) in case of funky
    // real-time issues where a later segment starts the previous day
    return header + "\(index)"
  }
}



