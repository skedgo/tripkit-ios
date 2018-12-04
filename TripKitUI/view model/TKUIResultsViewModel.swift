//
//  TKUIResultsViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

#if TK_NO_MODULE
#else
  import TripKit
#endif

public class TKUIResultsViewModel {
  
  public typealias UIInput = (
    selected: Driver<Item>, // => do .next
    tappedDate: Driver<Void>, // => return which date to show
    tappedShowModes: Driver<Void>, // => return which modes to show
    tappedMapRoute: Driver<MapRouteItem>,
    changedDate: Driver<RouteBuilder.Time>, // => update request + title
    changedModes: Driver<Void>, // => update request
    changedSortOrder: Driver<TKTripCostType>, // => update sorting
    droppedPin: Driver<CLLocationCoordinate2D> // => call dropPin()
  )
  
  /// An item to be displayed on the map
  public struct MapRouteItem {
    fileprivate let trip: Trip
    
    public let polylines: [TKRoutePolyline]
    
    init(_ trip: Trip) {
      self.trip = trip
      
      let displayableRoutes = trip.segments(with: .onMap)
        .compactMap { ($0 as? TKSegment)?.shapes() }   // Only include those with shapes
        .flatMap { $0.filter { $0.routeIsTravelled } } // Flat list of travelled shapes
      polylines = displayableRoutes.compactMap(TKRoutePolyline.init)
    }
  }
  
  public struct RouteBuilder: Codable {
    fileprivate enum SelectionMode: String, Equatable, Codable {
      case origin
      case destination
    }
    
    public enum Time: Equatable, Codable {
      private enum CodingKeys: String, CodingKey {
        case type
        case date
      }
      
      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let date = try? container.decode(Date.self, forKey: .date)
        switch (type, date) {
        case ("leaveAfter", .some(let date)): self = .leaveAfter(date)
        case ("arriveBefore", .some(let date)): self = .arriveBefore(date)
        default: self = .leaveASAP
        }
      }
      
