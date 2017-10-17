//
//  TKUIResultsCardModel.swift
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

class TKUIResultsCardModel {
  
  struct RouteBuilder {
    enum SelectionMode {
      case origin
      case destination
    }
    
    enum Time {
      case leaveASAP
      case leaveAfter(Date)
      case arriveBefore(Date)
    }
    
    var mode: SelectionMode
    var origin: MKAnnotation?
    var destination: MKAnnotation?
    var time: Time
    
    static var empty = RouteBuilder(mode: .destination, origin: nil, destination: nil, time: .leaveASAP)
  }
  
  convenience init(destination: MKAnnotation) {
    self.init(builder: RouteBuilder(mode: .origin, origin: nil, destination: destination, time: .leaveASAP))
  }
  
  convenience init(request: TripRequest) {
    self.init(builder: request.builder, request: request)
  }
  
  fileprivate init(builder: RouteBuilder, request: TripRequest? = nil) {
    rx_request = Variable(request)
    rx_routeBuilderVar = Variable(builder)
    
    // Monitor the builder's annotation's coordinates
    //
    // This looks fairly complicated but all it does is monitoring
    // the builder's origin and destination annotations for changes
    // to their coordinates, and then triggers a rebuild.
    rx_routeBuilderVar.asObservable()
      .flatMapLatest { builder -> Observable<RouteBuilder> in
        let origin: Observable<CLLocationCoordinate2D?>
        let destination: Observable<CLLocationCoordinate2D?>
        if let asObject = builder.origin as? NSObject {
          origin = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
        } else {
          origin = Observable.just(nil)
        }
        if let asObject = builder.destination as? NSObject {
          destination = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
        } else {
          destination = Observable.just(nil)
        }
        return Observable.combineLatest(origin.startWith(builder.origin?.coordinate), destination.startWith(builder.origin?.coordinate)) { _,_ in return builder }
      }
      .map { $0.generateRequest() }
      .filter { $0 != nil }
      .bind(to: rx_request)
      .disposed(by: disposeBag)
    
    
    // Whenever the builder is changing, i.e., when the user changes the
    // inputs, we generate a new request.
    rx_routeBuilderVar.asObservable()
      .map { $0.generateRequest() }
      .filter { $0 != nil }
      .bind(to: rx_request)
      .disposed(by: disposeBag)
  }
  
  fileprivate let disposeBag = DisposeBag()
  
  fileprivate let rx_routeBuilderVar: Variable<RouteBuilder>
  
  fileprivate let rx_request: Variable<TripRequest?>
  
  var request: TripRequest? {
    return rx_request.value
  }
  
  fileprivate let rx_sortOrder = Variable<STKTripCostType>(TKSettings.sortOrder)
  
  var sortOrder: STKTripCostType {
    get {
      return rx_sortOrder.value
    }
    set {
      TKSettings.sortOrder = newValue
      rx_sortOrder.value = newValue
    }
  }
  
  fileprivate let rx_error = PublishSubject<Error>()
  
  var error: Observable<Error> {
    return rx_error
  }
  
  var timeTitle: Observable<String> {
    return rx_request.asObservable()
      .filter { $0 != nil }
      .map { $0!.timeString }
  }
  
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
  lazy var sections: Observable<[ResultSection]> = {

    let request = self.rx_request.asObservable()
      .filter { $0 != nil && $0?.managedObjectContext != nil }
      .map { ($0!, $0!.managedObjectContext!) }
    
    let sort = self.rx_sortOrder.asObservable()
    
    return Observable
      .combineLatest(request, sort) { (request: $0.0, context: $0.1, order: $1) }
      .flatMapLatest { [unowned self] input in
        return input.context.rx
          .fetchObjects(
            TripGroup.self,
            sortDescriptors: [NSSortDescriptor(key: "visibleTrip.totalScore", ascending: true)],
            predicate: NSPredicate(format: "toDelete = NO AND request = %@ AND visibilityRaw != %@", input.request, NSNumber(value: TripGroupVisibility.hidden.rawValue)),
            relationshipKeyPathsForPrefetching: ["visibleTrip", "visibleTrip.segmentReferences"]
          )
          .throttle(0.5, scheduler: MainScheduler.instance)
          .map { [weak self] in
            self?.startRealtime()
            return self?.items(for: $0, sortBy: input.order) ?? []
          }
          .map { [ResultSection(items: $0)] }
      }
      .startWith([])
      .share(replay: 1, scope: .forever)
    
  }()
  
  
  lazy var fetchProgress: Observable<TKResultsFetcher.Progress> = {

    return self.rx_request.asObservable()
      .filter { $0 != nil }
      .map { $0! }
      .distinctUntilChanged()
      .filter { $0.managedObjectContext != nil }
      .flatMapLatest { [weak self] request -> Observable<TKResultsFetcher.Progress> in
        self?.stopRealtime()
        // Fetch the trip and handle errors in here, to not abort the outer observable
        return TKResultsFetcher
          .fetchTrips(for: request)
          .asDriver(onErrorRecover: { [weak self] error in
            self?.rx_error.onNext(error)
            return Driver.empty()
          })
          .asObservable()
      }
      .share(replay: 1, scope: .forever)
    
  }()
  
