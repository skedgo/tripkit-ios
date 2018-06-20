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

class TKUIResultsViewModel {
  
  typealias UIInput = (
    selected: Driver<Item>, // => do .next
    tappedDate: Driver<Void>, // => return which date to show
    tappedShowModes: Driver<Void>, // => return which modes to show
    changedDate: Driver<RouteBuilder.Time>, // => update request + title
    changedModes: Driver<Void>, // => update request
    changedSortOrder: Driver<STKTripCostType>, // => update sorting
    droppedPin: Driver<CLLocationCoordinate2D> // => call dropPin()
  )
  
  struct RouteBuilder {
    fileprivate enum SelectionMode {
      case origin
      case destination
    }
    
    enum Time {
      case leaveASAP
      case leaveAfter(Date)
      case arriveBefore(Date)
    }
    
    fileprivate var mode: SelectionMode
    fileprivate var origin: MKAnnotation?
    fileprivate var destination: MKAnnotation?
    fileprivate var time: Time
    
    fileprivate static var empty = RouteBuilder(mode: .destination, origin: nil, destination: nil, time: .leaveASAP)
  }
  
  convenience init(destination: MKAnnotation, inputs: UIInput) {
    self.init(builder: RouteBuilder(mode: .origin, origin: nil, destination: destination, time: .leaveASAP), inputs: inputs)
  }
  
  convenience init(request: TripRequest, inputs: UIInput) {
    self.init(builder: request.builder, initialRequest: request, inputs: inputs)
  }
  
  fileprivate init(builder: RouteBuilder, initialRequest: TripRequest? = nil, inputs: UIInput) {
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
    
    request = requestChanged
      .filter { $0 != nil }
      .map { $0! }
    
    fetchProgress = TKUIResultsViewModel.fetch(for: requestChanged, errorPublisher: errorPublisher)
    
    sections = TKUIResultsViewModel.buildSections(requestChanged, inputs: inputs)
    
    timeTitle = requestChanged
      .filter { $0 != nil }
      .map { $0!.timeString }
    
    mapAnnotations = builderChanged.map { $0.annotations }
    
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
  
  private let disposeBag = DisposeBag()
  
  let request: Driver<TripRequest>
  
  let timeTitle: Driver<String>
  
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
  let sections: Driver<[TKUIResultsViewModel.Section]>
  
  let fetchProgress: Driver<TKResultsFetcher.Progress>
  
  let error: Driver<Error>
  
  let mapAnnotations: Driver<[MKAnnotation]>
  
  let next: Driver<Next>
}

// MARK: - Navigation

extension TKUIResultsViewModel {
  enum Next {
    case showTrip(Trip)
    case presentModes(modes: [String], region: SVKRegion)
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
    
    return relevantInput.scan(initial) { previous, change in
      var updated = previous
      if let time = change.date {
        updated.time = time
      }
      if let pin = change.pin {
        updated.dropPin(at: pin)
      }
      return updated
    }
  }
  
  static func locationsChanged(in builder: RouteBuilder) -> Driver<RouteBuilder> {
    // This looks fairly complicated but all it does is monitoring the builder's
    // origin and destination annotations for changes to their coordinates, and
    // then triggers a rebuild.
    var origin: Observable<CLLocationCoordinate2D?> = Observable.empty()
    var destination: Observable<CLLocationCoordinate2D?> = Observable.empty()
    if let asObject = builder.origin as? NSObject {
      origin = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    if let asObject = builder.destination as? NSObject {
      destination = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    return Observable.merge(origin, destination)
      .map { _ in builder }
      .asDriver(onErrorDriveWith: Driver.empty())
  }
  
}

extension TKUIResultsViewModel.RouteBuilder {
  
  mutating func dropPin(at coordinate: CLLocationCoordinate2D) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    
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
          .fetchTrips(for: request, classifier: TKMetricClassifier())
          .asDriver(onErrorRecover: { error in
            errorPublisher.onNext(error)
            return Driver.just(.finished)
          })
    }
  }
  
}


// MARK: - Building results

extension TKUIResultsViewModel {
  
  static func buildSections(_ requests: Driver<TripRequest?>, inputs: UIInput) -> Driver<[Section]> {
    let expand = inputs.selected
      .map { item -> TripGroup? in
        switch item {
        case .nano, .trip, .lessIndicator: return nil
        case .moreIndicator(let group): return group
        }
    }
    
    return Driver.combineLatest(requests, inputs.changedSortOrder.startWith(.score), expand.startWith(nil))
      .flatMapLatest(buildSections)
  }
  
  private static func buildSections(_ request: TripRequest?, sortOrder: STKTripCostType, expand: TripGroup?) -> Driver<[Section]> {
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
      .map { sections(for: $0, sortBy: sortOrder, expand: expand) }
      .asDriver(onErrorJustReturn: [])
  }
  
