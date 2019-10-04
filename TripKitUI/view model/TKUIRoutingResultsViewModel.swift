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

  public typealias UIInput = (
    selected: Signal<Item>,                     // => do .next
    tappedToggleButton: Signal<TripGroup?>,     // => expand/collapse
    tappedDate: Signal<Void>,                   // => return which date to show
    tappedShowModes: Signal<Void>,              // => return which modes to show
    tappedShowModeOptions: Signal<Void>,        // => trigger mode configurator
    changedDate: Signal<RouteBuilder.Time>,     // => update request + title
    changedModes: Signal<[String]?>,            // => update request
    changedSortOrder: Signal<TKTripCostType>,   // => update sorting
    changedOrigin: Signal<MKAnnotation>,        // => update request + title
    changedDestination: Signal<MKAnnotation>    // => update request + subtitle
  )
  
  public typealias MapInput = (
    tappedMapRoute: Signal<MapRouteItem>,
    droppedPin: Signal<CLLocationCoordinate2D>  // => call dropPin()
  )
  
  public convenience init(destination: MKAnnotation, inputs: UIInput, mapInput: MapInput) {
    let builder = RouteBuilder(destination: destination)
    self.init(builder: builder, inputs: inputs, mapInput: mapInput)
  }
  
  public convenience init(request: TripRequest, inputs: UIInput, mapInput: MapInput) {
    self.init(builder: request.builder, initialRequest: request, inputs: inputs, mapInput: mapInput)
  }
  
  private init(builder: RouteBuilder, initialRequest: TripRequest? = nil, inputs: UIInput, mapInput: MapInput) {
    let builderChanged = TKUIRoutingResultsViewModel.watch(builder, inputs: inputs, mapInput: mapInput)
      .share(replay: 1, scope: .forever)

    let errorPublisher = PublishSubject<Error>()
    self.error = errorPublisher.asSignal(onErrorSignalWith: .empty())
    
    // Monitor the builder's annotation's coordinates
    let originOrDestinationChanged = builderChanged
      .flatMapLatest(TKUIRoutingResultsViewModel.locationsChanged)
    
    // Whenever the builder is changing, i.e., when the user changes the inputs,
    // we generate a new request.
    let requestChanged = Observable.merge(originOrDestinationChanged, builderChanged)
      .map { $0.generateRequest() }
      .filter { $0 != nil }
      .startWith(initialRequest)
      .share(replay: 1, scope: .forever)

    let tripGroupsChanged = TKUIRoutingResultsViewModel.fetchTripGroups(requestChanged)
      .share(replay: 1, scope: .forever)
      .distinctUntilChanged()

    request = requestChanged
      .filter { $0 != nil }
      .map { $0! }
      .asDriver(onErrorDriveWith: .empty())
    
    fetchProgress = TKUIRoutingResultsViewModel.fetch(for: requestChanged, errorPublisher: errorPublisher)
      .asDriver(onErrorDriveWith: .empty())

    realTimeUpdate = TKUIRoutingResultsViewModel.fetchRealTimeUpdates(for: tripGroupsChanged)
      .asDriver(onErrorDriveWith: .empty())

    sections = TKUIRoutingResultsViewModel.buildSections(tripGroupsChanged, inputs: inputs)
      .asDriver(onErrorJustReturn: [])

    let selection = mapInput.tappedMapRoute.startOptional() // default selection
    selectedItem = Observable.combineLatest(selection.asObservable(), sections.asObservable()) { $1.find($0) ?? $1.bestItem }
      .asDriver(onErrorDriveWith: .empty())
    
    titles = builderChanged
      .map { $0.titles }
      .asDriver(onErrorDriveWith: .empty())

    timeTitle = requestChanged
      .compactMap { $0?.timeString }
      .asDriver(onErrorDriveWith: .empty())
    
    let availableFromRequest: Observable<AvailableModes> = requestChanged
      .compactMap(TKUIRoutingResultsViewModel.buildAvailableModes)
    
    let availableFromChange = inputs.changedModes.asObservable()
      .withLatestFrom(requestChanged) { ($0, $1) }
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
      .map { Next.showTrip($0.trip) }
    
    let modeInput = Observable.combineLatest(requestChanged, builderChanged)
    let presentModes = inputs.tappedShowModeOptions.asObservable()
      .withLatestFrom(modeInput) { (_, tuple) -> Next in
        let modes = tuple.0?.applicableModeIdentifiers() ?? []
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
  
  let titles: Driver<(title: String, subtitle: String?)>
  
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