  fileprivate func rebuildSections() {
    // hacky way
    sortOrder = rx_sortOrder.value
  }
  
  func allQueriesDidFinish(with error: NSError?) {
    // TODO: Call this again?
    
    guard let request = self.rx_request.value, !request.hasTrips() else { return }
      
    if let error = error {
      rx_error.onNext(error)
      
    } else {
      // We have a request, there was no explicit error during routing.
      let info = [
        NSLocalizedDescriptionKey: NSLocalizedString("No routes found.", comment: "Error title when routing produced no results (but no specific error was returned from routing)."),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please adjust your query and try again.", comment: "Error recovery suggestion for when routing produced no results (but no specific error was returned from routing)."),
        ]
      
      let noTrips = NSError(domain: "com.buzzhives.TripGo", code: 872631, userInfo: info)
      rx_error.onNext(noTrips)
    }
  }
  
  private func items(for groups: [TripGroup], sortBy: STKTripCostType) -> [ResultItem] {
    guard let first = groups.first else { return [] }
    
    let descriptors = first.request.sortDescriptors(withPrimary: sortBy)
    let sorted = (groups as NSArray).sortedArray(using: descriptors).flatMap { $0 as? TripGroup }
    
    return sorted.flatMap { group -> ResultItem? in
      guard let trip = group.visibleTrip else { return nil }
      switch group.visibility {
      case .hidden: return nil
      case .mini:   return .nano(trip)
      case .full:   return .trip(trip)
      }
    }
  }
  
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


// MARK: - Routing

extension TKUIResultsCardModel {
  
  var routeBuilder: RouteBuilder {
    return rx_routeBuilderVar.value
  }
  
  var rx_routeBuilder: Observable<RouteBuilder> {
    return rx_routeBuilderVar.asObservable()
  }
  
  var applicableModes: [String] {
    return rx_request.value?.applicableModeIdentifiers() ?? []
  }
  
  var regionForModes: SVKRegion {
    let start = routeBuilder.origin?.coordinate
    let end = routeBuilder.destination?.coordinate
    
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
  
  var builder: TKUIResultsCardModel.RouteBuilder {
    
    let time: TKUIResultsCardModel.RouteBuilder.Time
    switch type {
    case .leaveASAP, .none:
      time = .leaveASAP
    case .leaveAfter:
      time = .leaveAfter(self.time!)
    case .arriveBefore:
      time = .arriveBefore(self.time!)
    }
    
    return TKUIResultsCardModel.RouteBuilder(
      mode: .destination,
      origin: fromLocation,
      destination: toLocation,
      time: time
    )
    
  }
  
}

extension TKUIResultsCardModel.RouteBuilder.Time {
 
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

extension TKUIResultsCardModel.RouteBuilder {
  
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


// MARK: - User interaction

extension TKUIResultsCardModel {
  
  func dropPin(at coordinate: CLLocationCoordinate2D) {
    var newInfo = routeBuilder
    
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    
    switch newInfo.mode {
    case .origin:
      // TODO: Localise
      annotation.title = "Origin"
      newInfo.origin = annotation
      newInfo.mode = .destination
    case .destination:
      // TODO: Localise
      annotation.title = "Destination"
      newInfo.destination = annotation
      newInfo.mode = .origin
    }
    
    rx_routeBuilderVar.value = newInfo
    
  }
  
  func selected(_ time: RouteBuilder.Time) {
    
    var newInfo = routeBuilder
    newInfo.time = time
    rx_routeBuilderVar.value = newInfo
    
  }
  
}



// MARK: - Table content models

/// An item in a section on the results screen
enum ResultItem {
  
  /// A regular/expanded trip
  case trip(Trip)
  
  /// A minimised trip
  case nano(Trip)
  
  
  var trip: Trip {
    switch self {
    case .nano(let trip): return trip
    case .trip(let trip): return trip
    }
  }
  
}

/// A section on the results screen, which consists of various sorted items
struct ResultSection {
  var header: String { return "" }
  
  /// Items in this section, all instances of the `ResultItem` enum
  var items: [Item]
}

// MARK: - Protocol conformance

func ==(lhs: ResultItem, rhs: ResultItem) -> Bool {
  
  switch (lhs, rhs) {
  case (.trip(let left), .trip(let right)): return left.objectID == right.objectID
  case (.nano(let left), .nano(let right)): return left.objectID == right.objectID
  default: return false
  }
}
extension ResultItem: Equatable {
}

extension ResultItem: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .trip(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .nano(let trip): return trip.objectID.uriRepresentation().absoluteString
    }
  }
}

extension ResultSection: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = ResultItem
  
  init(original: ResultSection, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity { return "SingleSection" }
}

