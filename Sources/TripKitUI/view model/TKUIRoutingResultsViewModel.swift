//
//  TKUIRoutingResultsViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TripKit

class TKUIRoutingResultsViewModel {
  
  enum SearchMode {
    case origin
    case destination
  }
  
  struct SearchResult {
    let mode: SearchMode
    let location: MKAnnotation
  }

  typealias UIInput = (
    selected: Signal<Item>,                     // => do .next
    tappedSectionButton: Signal<ActionPayload>, // => section action
    tappedDate: Signal<Void>,                   // => return which date to show
    tappedShowModes: Signal<Void>,              // => return which modes to show
    tappedShowModeOptions: Signal<Void>,        // => trigger mode configurator
    changedDate: Signal<RouteBuilder.Time>,     // => update request + title
    changedModes: Signal<[String]?>,            // => update request
    changedSortOrder: Signal<TKTripCostType>,   // => update sorting
    changedSearch: Signal<SearchResult>
  )
  
  typealias MapInput = (
    tappedMapRoute: Signal<TKUIRoutingResultsMapRouteItem>,
    droppedPin: Signal<CLLocationCoordinate2D>  // => call dropPin()
  )
  
  convenience init(destination: MKAnnotation, limitTo modes: Set<String>? = nil, inputs: UIInput, mapInput: MapInput) {
    let builder = RouteBuilder(destination: destination)
    self.init(builder: builder, editable: false, limitTo: modes, inputs: inputs, mapInput: mapInput)
  }
  
  convenience init(request: TripRequest, editable: Bool, limitTo modes: Set<String>? = nil, inputs: UIInput, mapInput: MapInput) {
    self.init(builder: request.builder, initialRequest: request, editable: editable, limitTo: modes, inputs: inputs, mapInput: mapInput)
  }
  
