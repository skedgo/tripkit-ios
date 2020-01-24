//
//  TKUIRoutingResultsViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

#if TK_NO_MODULE
#else
  import TripKit
#endif

public class TKUIRoutingResultsViewModel {
  
  public enum SearchMode {
    case origin
    case destination
  }
  
  public struct SearchResult {
    let mode: SearchMode
    let location: MKAnnotation
  }

  public typealias UIInput = (
    selected: Signal<Item>,                     // => do .next
    tappedToggleButton: Signal<TripGroup?>,     // => expand/collapse
    tappedDate: Signal<Void>,                   // => return which date to show
    tappedShowModes: Signal<Void>,              // => return which modes to show
    tappedShowModeOptions: Signal<Void>,        // => trigger mode configurator
    changedDate: Signal<RouteBuilder.Time>,     // => update request + title
    changedModes: Signal<[String]?>,            // => update request
    changedSortOrder: Signal<TKTripCostType>,   // => update sorting
    changedSearch: Signal<SearchResult>
  )
  
  public typealias MapInput = (
    tappedMapRoute: Signal<MapRouteItem>,
    droppedPin: Signal<CLLocationCoordinate2D>  // => call dropPin()
  )
  
  public convenience init(destination: MKAnnotation, limitTo modes: [String]? = nil, inputs: UIInput, mapInput: MapInput) {
    let builder = RouteBuilder(destination: destination)
    self.init(builder: builder, limitTo: modes, inputs: inputs, mapInput: mapInput)
  }
  
  public convenience init(request: TripRequest, limitTo modes: [String]? = nil, inputs: UIInput, mapInput: MapInput) {
    self.init(builder: request.builder, initialRequest: request, limitTo: modes, inputs: inputs, mapInput: mapInput)
  }
  
  private init(builder: RouteBuilder, initialRequest: TripRequest? = nil, limitTo modes: [String]? = nil, inputs: UIInput, mapInput: MapInput) {
    let builderChangedWithID = TKUIRoutingResultsViewModel.watch(builder, inputs: inputs, mapInput: mapInput)
      .share(replay: 1, scope: .forever)

    let errorPublisher = PublishSubject<Error>()
    self.error = errorPublisher.asSignal(onErrorSignalWith: .empty())
    
    // Monitor the builder's annotation's coordinates
    let originOrDestinationChanged = builderChangedWithID
      .flatMapLatest(TKUIRoutingResultsViewModel.locationsChanged)

    // Whenever the builder is changing, i.e., when the user changes the inputs,
    // we generate a new request. However, we don't do this if the got
    // provided with a request and `expandForFavorite` is not set; in that
    // case we just display the results.
    let requestChanged: Observable<(TripRequest, mutable: Bool)>
    let skipRequest: Bool
    if let request = initialRequest, request.tripGroups?.isEmpty == false, request.expandForFavorite == false {
      requestChanged = .just( (request, mutable: false) )
      skipRequest = true
    } else {
      requestChanged = Observable.merge(originOrDestinationChanged, builderChangedWithID)
        .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
        .distinctUntilChanged { $0.1 == $1.1 }
        .map { $0.0.generateRequest() }
        .startWith(initialRequest)
        .compactMap { $0 }
        .map { ($0, mutable: true) }
        .share(replay: 1, scope: .forever)
      skipRequest = false
    }

    let requestToShow = requestChanged.map { $0.0 }
    let updateableRequest = requestChanged.compactMap { $0.1 == true ? $0.0 : nil }

    let tripGroupsChanged = TKUIRoutingResultsViewModel.fetchTripGroups(requestToShow)
      .share(replay: 1, scope: .forever)
      .distinctUntilChanged()
    
    let builderChanged = builderChangedWithID.map { $0.0 }

    requestIsMutable = requestChanged.map { $0.1 }
      .startWith(true)
      .asDriver(onErrorJustReturn: true)
    
    request = requestToShow
      .asDriver(onErrorDriveWith: .empty())
    
    let progress: Driver<TKResultsFetcher.Progress>
    if skipRequest {
      progress = .just(.finished)
    } else {
      progress = TKUIRoutingResultsViewModel
        .fetch(for: updateableRequest, limitTo: modes, errorPublisher: errorPublisher)
        .asDriver(onErrorDriveWith: .empty())
    }
    fetchProgress = progress

    realTimeUpdate = TKUIRoutingResultsViewModel.fetchRealTimeUpdates(for: tripGroupsChanged)
      .asDriver(onErrorDriveWith: .empty())

    sections = TKUIRoutingResultsViewModel.buildSections(tripGroupsChanged, inputs: inputs, progress: progress.asObservable())
      .asDriver(onErrorJustReturn: [])

    let selection = mapInput.tappedMapRoute.startOptional() // default selection
    selectedItem = Observable.combineLatest(selection.asObservable(), sections.asObservable()) { $1.find($0) ?? $1.bestItem }
      .asDriver(onErrorDriveWith: .empty())
    
    originDestination = requestChanged
      .flatMapLatest { $0.0.reverseGeocodeLocations() }
      .asDriver(onErrorDriveWith: .empty())

    timeTitle = requestToShow
      .map { $0.timeString }
      .asDriver(onErrorDriveWith: .empty())
    
    let availableFromRequest: Observable<AvailableModes> = requestToShow
      .compactMap(TKUIRoutingResultsViewModel.buildAvailableModes)
    
    let availableFromChange = inputs.changedModes.asObservable()
      .withLatestFrom(requestToShow) { ($0, $1) }
      .compactMap(TKUIRoutingResultsViewModel.updateAvailableModes)
    
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

    mapRoutes = Observable.combineLatest(tripGroupsChanged, mapInput.tappedMapRoute.startOptional().asObservable())
      .map(TKUIRoutingResultsViewModel.buildMapContent)
      .asDriver(onErrorDriveWith: .empty())

    // Navigation
    
    let showTrip = inputs.selected
      .filter { $0.trip != nil }
      .map { Next.showTrip($0.trip!) }
    
    let modeInput = Observable.combineLatest(requestToShow, builderChanged)
    let presentModes = inputs.tappedShowModeOptions.asObservable()
      .withLatestFrom(modeInput) { (_, tuple) -> Next in
        let modes = tuple.0.applicableModeIdentifiers()
        let region = TKUIRoutingResultsViewModel.regionForModes(for: tuple.1)
        return Next.presentModeConfigurator(modes: modes, region: region)
      }
      .asSignal(onErrorSignalWith: .empty())
    
    let presentTime = inputs.tappedDate.asObservable()
      .withLatestFrom(builderChanged)
      .map { Next.presentDatePicker(time: $0.time, timeZone: $0.timeZone) }
      .asSignal(onErrorSignalWith: .empty())
    
    next = Signal.merge(showTrip, presentTime, presentModes)
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
  let fetchProgress: Driver<TKResultsFetcher.Progress>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  public let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  let error: Signal<Error>
  
  public let originAnnotation: Driver<MKAnnotation?>

  public let destinationAnnotation: Driver<MKAnnotation?>
  
  public let mapRoutes: Driver<MapContent>
  
  let next: Signal<Next>
}

// MARK: - Navigation

extension TKUIRoutingResultsViewModel {
  enum Next {
    case showTrip(Trip)
    case presentModeConfigurator(modes: [String], region: TKRegion)
    case presentDatePicker(time: RouteBuilder.Time, timeZone: TimeZone)
  }
}