  private static func sections(for groups: [TripGroup], sortBy: STKTripCostType, expand: TripGroup?) -> [Section] {
    guard let first = groups.first else { return [] }
    
    let groupSorters = first.request.sortDescriptors(withPrimary: sortBy)
    let sorted = (groups as NSArray).sortedArray(using: groupSorters).compactMap { $0 as? TripGroup }
    
    let tripSorters = first.request.tripSortDescriptors(withPrimary: sortBy)
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
        // TODO: We could be smarter about this, show the best plus the one before
        // or after (depending on query), and when expanding show all sorted
        // by time
        show = items.prefix(2) + [.moreIndicator(group)]
      } else {
        show = items
      }
      return Section(items: show, badge: group.badge, costs: best.costValues)
    }
  }
}

extension TripGroup {
  var badge: TKMetricClassifier.Classification? {
    return TKMetricClassifier.classification(for: self)
  }
}

extension TKUIResultsViewModel {
  
  /// An item in a section on the results screen
  enum Item {
    
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
  struct Section {
    var items: [Item]
    
    var badge: TKMetricClassifier.Classification?
    var costs: [NSNumber: String]
  }
}

extension TKMetricClassifier.Classification {
  
  var icon: UIImage {
    switch self {
    case .easiest: return UIImage.iconRelax
    case .greenest: return UIImage.iconTree
    case .fastest: return UIImage.iconTime
    case .healthiest: return UIImage.iconRun
    case .cheapest: return UIImage.iconMoney
    }
  }
  
  var text: String {
    switch self {
    case .easiest: return "Easiest" // TODO: Localise
    case .greenest: return "Greenest"
    case .fastest: return "Fastest"
    case .healthiest: return "Healthiest"
    case .cheapest: return "Cheapest"
    }
  }
  
  var color: UIColor {
    switch self {
    case .easiest, .cheapest, .fastest: return #colorLiteral(red: 0.7921568627, green: 0.2549019608, blue: 0.0862745098, alpha: 1)
    case .greenest, .healthiest: return #colorLiteral(red: 0.1254901961, green: 0.7882352941, blue: 0.4156862745, alpha: 1)
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
  
  func startRealtime() {
    //    guard let trips = request.trips else { return }
    //    for trip in trips {
    //      let immediately = !trip.timesAreRealTime()
    //      ServerCommunicator.sharedInstance().registerRealTimeUpdates(trip, updateImmediately: immediately)
    //    }
  }
  
  func stopRealtime() {
    //    guard let trips = request.trips else { return }
    //    for trip in trips {
    //      ServerCommunicator.sharedInstance().unregisterRealTimeUpdates(trip)
    //    }
  }
  
}

// MARK: - Map helpers

private extension TKUIResultsViewModel.RouteBuilder {
  
  var annotations: [MKAnnotation] {
    var annotations = [MKAnnotation]()
    if let origin = origin {
      annotations.append(origin)
    }
    if let destination = destination {
      annotations.append(destination)
    }
    return annotations
  }
  
}

extension TKUIResultsViewModel {
  
  func annotationIsOrigin(_ annotation: MKAnnotation) -> Bool {
    return false // TODO: Fix
  }
  
  func annotationIsDestination(_ annotation: MKAnnotation) -> Bool {
    return false // TODO: Fix
  }
  
}


// MARK: - Routing

extension TKUIResultsViewModel {
  
  static func regionForModes(for builder: RouteBuilder) -> SVKRegion {
    let start = builder.origin?.coordinate
    let end = builder.destination?.coordinate
    
    if let start = start, let end = end {
      return TKRegionManager.shared.region(containing: start, end)
    } else if let start = start, let local = TKRegionManager.shared.localRegions(containing: start).first {
      return local
    } else {
      return SVKInternationalRegion.shared
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
  
  init(timeType: SGTimeType, date: Date) {
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
  
  var timeType: SGTimeType {
    switch self {
    case .leaveASAP: return .leaveASAP
    case .leaveAfter: return .leaveAfter
    case .arriveBefore: return .arriveBefore
    }
  }
  
  
}

extension TKUIResultsViewModel.RouteBuilder {
  
  var timeZone: TimeZone {
    switch time {
    case .leaveASAP, .leaveAfter:
      if let location = origin, let timeZone = TKRegionManager.shared.timeZone(for: location.coordinate) {
        return timeZone
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
    
    let origin = self.origin ?? SGLocationManager.shared.currentLocation
    
    return TripRequest.insert(
      from: origin, to: destination,
      for: time.date, timeType: time.timeType,
      into: TripKit.shared.tripKitContext
    )
  }
  
}


// MARK: - Protocol conformance

func ==(lhs: TKUIResultsViewModel.Item, rhs: TKUIResultsViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case (.trip(let left), .trip(let right)): return left.objectID == right.objectID
  case (.nano(let left), .nano(let right)): return left.objectID == right.objectID
  case (.moreIndicator, .moreIndicator): return true
  default: return false
  }
}
extension TKUIResultsViewModel.Item: Equatable { }

extension TKUIResultsViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .trip(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .nano(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .moreIndicator(let group): return "more-\(group.objectID.uriRepresentation().absoluteString)"
    case .lessIndicator(let group): return "less-\(group.objectID.uriRepresentation().absoluteString)"
    }
  }
}

extension TKUIResultsViewModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUIResultsViewModel.Item
  
  init(original: TKUIResultsViewModel.Section, items: [TKUIResultsViewModel.Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity { return items.first?.identity ?? "Empty" }
}