      public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .leaveASAP:
          try container.encode("leaveASAP", forKey: .type)
        case .leaveAfter(let date):
          try container.encode("leaveAfter", forKey: .type)
          try container.encode(date, forKey: .date)
        case .arriveBefore(let date):
          try container.encode("arriveBefore", forKey: .type)
          try container.encode(date, forKey: .date)
        }
      }
      
      case leaveASAP
      case leaveAfter(Date)
      case arriveBefore(Date)
    }
    
    fileprivate var mode: SelectionMode
    fileprivate var origin: TKNamedCoordinate?
    fileprivate var destination: TKNamedCoordinate?
    fileprivate var time: Time
    
    fileprivate static var empty = RouteBuilder(mode: .destination, origin: nil, destination: nil, time: .leaveASAP)
  }
  
  public convenience init(destination: MKAnnotation, inputs: UIInput) {
    let builder = RouteBuilder(mode: .origin, origin: nil, destination: TKNamedCoordinate.namedCoordinate(for: destination), time: .leaveASAP)
    self.init(builder: builder, inputs: inputs)
  }
  
  public convenience init(request: TripRequest, inputs: UIInput) {
    self.init(builder: request.builder, initialRequest: request, inputs: inputs)
  }
  
  private init(builder: RouteBuilder, initialRequest: TripRequest? = nil, inputs: UIInput) {
    let builderChanged = TKUIResultsViewModel.watch(builder, inputs: inputs)
    
    let errorPublisher = PublishSubject<Error>()
    self.error = errorPublisher.asDriver(onErrorDriveWith: Driver.empty())
    
    // Monitor the builder's annotation's coordinates
    let originOrDestinationChanged = builderChanged
      .flatMapLatest(TKUIResultsViewModel.locationsChanged)
    
    // Whenever the builder is changing, i.e., when the user changes the inputs,
    // we generate a new request.
    let requestChanged = Driver.merge(originOrDestinationChanged, builderChanged)
      .map { $0.generateRequest() }
      .filter { $0 != nil }
      .startWith(initialRequest)
    
    let tripGroupsChanged = TKUIResultsViewModel.fetchTripGroups(requestChanged)
    
    request = requestChanged
      .filter { $0 != nil }
      .map { $0! }
    
    fetchProgress = TKUIResultsViewModel.fetch(for: requestChanged, errorPublisher: errorPublisher)
    
    realTimeUpdate = TKUIResultsViewModel.fetchRealTimeUpdates(for: tripGroupsChanged)
    
    sections = TKUIResultsViewModel.buildSections(tripGroupsChanged, inputs: inputs)
    
    selectedItem = inputs.tappedMapRoute
      .startWithOptional(nil) // default selection
      .withLatestFrom(sections) { $1.find($0) ?? $1.bestItem }
    
    titles = builderChanged
      .map { $0.titles }
    
    timeTitle = requestChanged
      .filter { $0 != nil }
      .map { $0!.timeString }
    
    includedTransportModes = requestChanged
      .map { $0?.includedTransportModes }
    
    originAnnotation = builderChanged
      .map { $0.origin }
      .distinctUntilChanged { $0 === $1 }

    destinationAnnotation = builderChanged
      .map { $0.destination }
      .distinctUntilChanged { $0 === $1 }
    
    mapRoutes = Driver.combineLatest(tripGroupsChanged, inputs.tappedMapRoute.startWithOptional(nil))
      .map { groups, selection in
        let routeItems = groups.compactMap { $0.preferredRoute }
        let selectedTripGroup = selection?.trip.tripGroup
          ?? groups.first?.request.preferredGroup
          ?? groups.first
        let selectedItem = routeItems.first {$0.trip.tripGroup == selectedTripGroup }
        return (routeItems, selectedItem)
      }

    // Navigation
    
    let showTrip = inputs.selected
      .filter { $0.trip != nil }
      .map { Next.showTrip($0.trip!) }
    
    let modeInput = Driver.combineLatest(requestChanged, builderChanged)
    let presentModes = inputs.tappedShowModes
      .withLatestFrom(modeInput) { (_, tuple) -> Next in
        let modes = tuple.0?.applicableModeIdentifiers() ?? []
        let region = TKUIResultsViewModel.regionForModes(for: tuple.1)
        return Next.presentModes(modes: modes, region: region)
    }
    
    let presentTime = inputs.tappedDate
      .withLatestFrom(builderChanged)
      .map { Next.presentDatePicker(time: $0.time, timeZone: $0.timeZone) }
    
    next = Driver.merge(showTrip, presentTime, presentModes)
  }
  
  let request: Driver<TripRequest>
  
  let titles: Driver<(title: String, subtitle: String?)>
  
  let timeTitle: Driver<String>
  
  /// Indicates the number of active transport modes
  let includedTransportModes: Driver<String?>
  
  /// The sections to be displayed in a table view.
  ///
  /// Compatible with RxDataSource's RxTableViewSectionedAnimatedDataSource and
  /// ideally isn't used directly but just in combination with said data source.
  ///
  /// Example:
  ///
  /// ```swift
  /// let dataSource = RxTableViewSectionedAnimatedDataSource<ResultSection>()
  /// dataSource.configureCell = { ... }
  /// viewModel.sections
  ///   .bindTo(tableView.rx.items(dataSource: dataSource))
  ///   .disposed(by: disposeBag)
  /// ```
  let sections: Driver<[Section]>
  
  let selectedItem: Driver<Item?>
  
  /// Progress of fetching the routing results
  ///
  /// - warning: Subscribe to this, otherwise you won't get any results at all.
  let fetchProgress: Driver<TKResultsFetcher.Progress>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  public let realTimeUpdate: Driver<TKRealTimeUpdateProgress>
  
  let error: Driver<Error>
  
  public let originAnnotation: Driver<MKAnnotation?>

  public let destinationAnnotation: Driver<MKAnnotation?>
  
  public let mapRoutes: Driver<([MapRouteItem], selection: MapRouteItem?)>
  
  let next: Driver<Next>
}

// MARK: - Navigation

extension TKUIResultsViewModel {
  enum Next {
    case showTrip(Trip)
    case presentModes(modes: [String], region: TKRegion)
    case presentDatePicker(time: RouteBuilder.Time, timeZone: TimeZone)
  }
}

