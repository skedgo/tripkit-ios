//
//  TKUIDeparturesViewModel.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 01.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreSpotlight

import RxSwift
import RxCocoa

/// View model for displaying and interacting with public
/// transport departures from an stop (or list thereof).
public class TKUIDeparturesViewModel: NSObject {
  
  enum Constants {
    static let minutesToFetchBeforeNow = 15
    static let departuresToFetch = 50
    static let realTimeRefreshInterval: DispatchTimeInterval = .seconds(30)
  }
  
  typealias DataInput = (
    stops: [TKUIStopAnnotation]?,
    dlsTable: TKDLSTable?,
    startDate: Date?,
    selectedServiceID: String?,
    groupStops: Bool
  )
  
  public typealias UIInput = (
    selected: Signal<Item>,
    showAlerts: Signal<Item>,
    filter: Driver<String>,
    date: Driver<Date>,
    refresh: Signal<Void>,
    loadMoreAfter: Signal<Item>
  )
  
  public convenience init(restoredState: RestorableState, input: UIInput) {
    self.init(data: (stops: restoredState.stops, dlsTable: nil, startDate: nil, selectedServiceID: nil, groupStops: restoredState.groupStops), input: input)
  }

  public convenience init(stops: [TKUIStopAnnotation], groupStops: Bool = false, input: UIInput?) {
    self.init(data: (stops: stops, dlsTable: nil, startDate: nil, selectedServiceID:nil, groupStops: groupStops), input: input)
  }
  
  public convenience init(dlsTable: TKDLSTable, startDate: Date?, selectedServiceID: String? = nil, input: UIInput?) {
    self.init(data: (stops: nil, dlsTable: dlsTable, startDate: startDate, selectedServiceID: selectedServiceID, groupStops: false), input: input)
  }
  
  private init(data: DataInput, input: UIInput?) {
    departureStops = data.stops ?? []
    startDate = data.startDate
    restorationState = RestorableState(dataInput: data)
    
    let timeZone = TKUIDeparturesViewModel.timeZone(from: data)
    self.timeZone = timeZone

    let errorPublisher = PublishSubject<Error>()

    let departures = TKUIDeparturesViewModel.fetchContent(for: data, input: input, errorPublisher: errorPublisher)
    
    lines = departures.map(TKUIDeparturesViewModel.extractLines)

    sections = departures
      .map { TKUIDeparturesViewModel.buildSections($0, groupStops: data.groupStops, selectedServiceID: data.selectedServiceID) }
    
    let selection = (input?.selected ?? .empty()).startOptional() // default selection
    selectedItem = Observable.combineLatest(selection.asObservable(), sections.asObservable()) { $0 ?? $1.defaultSelection }
      .distinctUntilChanged() // Don't re-select when updating as we'd scroll again
      .asDriver(onErrorDriveWith: .empty())

    embarkationStopAlerts = departures
      .map(TKUIDeparturesViewModel.buildAlerts)
      .distinctUntilChanged { $0.count == $1.count }
    
    time = (input?.date ?? .empty())
      .startWith(Date())
    
    timeTitle = (input?.date ?? .empty())
      .map { TKStyleManager.timeString($0, for: timeZone) }
      .startWith(Loc.Now)
    
    titles = Driver.just(TKUIDeparturesViewModel.titles(from: data))
    
    realTimeUpdate = TKUIDeparturesViewModel.fetchRealtimeUpdates(departures: departures)
      .asDriver(onErrorRecover: { error in
        errorPublisher.onNext(error)
        return .empty()
      })

    error = errorPublisher.asSignal { .just($0) }
    
    // Navigation
    
    let showDepartures = input?.selected
      .map { $0.dataModel }
      .map { Next.departure($0) }
    
    let showAlerts = input?.showAlerts
      .map { $0.dataModel.service.allAlerts() }
      .map { Next.alerts($0) }
    
    next = Signal.merge(showDepartures ?? .empty(), showAlerts ?? .empty())
  }
  
  public let departureStops: [TKUIStopAnnotation]
  
  private let restorationState: RestorableState?
  
  private let startDate: Date?
  
  public let timeZone: TimeZone
  
  public let titles: Driver<(title: String, subtitle: String?)>
  
  public let time: Driver<Date>
  
  public let timeTitle: Driver<String>
  
  let lines: Driver<[TKUIDeparturesAccessoryView.Line]>
    
  public let sections: Driver<[Section]>
  
  public let selectedItem: Driver<Item?>

  public let embarkationStopAlerts: Driver<[TKAlert]>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  public let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  /// User-relevant errors, e.g., if departures couldn't get downloaded
  public let error: Signal<Error>
  
  // Actions to take
  
  public let next: Signal<Next>
}

// MARK: - Navigation

extension TKUIDeparturesViewModel {
  
  public enum Next {
    case departure(StopVisits)
    case alerts([TKAlert])
  }
  
}

// MARK: - Scrolling to base date

extension TKUIDeparturesViewModel {

