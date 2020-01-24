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

public class TKUINearbyViewModel {
  
  public enum Next {
    case stop(TKUIStopAnnotation)
    case location(TKModeCoordinate)
  }
  
  public struct ListInput {
    public let pickedModes: Signal<Set<TKModeInfo>>
    public let selection: Signal<TKUINearbyViewModel.Item>
    public let searchResult: Driver<MKAnnotation>
    
    public init(pickedModes: Signal<Set<TKModeInfo>> = .empty(), selection: Signal<TKUINearbyViewModel.Item> = .empty(), searchResult: Driver<MKAnnotation> = .empty()) {
      self.pickedModes = pickedModes
      self.selection = selection
      self.searchResult = searchResult
    }
  }
  
  public struct MapInput {
    public let mapRect: Driver<MKMapRect>
    public let selection: Signal<TKUIIdentifiableAnnotation?>
    public let focus: Signal<MKAnnotation?>
    
    public init(
      mapRect: Driver<MKMapRect> = .just(.null),
      selection: Signal<TKUIIdentifiableAnnotation?> = .empty(),
      focus: Signal<MKAnnotation?> = .just(nil)
    ) {
      self.mapRect = mapRect
      self.selection = selection
      self.focus = focus
    }
  }
  
  /// Creates a new view model
  ///
  /// - Parameters:
  ///   - mode: The mode identifier to which to limit the nearby locations
  ///   - pickedModes: The selected modes (only used if `mode == nil`)
  ///   - mapCenter: The centre of the map, if the user moved it, should drive with `nil` if map is centred on the user's current location
  public init(
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
    
    let nearby = Self.buildNearbyLocations(
      limitTo: mode,
      startLocation: startLocation,
      mapRect: mapInput.mapRect.startOptional(),
      refresh: refresh,
      onError: errorPublisher
    )
    
    /// Variant of `nearby` that's filtering according to `pickedModes`
    let pickedModes = cardInput.pickedModes.asObservable()
      .map { $0 as Set<TKModeInfo>? }
      .startWith(nil)
    
    let focused = mapInput.focus
      .asObservable()
      .startWith(nil)
    
    let filteredNearby: Driver<ViewContent>
    filteredNearby = Observable
      .combineLatest(nearby, pickedModes, focused)
      .map { TKUINearbyViewModel.filterNearbyContent($0, modes: $1, limitTo: mode, focusOn: $2) }
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
        return allModes.tk_filterDuplicates { $0 == $1 }
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

  public let limitToMode: String?
  
  public let startLocation: MKAnnotation?

  // View output
  
  // These are the modes available in the locations.json output.
  public let availableModes: Driver<[TKModeInfo]>

  public let error: Driver<Error>
  
  public let sections: Driver<[Section]>
  
  public let mapAnnotations: Driver<[TKUIIdentifiableAnnotation]>
  
  public let mapOverlays: Driver<[MKOverlay]>
  
  // View actions
  
  public let next: Signal<Next>
  
  /// This will always be an annotations that's in `mapAnnotations`
  public let mapAnnotationToSelect: Signal<TKUIIdentifiableAnnotation>
  
  /// This will typically be an annotation that's NOT in `mapAnnotations`
  public let searchResultToShow: Driver<MKAnnotation?>
  
}

// MARK: - Helpful extensions

extension Array {
  
  public func tk_filterDuplicates(includeElement: @escaping (_ lhs: Element, _ rhs: Element) -> Bool) -> [Element] {
    
    return reduce(into: []) { acc, element in
      if nil == acc.first(where: { includeElement(element, $0) }) {
        acc.append(element)
      }
    }
    
  }
}
