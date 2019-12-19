//
//  TKUINearbyViewModel.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 26/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TripKit

import RxSwift
import RxCocoa
import RxDataSources

class TKUINearbyViewModel {
  
  enum Next {
    case stop(TKUIStopAnnotation)
    case location(TKModeCoordinate)
  }
  
  struct ListInput {
    var pickedModes: Signal<Set<TKModeInfo>> = .empty()
    var selection: Signal<TKUINearbyViewModel.Item> = .empty()
    var searchResult: Driver<MKAnnotation> = .empty()
  }
  
  struct MapInput {
    var mapRect: Driver<MKMapRect> = .just(.null)
    var selection: Signal<TKUIIdentifiableAnnotation?> = .empty()
  }
  
  /// Creates a new view model
  ///
  /// - Parameters:
  ///   - mode: The mode identifier to which to limit the nearby locations
  ///   - pickedModes: The selected modes (only used if `mode == nil`)
  ///   - mapCenter: The centre of the map, if the user moved it, should drive with `nil` if map is centred on the user's current location
  init(
      limitTo mode: String? = nil,
      startLocation: MKAnnotation? = nil,
      cardInput: ListInput = ListInput(),
      mapInput: MapInput = MapInput()
    ) {

    // Where we'll pass on any errors
    let errorPublisher = PublishSubject<Error>()

    // Internal inputs
    let deviceLocation = TKLocationManager.shared.rx.currentLocation
    let deviceHeading = TKLocationManager.shared.rx.deviceHeading.map { $0.magneticHeading }

    let refresh = PublishSubject<Void>()
    
    // Intermediary helpers
    
    // TODO: Use mapRect directly
    let center = mapInput.mapRect
      .map { MKCoordinateRegion($0).center }
      .startOptional()
    
    let nearby = Self.buildNearbyLocations(limitTo: mode, startLocation: startLocation, mapCenter: center, refresh: refresh, onError: errorPublisher)
    
    /// Variant of `nearby` that's filtering according to `pickedModes`
    let pickedModes = cardInput.pickedModes.asObservable()
      .map { $0 as Set<TKModeInfo>? }
      .startWith(nil)
    
    let filteredNearby: Driver<ViewContent>
    filteredNearby = Observable
      .combineLatest(nearby, pickedModes)
      .map { Self.filterNearbyContent($0, modes: $1, limitTo: mode) }
      .asDriver(onErrorDriveWith: .empty())
    
    // Outputs
    
    self.limitToMode = mode
    self.startLocation = startLocation
    
    self.refreshPublisher = refresh
    
    self.error = errorPublisher.asDriver(onErrorDriveWith: Driver.empty())
    
    self.mapAnnotations = filteredNearby.map { $0.annotations }
    
    self.availableModes = nearby
      .map { content -> [TKModeInfo] in
        let allModes = content.locations.compactMap { $0.stopModeInfo }
        return allModes.filterDuplicates { $0 == $1 }
      }
      .asDriver(onErrorJustReturn: [])
    
    self.sections = filteredNearby
      .map { Self.buildSections(content: $0, deviceLocation: deviceLocation, deviceHeading: deviceHeading) }
      .startWith( [.empty] )

    self.mapAnnotationToSelect = cardInput.selection
      .asObservable()
      .compactMap { $0.mapAnnotation }
      .asSignal(onErrorSignalWith: .empty())
    
    self.mapOverlays = filteredNearby.map { $0.overlays }
    
    self.searchResultToShow = cardInput.searchResult.startOptional()
    
    let nextFromMap: Signal<TKUIIdentifiableAnnotation?> = mapInput.selection

    // We don't trigger next from `cardInput.selection`, as we rely on this
    // to go via the map. Otherwise we end up with duplicated signals here.
    
    self.next = Signal.merge(nextFromMap)
      .asObservable()
      .compactMap {
        if let stop = $0 as? TKStopCoordinate {
          return .stop(stop)
        } else if let location = $0 as? TKModeCoordinate {
          return .location(location)
        } else {
          return nil
        }
      }
      .asSignal(onErrorSignalWith: .empty())
  }
  
  fileprivate let refreshPublisher: PublishSubject<Void>

  let limitToMode: String?
  
  let startLocation: MKAnnotation?

  // View output
  
  // These are the modes available in the locations.json output.
  let availableModes: Driver<[TKModeInfo]>

  let error: Driver<Error>
  
  let sections: Driver<[Section]>
  
  let mapAnnotations: Driver<[TKUIIdentifiableAnnotation]>
  
  let mapOverlays: Driver<[MKOverlay]>
  
  // View actions
  
  let next: Signal<Next>
  
  /// This will always be an annotations that's in `mapAnnotations`
  let mapAnnotationToSelect: Signal<TKUIIdentifiableAnnotation>
  
  /// This will typically be an annotation that's NOT in `mapAnnotations`
  let searchResultToShow: Driver<MKAnnotation?>
  
}

// MARK: - Helpful extensions

extension Array {
  
  func filterDuplicates(includeElement: @escaping (_ lhs: Element, _ rhs: Element) -> Bool) -> [Element] {
    
    return reduce(into: []) { acc, element in
      if nil == acc.first(where: { includeElement(element, $0) }) {
        acc.append(element)
      }
    }
    
  }
}

