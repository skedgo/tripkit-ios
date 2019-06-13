//
//  TKUIDeparturesViewModel+Content.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 20.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension TKUIDeparturesViewModel {
  
  public struct Section {
    let date: Date
    public var items: [Item]
    
    public var title: String {
      guard let timeZone = items.first?.dataModel.stop.region?.timeZone else { return "" }
      return TKStyleManager.dateString(date, for: timeZone)
    }
  }
  
  public struct Item {
    let dataModel: StopVisits
    public let contentModel: TKUIDepartureCardContentModel
    public let isSelected: Bool
  }

}

// MARK: - Building sections

extension TKUIDeparturesViewModel {
  
  static func fetchContent(for data: DataInput, input: UIInput?, errorPublisher: PublishSubject<Error>) -> Driver<[StopVisits]> {
    return fetchDepartures(for: data, input: input) // fetch in background
      .observeOn(MainScheduler.instance)
      .filter { result in
        switch result {
        case .addedDepartures, .addedDeparturesAndChildren:
          return true
        case .failed(let error):
          errorPublisher.onNext(error)
          return false
        }
      }
      .flatMapLatest { _ in TKUIDeparturesViewModel.departures(for: data, input: input) }
      .asDriver(onErrorRecover: { error in
        errorPublisher.onNext(error)
        return .empty()
      })
  }
  
  /// Retrieves the *already downloaded departures* for the requested data,
  /// potentially filtering by date or filter string.
  ///
  /// - Parameters:
  ///   - data: What data to retrieve
  ///   - input: How to filter the data
  /// - Returns: Observable of departures, firing depending on input
  private static func departures(for data: DataInput, input: UIInput?) -> Observable<[StopVisits]> {
    
    let relevantInput: Observable<(filter: String?, date: Date?)>
    
    let filterSteam = input?.filter
      .map { $0 as String? }
      .startWith(nil)
      .asObservable()
      ?? .just(nil)
    
    let dateStream = input?.date
      .map { $0 as Date? }
      .startWith(data.startDate)
      .asObservable()
      ?? .just(nil)
    
    relevantInput = Observable.combineLatest(filterSteam, dateStream) { (filter: $0, date: $1) }
    
    if let stops = data.stops, !stops.isEmpty {
      let stopLocations = self.stopLocations(for: stops)
      return relevantInput
        .flatMapLatest { TKUIDeparturesViewModel.stopVisits(for: stopLocations, filter: $0, date: $1) }
      
    } else if let dlsTable = data.dlsTable {
      return relevantInput
        .flatMapLatest { TKUIDeparturesViewModel.stopVisits(for: dlsTable.pairIdentifiers, date: $0.date) }
      
    } else {
      preconditionFailure("Need non-empty `stops` or `dlsTable`")
    }
  }
  
  private static func stopVisits(for stops: [StopLocation], filter: String?, date: Date?) -> Observable<[StopVisits]> {
    
    let earliestDate = date ?? Date(timeIntervalSinceNow: TimeInterval(-60 * Constants.minutesToFetchBeforeNow))
    
    let stopsToMatch = stops.flatMap { $0.stopsToMatchTo() }
    let predicate = StopVisits.departuresPredicate(forStops: stopsToMatch, from: earliestDate, filter: filter)
    
    return TripKit.shared.tripKitContext.rx.fetchObjects(
      StopVisits.self,
      sortDescriptors: StopVisits.defaultSortDescriptors(),
      predicate: predicate,
      relationshipKeyPathsForPrefetching: ["service"]
    )
  }
  
  private static func stopVisits(for pairs: Set<String>?, date: Date?) -> Observable<[StopVisits]> {
    guard let pairs = pairs else { return Observable.just([]) }
    
    
    let earliestDate = date ?? Date(timeIntervalSinceNow: TimeInterval(-60 * Constants.minutesToFetchBeforeNow))
    
    let predicate = DLSEntry.departuresPredicate(forPairs: pairs, from: earliestDate, filter: nil)
    
    return TripKit.shared.tripKitContext.rx
      .fetchObjects(
        DLSEntry.self,
        sortDescriptors: StopVisits.defaultSortDescriptors(),
        predicate: predicate,
        relationshipKeyPathsForPrefetching: ["service"]
      )
      .map { $0.map { $0 as StopVisits } }
  }
  