  public func topIndexPath(in sections: [Section]) -> IndexPath? {
    let targetTimeInterval: TimeInterval
    if let start = startDate {
      targetTimeInterval = start.timeIntervalSinceNow
    } else {
      targetTimeInterval = -30
    }
      
    for (s, section) in sections.enumerated() {
      for (i, item) in section.items.enumerated() {
        if item.contentModel.approximateTimeToDepart?.timeIntervalSinceNow ?? -60 > targetTimeInterval {
          return IndexPath(item: i, section: s)
        }
      }
    }
    return nil
  }
  
}

// MARK: - Sharing

extension TKUIDeparturesViewModel {
  
  public func stopVisits(for items: [Item]) -> [StopVisits] {
    return items.map { $0.dataModel }
  }
  
}

// MARK: - Input conversion

extension TKUIDeparturesViewModel {
  
  static func timeZone(from data: DataInput) -> TimeZone {
    if let stops = data.stops, let first = stops.first {
      return TKRegionManager.shared.timeZone(for: first.coordinate) ?? .current
      
    } else if let dlsTable = data.dlsTable {
      return dlsTable.startRegion.timeZone
      
    } else {
      return .current
    }
  }
  
  static func titles(from data: DataInput) -> (title: String, subtitle: String?) {
    if let stops = data.stops, let first = stops.first {
      let title = (first.title ?? nil) ?? Loc.Timetable
      var subtitle: String? = nil
      if let more = Loc.More(count:stops.count - 1) {
        subtitle = "+ \(more)"
      }
      return (title, subtitle)
      
    } else {
      return (title: Loc.Timetable, subtitle: nil)
    }
  }
  
  static func stopLocations(for stops: [TKUIStopAnnotation]) -> [StopLocation] {
    return stops.map(StopLocation.from)
  }

}

extension StopLocation {
  
  fileprivate static func from(_ stop: TKUIStopAnnotation) -> StopLocation {
    if let stopLocation = stop as? StopLocation {
      return stopLocation
    } else {
      return StopLocation.fetchOrInsertStop(
        forStopCode: stop.stopCode,
        modeInfo: stop.modeInfo,
        atLocation: TKNamedCoordinate.namedCoordinate(for: stop),
        intoTripKitContext: TripKit.shared.tripKitContext
      )
    }
  }
  
}


// MARK: - User activity

extension TKUIDeparturesViewModel {
  static let typeIdentifier = "com.buzzhives.TripPlanner.showStopTimeTable"
  
  private func urlForUserActivity() -> URL? {
    guard
      TKShareHelper.enableSharingOfURLs,
      let stop = restorationState?.stops?.first, // minor hack
      let region = stop.regions.first
      else { return nil } // minor hack
    
    return TKShareHelper.createStopURL(stopCode: stop.stopCode, inRegionNamed: region.name, filter: nil)
  }

  public func updateUserActivityState(_ activity: NSUserActivity) {
    guard let url = urlForUserActivity() else { return }
    activity.addUserInfoEntries(from: ["stopTimeTableURL": url])
  }
  
  public func buildUserActivity() -> NSUserActivity? {
    guard
      let stop = restorationState?.stops?.first, // minor hack
      let url = urlForUserActivity()
      else { return nil }
    
    let title = stop.title ?? Loc.Timetable

    let activity = NSUserActivity(activityType: TKUIDeparturesViewModel.typeIdentifier)
    activity.title = title
    activity.webpageURL = url
    activity.userInfo = ["stopTimeTableURL": url]
    activity.requiredUserInfoKeys = ["stopTimeTableURL"]

    let attributeSet = CSSearchableItemAttributeSet(itemContentType: TKUIDeparturesViewModel.typeIdentifier)
    attributeSet.title = title
    if let image = stop.glyphImage {
      attributeSet.thumbnailData = image.pngData()
    }
    activity.contentAttributeSet = attributeSet
    
    activity.isEligibleForSearch = true
    activity.isEligibleForHandoff = true
    activity.isEligibleForPublicIndexing = true
    
    return activity
  }
}

// MARK: - State restoration

extension TKUIDeparturesViewModel {
  public struct RestorableState: Codable {
    let stops: [TKStopCoordinate]?
    let groupStops: Bool
    
    // LATER: We should also handle StopLocation by saving the persistentID and then
    // loading those again, as this is used when coming from the MxM screens
    // though those currently don't restore anyway.
    // We'd then call StopLocation(fromPersistentId: $0, in: TripKit.shared.context)
    // When this is done, also fix up `init?(dataInput: TKUIDeparturesViewModel.DataInput)`
  }

  public func save() throws -> Data {
    return try JSONEncoder().encode(restorationState)
  }
  
  public static func restoredState(from data: Data) -> RestorableState? {
    let state = try? JSONDecoder().decode(RestorableState.self, from: data)
    if let stops = state?.stops, !stops.isEmpty {
      return state
    } else {
      return nil
    }
  }
}


extension TKUIDeparturesViewModel.RestorableState {
  init?(dataInput: TKUIDeparturesViewModel.DataInput) {
    
    // LATER: When we restore also StopLocations, then we should handle this here, too.
    // When we do this, we can make this non-failable again.
    guard let stops = dataInput.stops?.compactMap({ $0 as? TKStopCoordinate }), !stops.isEmpty else {
      return nil
    }
    
    self.init(stops: stops, groupStops: dataInput.groupStops)
  }
}