  private init(builder: RouteBuilder, initialRequest: TripRequest? = nil, editable: Bool, limitTo modes: Set<String>? = nil, inputs: UIInput, mapInput: MapInput) {
    
    let builderChangedWithID = Self.watch(builder, inputs: inputs, mapInput: mapInput)
      .share(replay: 1, scope: .forever)

    let errorPublisher = PublishSubject<Error>()
    self.error = errorPublisher.asSignal(onErrorSignalWith: .empty())
    
    // Monitor the builder's annotation's coordinates
    let originOrDestinationChanged = builderChangedWithID
      .flatMapLatest(Self.locationsChanged)

    // Whenever the builder is changing, i.e., when the user changes the inputs,
    // we generate a new request. However, we don't do this if the got
    // provided with a request and set to `editable == false`; in that
    // case we just display the results.
    let requestChanged: Observable<(TripRequest, mutable: Bool)>
    let skipRequest: Bool
    if !editable, let request = initialRequest, !request.tripGroups.isEmpty {
      requestChanged = .just( (request, mutable: false) )
      skipRequest = true
    
    } else {
      requestChanged = Observable.merge(
        originOrDestinationChanged,
        builderChangedWithID
          .debounce(.seconds(1), scheduler: MainScheduler.instance)
      )
        .distinctUntilChanged { $0.1 == $1.1 } // only generate a new request object if necessary
        .map { ($0.0.generateRequest(), $0.1) }
        .startWith( (initialRequest, initialRequest.map { Self.buildId(for: $0.builder) } ) )
        .distinctUntilChanged { $0.1 == $1.1 } // ignore duplicated request objects (happens when initialRequest != nil)
        .compactMap { $0.0 }
        .map { ($0, mutable: true) }
        .share(replay: 1, scope: .forever)
      skipRequest = false
    }

    let requestToShow = requestChanged.map(\.0)
    let updateableRequest = requestChanged.compactMap { $0.1 == true ? $0.0 : nil }

    let tripGroupsChanged = TKUIRoutingResultsViewModel.fetchTripGroups(requestChanged)
      .share(replay: 1, scope: .forever)
      .distinctUntilChanged { $0.0 == $1.0 }
    
    let builderChanged = builderChangedWithID.map(\.0)

    requestIsMutable = requestChanged.map(\.1)
      .startWith(true)
      .asDriver(onErrorJustReturn: true)
    
    request = requestToShow
      .asDriver(onErrorDriveWith: .empty())
    
    let progress: Driver<TKUIResultsFetcher.Progress>
    if skipRequest {
      progress = .just(.finished)
    } else {
      progress = Self.fetch(
          for: updateableRequest,
          skipInitial: initialRequest != nil,
          limitTo: modes,
          errorPublisher: errorPublisher
        )
        .asDriver(onErrorDriveWith: .empty())
    }
    fetchProgress = progress
    
    let advisory = Self.fetchAdvisory(for: requestToShow)

    realTimeUpdate = Self.fetchRealTimeUpdates(for: tripGroupsChanged.map(\.0))
      .asDriver(onErrorDriveWith: .empty())

    sections = Self.buildSections(tripGroupsChanged, inputs: inputs, progress: progress.asObservable(), advisory: advisory)
      .asDriver(onErrorJustReturn: [])

    let selection = mapInput.tappedMapRoute.startOptional() // default selection
    selectedItem = Observable
      .combineLatest(selection.asObservable(), sections.asObservable()) { $1.find($0) ?? $1.bestItem }
      .distinctUntilChanged()
      .asDriver(onErrorDriveWith: .empty())
    
    originDestination = requestChanged
      .flatMapLatest { $0.0.reverseGeocodeLocations() }
      .asDriver(onErrorDriveWith: .empty())

    timeTitle = requestToShow
      .map { $0.timeString }
      .asDriver(onErrorDriveWith: .empty())
    
    let availableFromRequest: Observable<AvailableModes> = requestChanged
      .compactMap(Self.buildAvailableModes)
      .distinctUntilChanged { $0.available == $1.available } // ignore any `enabled` changes in the mean-time
    
    let availableFromChange = inputs.changedModes.asObservable()
      .withLatestFrom(requestToShow) { ($0, $1) }
      .compactMap(Self.updateAvailableModes)
    
    let available = Observable.merge(availableFromRequest, availableFromChange)
      .distinctUntilChanged()
    
    let showModes = inputs.tappedShowModes.scan(false) { acc, _ in !acc }.asObservable()

    availableModes = Observable.combineLatest(available, showModes) { available, show in
        if show {
          return available
        } else {
          return .none
        }
      }
      .asDriver(onErrorDriveWith: .empty())

    originAnnotation = builderChanged
      .map { $0.origin }
      .distinctUntilChanged { $0 === $1 }
      .asDriver(onErrorDriveWith: .empty())

    destinationAnnotation = builderChanged
      .map { $0.destination }
      .distinctUntilChanged { $0 === $1 }
      .asDriver(onErrorDriveWith: .empty())

    mapRoutes = Observable.combineLatest(
        tripGroupsChanged.map(\.0),
        mapInput.tappedMapRoute.startOptional().asObservable()
      )
      .map(Self.buildMapContent)
      .asDriver(onErrorDriveWith: .empty())

    // Navigation
    
    let triggerAction = inputs.tappedSectionButton
      .compactMap { action -> Next? in
        switch action {
        case let .trigger(action, group): return .trigger(action, group)
        default: return nil
        }
      }
    
    let showSelection = inputs.selected
      .compactMap(Next.init)

    let modeInput = Observable.combineLatest(requestToShow, builderChanged)
    let presentModes = inputs.tappedShowModeOptions.asObservable()
      .withLatestFrom(modeInput) { (_, tuple) -> Next in
        let modes = tuple.0.applicableModeIdentifiers
        let region = Self.regionForModes(for: tuple.1)
        return Next.presentModeConfigurator(modes: modes, region: region)
      }
      .asSignal(onErrorSignalWith: .empty())
    
    let presentTime = inputs.tappedDate.asObservable()
      .withLatestFrom(builderChanged)
      .map { Next.presentDatePicker(time: $0.time, timeZone: $0.timeZone) }
      .asSignal(onErrorSignalWith: .empty())
    
    next = Signal.merge(showSelection, presentTime, presentModes, triggerAction)
  }
  
  let request: Driver<TripRequest>
  
  /// Whether the user is allowed to change the request
  let requestIsMutable: Driver<Bool>
  
  let originDestination: Driver<(origin: String?, destination: String?)>
  
  let timeTitle: Driver<String>
  
  let availableModes: Driver<AvailableModes>
  
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
  let fetchProgress: Driver<TKUIResultsFetcher.Progress>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  let error: Signal<Error>
  
  let originAnnotation: Driver<MKAnnotation?>

  let destinationAnnotation: Driver<MKAnnotation?>
  
  let mapRoutes: Driver<MapContent>
  
  let next: Signal<Next>
}

// MARK: - Navigation

extension TKUIRoutingResultsViewModel {
  enum Next {
    case showTrip(Trip)
    case showAlert(TKAPI.Alert)
    case presentModeConfigurator(modes: [String], region: TKRegion)
    case presentDatePicker(time: RouteBuilder.Time, timeZone: TimeZone)
    case trigger(TKUIRoutingResultsCard.TripGroupAction, TripGroup)
    
    init?(selection: Item) {
      switch selection {
      case .advisory(let alert): self = .showAlert(alert)
      case .trip(let trip): self = .showTrip(trip)
      default: return nil
      }
    }
  }
}