  static func buildSections(_ visits: [StopVisits], groupStops: Bool, selectedServiceID: String?) -> [Section] {
    let items = visits.compactMap { visit -> Item? in
      guard let contentModel = TKUIDepartureCardContentModel.build(for: visit) else { return nil }
      let selected = visit.service.code == selectedServiceID
      return Item(dataModel: visit, contentModel: contentModel, isSelected: selected)
    }
    
    let unknownDate = Date()
    let grouped = Dictionary(grouping: items) { $0.dataModel.regionDay ?? unknownDate }
    return grouped.map(Section.init).sorted { $0.date < $1.date }
  }
  
}
// MARK: - Updating + fetching content

extension TKUIDeparturesViewModel {
  
  private enum FetchResult {
    case addedDepartures
    case addedDeparturesAndChildren
    case failed(Error)
  }
  
  /// This fetches departures for the requested data (e.g., stops or DLS tables),
  /// and might clear the existing departures depending on the input.
  ///
  /// The observable will fire multiple times, starting with fetching the
  /// departures for "now"'" and then firing again according to `input`.
  ///
  /// - Parameters:
  ///   - data: What to fetch
  ///   - input: Reactive to input
  /// - Returns: Observable with fetch result, firing depending on input
  private static func fetchDepartures(for data: DataInput, input: UIInput?) -> Observable<FetchResult> {
    
    let relevantInput: Observable<(from: Date?, refresh: Bool)>
    
    // When pulling to refresh, rebuild and use last date.
    // No need to throttle or debounce.
    let refresh = input?.refresh
      .map { _ in (from: nil as Date?, refresh: true) }
      .asObservable()
      ?? .empty()
    
    // When scrolling to the bottom, load more items after that date.
    // Throttle in case minor scroll offsets call this again.
    let more = input?.loadMoreAfter
      .distinctUntilChanged()
      .filter { $0.dataModel.originalTime != nil }
      .map { after in (from: after.dataModel.originalTime, refresh: false) }
      .throttle(.milliseconds(500), latest: false)
      .asObservable()
      ?? .empty()
    
    // When changing the date, switch to that date a rebuild
    let date = input?.date
      .map { date in (from: date as Date?, refresh: true) }
      .debounce(.milliseconds(500))
      .asObservable()
      ?? .empty()
    
    
    // We start with a refresh. We could be smarter here, e.g., checking
    // first if we have data already and then don't fetch.
    
    relevantInput = Observable.merge(date, more, refresh)
      .startWith( (from: data.startDate, refresh: true) )
    
    if let stops = data.stops, !stops.isEmpty {
      let stopLocations = self.stopLocations(for: stops)
      
      return relevantInput
        .flatMapLatest { date, rebuild -> Observable<FetchResult> in
          if rebuild {
            stopLocations.forEach { $0.clearVisits() }
          }
          let downloadDate = date ?? Date(timeIntervalSinceNow: TimeInterval(-60 * Constants.minutesToFetchBeforeNow))
          return TKDeparturesProvider
            .downloadDepartures(for: stopLocations, fromDate: downloadDate, limit: Constants.departuresToFetch)
            .map { $0 ? .addedDeparturesAndChildren : .addedDepartures }
            .asObservable()
            .catchError { return .just(.failed($0)) }
      }
      
    } else if let dlsTable = data.dlsTable {
      
      return relevantInput
        .flatMapLatest { date, rebuild -> Observable<FetchResult> in
          if rebuild {
            DLSEntry.clearAllEntries(inTripKitContext: TripKit.shared.tripKitContext)
          }
          let downloadDate = date ?? Date(timeIntervalSinceNow: TimeInterval(-60 * Constants.minutesToFetchBeforeNow))
          return TKDeparturesProvider
            .downloadDepartures(for: dlsTable, fromDate: downloadDate, limit: Constants.departuresToFetch)
            .map { pairs in
              dlsTable.addPairIdentifiers(pairs)
              return .addedDepartures
            }
            .asObservable()
            .catchError { return .just(.failed($0)) }
      }
      
    } else {
      preconditionFailure("Need non-empty `stops` or `dlsTable`")
    }
    
  }
}


