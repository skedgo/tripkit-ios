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
  
  public convenience init(destination: MKAnnotation, inputs: UIInput) {
    let builder = RouteBuilder(destination: destination)
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
      .map(TKUIResultsViewModel.buildMapContent)

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
  
  public let mapRoutes: Driver<MapContent>
  
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