// MARK: - Builder

extension TKUIResultsViewModel {
  
  static func watch(_ initial: RouteBuilder, inputs: UIInput) -> Driver<RouteBuilder> {
    
    typealias BuilderInput = (date: RouteBuilder.Time?, pin: CLLocationCoordinate2D?, forceRefresh: Bool)
    
    // TODO: When pulling to refresh, rebuild
    // When changing modes, force refresh
    let refresh: Driver<BuilderInput> = inputs.changedModes
      .map { (date: nil, pin: nil, forceRefresh: true) }
    
    // When changing date, switch to that date
    let date: Driver<BuilderInput> = inputs.changedDate
      .map { (date: $0, pin: nil, forceRefresh: false) }
    
    // When dropping pin, set it
    let pin: Driver<BuilderInput> = inputs.droppedPin
      .map { (date: nil, pin: $0, forceRefresh: false) }
    
    let relevantInput = Driver.merge(date, pin, refresh)
    
    return relevantInput
      .scan(initial) { previous, change in
        var updated = previous
        if let time = change.date {
          updated.time = time
        }
        if let pin = change.pin {
          updated.dropPin(at: pin)
        }
        return updated
      }
      .distinctUntilChanged()
      .startWith(initial)
  }
  
  static func locationsChanged(in builder: RouteBuilder) -> Driver<RouteBuilder> {
    // This looks fairly complicated but all it does is monitoring the builder's
    // origin and destination annotations for changes to their coordinates, and
    // then triggers a rebuild.
    var origin: Observable<CLLocationCoordinate2D?> = Observable.empty()
    var destination: Observable<CLLocationCoordinate2D?> = Observable.empty()
    if let asObject = builder.origin {
      origin = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    if let asObject = builder.destination {
      destination = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    return Observable.merge(origin, destination)
      .map { _ in builder }
      .asDriver(onErrorDriveWith: Driver.empty())
  }
  
}

extension TKUIResultsViewModel.RouteBuilder {
  
  mutating func dropPin(at coordinate: CLLocationCoordinate2D) {
    let annotation = TKNamedCoordinate(coordinate: coordinate)
    
    switch mode {
    case .origin:
      annotation.title = "Origin"
      origin = annotation
      mode = .destination
    case .destination:
      annotation.title = "Destination"
      destination = annotation
      mode = .origin
    }
  }
  
}

// MARK: - Fetching routes

extension TKUIResultsViewModel {
  
  static func fetch(for request: Driver<TripRequest?>, errorPublisher: PublishSubject<Error>) -> Driver<TKResultsFetcher.Progress> {
    return request
      .filter { $0 != nil }
      .map { $0! }
      .distinctUntilChanged()
      .filter { $0.managedObjectContext != nil }
      .flatMapLatest { request in
        // Fetch the trip and handle errors in here, to not abort the outer observable
        return TKResultsFetcher
          .streamTrips(for: request, classifier: TKMetricClassifier())
          .asDriver(onErrorRecover: { error in
            errorPublisher.onNext(error)
            return Driver.just(.finished)
          })
    }
  }
  
}


// MARK: - Real-time updates

extension TKUIResultsViewModel {
  
  static func fetchRealTimeUpdates(for tripGroups: Driver<[TripGroup]>) -> Driver<TKRealTimeUpdateProgress> {
    
    return Observable<Int>
      .interval(30, scheduler: MainScheduler.instance)
      .withLatestFrom(tripGroups)
      .flatMapLatest(TKBuzzRealTime.rx.update)
      .startWith(.idle)
      .asDriver(onErrorRecover: { error in
        assertionFailure("Should never error, but did with: \(error)")
        return Driver.empty()
      })
  }
  
}

extension Reactive where Base: TKBuzzRealTime {
  
  static func update(tripGroups: [TripGroup]) -> Observable<TKRealTimeUpdateProgress> {
    let trips = tripGroups.compactMap { $0.visibleTrip }
    let individualUpdates = trips.map(update)
    return Observable
      .combineLatest(individualUpdates) { _ in .updated}
      .startWith(.updating)
  }
  
  static func update(_ trip: Trip) -> Observable<Bool> {
    var realTime: TKBuzzRealTime! = TKBuzzRealTime()
    
    return Observable.create { subscriber in
      realTime.update(trip, success: { (_, didUpdate) in
        subscriber.onNext(didUpdate)
        subscriber.onCompleted()
      }, failure: { error in
        // Silently absorb errors
        subscriber.onNext(false)
        subscriber.onCompleted()
      })
      return Disposables.create {
        realTime = nil
      }
    }
  }

}


// MARK: - Building results

extension TKUIResultsViewModel {
  
  static func fetchTripGroups(_ requests: Driver<TripRequest?>) -> Driver<[TripGroup]> {
    return requests.flatMapLatest { request in
      guard let request = request, let context = request.managedObjectContext else {
        return Driver.just([])
      }
      
      return context.rx
        .fetchObjects(
          TripGroup.self,
          sortDescriptors: [NSSortDescriptor(key: "visibleTrip.totalScore", ascending: true)],
          predicate: NSPredicate(format: "toDelete = NO AND request = %@ AND visibilityRaw != %@", request, NSNumber(value: TripGroupVisibility.hidden.rawValue)),
          relationshipKeyPathsForPrefetching: ["visibleTrip", "visibleTrip.segmentReferences"]
        )
        .throttle(0.5, scheduler: MainScheduler.instance)
        .asDriver(onErrorJustReturn: [])
    }
  }
  
  static func buildSections(_ groups: Driver<[TripGroup]>, inputs: UIInput) -> Driver<[Section]> {
    let expand = inputs.selected
      .map { item -> TripGroup? in
        switch item {
        case .nano, .trip, .lessIndicator: return nil
        case .moreIndicator(let group): return group
        }
    }
    
    return Driver
      .combineLatest(groups, inputs.changedSortOrder.startWith(.score), expand.startWith(nil))
      .map(sections)
  }
  
  private static func sections(for groups: [TripGroup], sortBy: TKTripCostType, expand: TripGroup?) -> [Section] {
    guard let first = groups.first else { return [] }
    
    let groupSorters = first.request.sortDescriptors(withPrimary: sortBy)
    let sorted = (groups as NSArray).sortedArray(using: groupSorters).compactMap { $0 as? TripGroup }
    
    let tripSorters = first.request.tripTimeSortDescriptors()
    return sorted.compactMap { group -> Section? in
      guard let best = group.visibleTrip else { return nil }
      let items = (Array(group.trips) as NSArray)
        .sortedArray(using: tripSorters)
        .compactMap { $0 as? Trip }
        .compactMap { Item(trip: $0, in: group) }
      
      let show: [Item]
      if items.count > 2, expand == group {
        show = items + [.lessIndicator(group)]
      } else if items.count > 2 {
        let good = items.filter { !($0.trip?.showFaded ?? true) }
        show = good.prefix(2) + [.moreIndicator(group)]
      } else {
        show = items
      }
      return Section(items: show, badge: group.badge, costs: best.costValues)
    }
  }
}

extension TripRequest {
  var includedTransportModes: String {
    let all = spanningRegion().modeIdentifiers
    let visible = Set(all).subtracting(TKUserProfileHelper.hiddenModeIdentifiers)
    return Loc.Showing(visible.count, ofTransportModes: all.count)
  }
}

extension TripGroup {
  var badge: TKMetricClassifier.Classification? {
    return TKMetricClassifier.classification(for: self)
  }
}

extension Trip {
  var showFaded: Bool {
    return missedBookingWindow     // shuttle, etc., departing too soon
        || calculateOffset() < -1  // doesn't match query
  }
}

extension TKUIResultsViewModel {
  
  /// An item in a section on the results screen
  public enum Item {
    
    /// A regular/expanded trip
    case trip(Trip)
    
    /// A minimised trip
    case nano(Trip)
    
    case moreIndicator(TripGroup)
    case lessIndicator(TripGroup)
    
    var trip: Trip? {
      switch self {
      case .nano(let trip): return trip
      case .trip(let trip): return trip
      case .moreIndicator, .lessIndicator: return nil
      }
    }
    
  }
  
  /// A section on the results screen, which consists of various sorted items
  public struct Section {
    public var items: [Item]
    
    public var badge: TKMetricClassifier.Classification?
    var costs: [NSNumber: String]
  }
}

extension TKMetricClassifier.Classification {
  
  var icon: UIImage? {
    switch self {
    case .easiest: return UIImage.iconRelax
    case .greenest: return UIImage.iconTree
    case .fastest: return UIImage.iconTime
    case .healthiest: return UIImage.iconRun
    case .cheapest: return UIImage.iconMoney
    case .recommended: return nil
    }
  }
  
  var text: String {
    switch self {
    case .easiest: return "Easiest" // TODO: Localise
    case .greenest: return "Greenest"
    case .fastest: return "Fastest"
    case .healthiest: return "Healthiest"
    case .cheapest: return "Cheapest"
    case .recommended: return "Recommended"
    }
  }
  
  var color: UIColor {
    switch self {
    case .easiest, .cheapest, .fastest: return #colorLiteral(red: 0.7921568627, green: 0.2549019608, blue: 0.0862745098, alpha: 1)
    case .greenest, .healthiest: return #colorLiteral(red: 0.1254901961, green: 0.7882352941, blue: 0.4156862745, alpha: 1)
    case .recommended: return #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
    }
  }
}

extension TKUIResultsViewModel.Item {
  
  fileprivate init?(trip: Trip, in group: TripGroup) {
    switch group.visibility {
    case .hidden: return nil
    case .mini:   self = .nano(trip)
    case .full:   self = .trip(trip)
    }
  }
  
}

// MARK: - Map content

public func ==(lhs: TKUIResultsViewModel.MapRouteItem, rhs: TKUIResultsViewModel.MapRouteItem) -> Bool {
  return lhs.trip.objectID == rhs.trip.objectID
}
extension TKUIResultsViewModel.MapRouteItem: Equatable { }

extension TripGroup {
  fileprivate var preferredRoute: TKUIResultsViewModel.MapRouteItem? {
    guard let trip = visibleTrip else { return nil }
    return TKUIResultsViewModel.MapRouteItem(trip)
  }
}

extension Array where Element == TKUIResultsViewModel.Section {
  fileprivate func find(_ mapRoute: TKUIResultsViewModel.MapRouteItem?) -> TKUIResultsViewModel.Item? {
    guard let mapRoute = mapRoute else { return nil }
    for section in self {
      for item in section.items {
        if item.trip == mapRoute.trip {
          return item
        }
      }
    }
    return nil
  }
  
  var bestItem: TKUIResultsViewModel.Item? {
    return first?.items.first // Assuming we're sorting by best
  }
}

// MARK: - ?

extension TKUIResultsViewModel {
  
  //  func allQueriesDidFinish(with error: NSError?) {
  //    // TODO: Call this again?
  //
  //    guard let request = self.rx_request.value, !request.hasTrips() else { return }
  //
  //    if let error = error {
  //      rx_error.onNext(error)
  //
  //    } else {
  //      // We have a request, there was no explicit error during routing.
  //      let info = [
  //        NSLocalizedDescriptionKey: NSLocalizedString("No routes found.", comment: "Error title when routing produced no results (but no specific error was returned from routing)."),
  //        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please adjust your query and try again.", comment: "Error recovery suggestion for when routing produced no results (but no specific error was returned from routing)."),
  //        ]
  //
  //      let noTrips = NSError(domain: "com.buzzhives.TripGo", code: 872631, userInfo: info)
  //      rx_error.onNext(noTrips)
  //    }
  //  }
  
}

// MARK: - Routing

extension TKUIResultsViewModel {
  
  static func regionForModes(for builder: RouteBuilder) -> TKRegion {
    let start = builder.origin?.coordinate
    let end = builder.destination?.coordinate
    
    if let start = start, let end = end {
      return TKRegionManager.shared.region(containing: start, end)
    } else if let start = start, let local = TKRegionManager.shared.localRegions(containing: start).first {
      return local
    } else {
      return .international
    }
  }
  
}

fileprivate extension TripRequest {
  
  var builder: TKUIResultsViewModel.RouteBuilder {
    
    let time: TKUIResultsViewModel.RouteBuilder.Time
    switch type {
    case .leaveASAP, .none:
      time = .leaveASAP
    case .leaveAfter:
      time = .leaveAfter(self.time!)
    case .arriveBefore:
      time = .arriveBefore(self.time!)
    }
    
    return TKUIResultsViewModel.RouteBuilder(
      mode: .destination,
      origin: fromLocation,
      destination: toLocation,
      time: time
    )
    
  }
  
}

extension TKUIResultsViewModel.RouteBuilder.Time {
  
  init(timeType: TKTimeType, date: Date) {
    switch timeType {
    case .leaveASAP, .none:
      self = .leaveASAP
    case .leaveAfter:
      self = .leaveAfter(date)
    case .arriveBefore:
      self = .arriveBefore(date)
    }
  }
  
  var date: Date {
    switch self {
    case .leaveASAP: return Date()
    case .leaveAfter(let date): return date
    case .arriveBefore(let date): return date
    }
  }
  
  var timeType: TKTimeType {
    switch self {
    case .leaveASAP: return .leaveASAP
    case .leaveAfter: return .leaveAfter
    case .arriveBefore: return .arriveBefore
    }
  }
  
  
}

extension TKUIResultsViewModel.RouteBuilder {
  
  var titles: (title: String, subtitle: String?) {
    let destinationName = destination?.title ?? nil
    let originName = origin?.title ?? nil
    
    let title: String
    if let name = destinationName {
      title = Loc.To(location: name)
    } else {
      title = "Plan Trip" // TODO: Localise
    }
    
    let subtitle: String
    if let name = originName {
      subtitle = Loc.From(location: name)
    } else {
      subtitle = "From current location" // TODO: Localise
    }
    return (title, subtitle)
  }
  
  var timeZone: TimeZone {
    switch time {
    case .leaveASAP, .leaveAfter:
      if let location = origin, let timeZone = TKRegionManager.shared.timeZone(for: location.coordinate) {
        return timeZone
      } else {
        fallthrough // prefer arrival time zone, over current
      }
      
    case .arriveBefore:
      if let location = destination, let timeZone = TKRegionManager.shared.timeZone(for: location.coordinate) {
        return timeZone
      }
    }
    return .current
  }
  
  fileprivate func generateRequest() -> TripRequest? {
    guard let destination = destination else { return nil }
    
    let origin = self.origin ?? TKLocationManager.shared.currentLocation
    
    return TripRequest.insert(
      from: origin, to: destination,
      for: time.date, timeType: time.timeType,
      into: TripKit.shared.tripKitContext
    )
  }
  
}


// MARK: - Protocol conformance

public func ==(lhs: TKUIResultsViewModel.RouteBuilder, rhs: TKUIResultsViewModel.RouteBuilder) -> Bool {
  return lhs.time == rhs.time
    && lhs.origin === rhs.origin
    && lhs.destination === rhs.destination
    && lhs.mode == rhs.mode
}
extension TKUIResultsViewModel.RouteBuilder: Equatable { }

public func ==(lhs: TKUIResultsViewModel.Item, rhs: TKUIResultsViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case (.trip(let left), .trip(let right)): return left.objectID == right.objectID
  case (.nano(let left), .nano(let right)): return left.objectID == right.objectID
  case (.moreIndicator, .moreIndicator): return true
  default: return false
  }
}
extension TKUIResultsViewModel.Item: Equatable { }

extension TKUIResultsViewModel.Item: IdentifiableType {
  public typealias Identity = String
  public var identity: Identity {
    switch self {
    case .trip(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .nano(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .moreIndicator(let group): return "more-\(group.objectID.uriRepresentation().absoluteString)"
    case .lessIndicator(let group): return "less-\(group.objectID.uriRepresentation().absoluteString)"
    }
  }
}

extension TKUIResultsViewModel.Section: AnimatableSectionModelType {
  public typealias Identity = String
  public typealias Item = TKUIResultsViewModel.Item
  
  public init(original: TKUIResultsViewModel.Section, items: [TKUIResultsViewModel.Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity { return items.first?.identity ?? "Empty" }
}