// MARK: - Real-time updates

extension TKUIDeparturesViewModel {
  
  static func fetchRealtimeUpdates(departures: Driver<[StopVisits]>) -> Observable<TKRealTimeUpdateProgress<Void>> {
    
    return Observable<Int>
      .interval(Constants.realTimeRefreshInterval, scheduler: MainScheduler.instance)
      .withLatestFrom(departures)
      .flatMapLatest { departures -> Observable<TKRealTimeUpdateProgress<Void>> in
        guard let region = departures.first?.stop.region else { return .empty() }
        return TKBuzzRealTime.rx
          .update(departures: departures, in: region)
          .map { _ in .updated(()) }
          .startWith(.updating)
      }
      .startWith(.idle)
  }
  
}

extension TKUIDeparturesViewModel {
  fileprivate enum FetchError: Error {
    case unknownError
  }
}

extension Reactive where Base: TKBuzzRealTime {
  
  static func update(departures: [StopVisits], in region: TKRegion) -> Observable<[StopVisits]> {
    
    let dlsEntries = departures.compactMap({ $0 as? DLSEntry })
    if !dlsEntries.isEmpty {
      return Observable.create { subscriber in
        TKBuzzRealTime.updateDLSEntries(
          Set(dlsEntries),
          in: region,
          success: { updatedDepartures in
            let asVisits = updatedDepartures.map { $0 as StopVisits }
            subscriber.onNext(asVisits)
            subscriber.onCompleted()
        }, failure: { error in
          if let error = error {
            subscriber.onError(error)
          } else {
            subscriber.onError(TKUIDeparturesViewModel.FetchError.unknownError)
          }
        })
        return Disposables.create()
      }
      
    } else {
      return Observable.create { subscriber in
        TKBuzzRealTime.updateEmbarkations(
          Set(departures),
          in: region,
          success: { updatedDepartures in
            subscriber.onNext(Array(updatedDepartures))
            // TODO: Shouldn't this complete? Turn into Single?
        }, failure: { error in
          if let error = error {
            subscriber.onError(error)
          } else {
            subscriber.onError(TKUIDeparturesViewModel.FetchError.unknownError)
          }
        })
        return Disposables.create()
      }
    }
    
  }
  
}


// MARK: - Alerts

extension TKUIDeparturesViewModel {
  
  static func buildAlerts(_ visits: [StopVisits]) -> [TKAlert] {
    
    var seenStopCodes = Set<String>()
    let stops = visits
      .map { $0.stop }
      .filter { seenStopCodes.insert($0.stopCode).inserted }
    
    var seenHashCodes = Set<Int>()
    let alerts = stops
      .flatMap { $0.alertsIncludingChildren }
      .filter { seenHashCodes.insert($0.hashCode.intValue).inserted }
      .map { $0 as TKAlert }
    
    return alerts
  }
  
}

extension StopLocation {
  
  fileprivate var alertsIncludingChildren: [Alert] {
    let childAlerts = children?.flatMap { $0.alertsIncludingChildren }
    return Alert.fetchAlerts(for: self) + (childAlerts ?? [])
  }
  
}


// MARK: - Selection

extension Array where Element == TKUIDeparturesViewModel.Section {
  var defaultSelection: TKUIDeparturesViewModel.Item? {
    for section in self {
      return section.items.first(where: { $0.isSelected })
    }
    return nil
  }
}



// MARK: - RxDataSources

extension TKUIDeparturesViewModel.Item: Equatable {
  
  public static func ==(lhs: TKUIDeparturesViewModel.Item, rhs: TKUIDeparturesViewModel.Item) -> Bool {
    return lhs.dataModel.objectID == rhs.dataModel.objectID
  }
  
}

extension TKUIDeparturesViewModel.Item: IdentifiableType {
  public typealias Identity = NSManagedObjectID
  
  public var identity: Identity {
    return dataModel.objectID
  }
}

extension TKUIDeparturesViewModel.Section: AnimatableSectionModelType {
  public typealias Item = TKUIDeparturesViewModel.Item
  public typealias Identity = Date
  
  public init(original: TKUIDeparturesViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity {
    return date
  }
}
