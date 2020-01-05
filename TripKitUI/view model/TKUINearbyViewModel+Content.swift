//
//  TKUINearbyViewModel+Content.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 27.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit

import TripKit

import RxSwift
import RxCocoa
import RxDataSources

extension TKUINearbyViewModel {
  
  /// An item in a section on the nearby screen
  public struct Item {
    public let modeCoordinate: TKModeCoordinate
    
    public let title: String
    public let icon: UIImage?
    public let iconURL: URL?
    public let identifier: String
    
    public let subtitle: Driver<String?>
    public let distance: Driver<CLLocationDistance?>
    public let heading: Driver<CLLocationDirection?>
    
    public var mapAnnotation: TKUIIdentifiableAnnotation? {
      return modeCoordinate is TKDisplayableRoute ? nil : modeCoordinate
    }
  }
  
  /// A section on the nearby screen, which is made up of various sorted items.
  public struct Section {
    static let empty = Section(items: [])
    
    public var header: String { return "" }
    
    /// Items in this section, all instances of the `TKUINearbyViewModel.Item` enum
    public var items: [Item]
  }
  
}

// MARK: - Build content

extension TKUINearbyViewModel {
  
  struct ViewContent {
    let locations: [TKModeCoordinate]
    let user: CLLocation?
    
    var annotations: [TKModeCoordinate] {
      return locations.filter { !($0 is TKDisplayableRoute) }
    }
    
    var overlays: [MKOverlay] {
      return locations
        .compactMap { $0 as? TKDisplayableRoute }
        .compactMap { TKRoutePolyline(for: $0) }
    }
    
  }
  
  static func buildNearbyLocations(limitTo mode: String?, startLocation: MKAnnotation?, mapCenter: Driver<CLLocationCoordinate2D?>, refresh: Observable<Void>, onError errorPublisher: PublishSubject<Error>) -> Observable<ViewContent>
  {
    /// Observable combining the user's device location and locations that are nearby.
    /// This includes all nearby locations, regardless of filtering status. To get the
    /// same thing filtered, use `filteredNearby`.
    
    
    let newCoordinate = mapCenter.asObservable()
      .startWith(startLocation?.coordinate)
      .distinctUntilChanged { prev, new in
        // Only pass on if we moved at least a certain amount
        
        if prev == nil, new == nil {
          return true
        } else if let oldCoordinate = prev, let newCoordinate = new, let distance = oldCoordinate.distance(from: newCoordinate) {
          return distance < 250
        } else {
          return false
        }
      }
    
    /// *All* the locations near current coordinate (either from device location
    /// or the user moving the map).
    return Observable.combineLatest(newCoordinate, refresh.startWith(()))
      .flatMapLatest { (coordinate, _) -> Observable<[TKModeCoordinate]> in
        guard let coordinate = coordinate else { return .empty() }
        return TKLocationProvider.fetchLocations(center: coordinate, radius: 750, modes: mode != nil ? [mode!] : nil)
          .asObservable()
          .catchError { error in
            errorPublisher.onNext(error)
            return .empty()
        }
      }
      .map { ViewContent(locations: $0, user: nil) }
  }
  
  static func filterNearbyContent(_ content: ViewContent, modes: Set<TKModeInfo>?, limitTo mode: String?, focusOn annotation: MKAnnotation?) -> ViewContent {
    if let focus = annotation {
      let byFocus = content.locations.filter { location in
        return location.coordinate.latitude == focus.coordinate.latitude && location.coordinate.longitude == focus.coordinate.longitude
      }
      return ViewContent(locations: byFocus, user: content.user)
      
    } else {
      let byModes = content.locations.filter { location in
        guard mode == nil else { return true } // no extra filtering
        if let enabled = modes {
          return enabled.contains { $0 == location.stopModeInfo }
        } else {
          return !TKUserProfileHelper.hiddenAndMinimizedModeIdentifiers.contains( location.modeInfo.identifier ?? "")
        }
      }
      return ViewContent(locations: byModes, user: content.user)
    }
  }
  
  static func buildSections(content: ViewContent, deviceLocation: Observable<CLLocation>, deviceHeading: Observable<CLLocationDirection>) -> [Section] {
    
    // TODO: Review this, it's weird that we get the user location twice?!, once as a driver and once as a value.
    
    // The items also get the device location and heading so that the UI can update accordingly
    // *even if* the number of items or their sort order isn't changing.
    //
    // Note that, we use the `anotations` property of `ViewContent` to build sections. This allows
    // us to exclude elements that are `MKOverlay`, e.g., on-street parking locations. 
    var items = content.annotations.map { Item(for: $0, distanceFrom: deviceLocation, deviceHeading: deviceHeading) }
    
    // We sorted by the input's *current* distance. We are *not* resorting as the
    // distances change, as we rely on `filteredNearby` to then fire again.
    items.sort {
      if let user = content.user?.coordinate, let first = $0.modeCoordinate.coordinate.distance(from: user), let second = $1.modeCoordinate.coordinate.distance(from: user) {
        return first < second
      } else {
        return $0.title < $1.title
      }
    }
    return [Section(items:items)]
  }
  
}

// MARK: - Helpers

fileprivate extension TKUINearbyViewModel.Item {
  init(for modeCoordinate: TKModeCoordinate, distanceFrom target: Observable<CLLocation>, deviceHeading: Observable<CLLocationDirection>) {
    self.modeCoordinate = modeCoordinate
    
    title = modeCoordinate.title ?? "Unknown"
    icon = modeCoordinate.stopModeInfo.image
    iconURL = modeCoordinate.stopModeInfo.imageURL
    
    if let locationID = modeCoordinate.locationID {
      identifier = locationID
    } else {
      identifier = "\(modeCoordinate.stopModeInfo.alt)-\(title)-\(modeCoordinate.coordinate.latitude)-\(modeCoordinate.coordinate.longitude)"
    }
    
    // Note that, the subtitle may be nil at this point, e.g., when
    // modeCoordinate doesn't have an address and reverse geocoding
    // is used to get that. We use RxSwift to respond when the that
    // returns.
    subtitle = modeCoordinate.rx.observe(String.self, "subtitle")
      .asDriver(onErrorJustReturn: nil)
      .startWith(modeCoordinate.subtitle)
    
    distance = target
      .map { $0.coordinate.distance(from: modeCoordinate.coordinate) }
      .asDriver(onErrorJustReturn: nil)
    
    heading = Observable.combineLatest(target, deviceHeading) { (location: $0, heading: $1) }
      .map {
        let itemHeading = modeCoordinate.coordinate.bearing(from: $0.location.coordinate)
        return itemHeading - $0.heading
      }
      .asDriver(onErrorJustReturn: nil)
  }
}

extension CLLocationCoordinate2D {
    
  func degreesToRadians(degrees: Double) -> Double {
    return degrees * .pi / 180.0
  }
  
  func radiansToDegrees(radians: Double) -> Double {
    return radians * 180.0 / .pi
  }
  
  public func bearing(from other: CLLocationCoordinate2D) -> CLLocationDirection {
    let lat1 = degreesToRadians(degrees: latitude)
    let lng1 = degreesToRadians(degrees: longitude)
    
    let lat2 = degreesToRadians(degrees: other.latitude)
    let lng2 = degreesToRadians(degrees: other.longitude)
    
    let lngDelta = lng2 - lng1
    
    let y = sin(lngDelta) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lngDelta)
    var radiansBearing = atan2(y, x)
    if (radiansBearing < 0.0) {
      radiansBearing += 2 * .pi
    }
    
    return radiansToDegrees(radians: radiansBearing)
  }
    
}

extension TKModeInfo {
  
  static func == (lhs: TKModeInfo, rhs: TKModeInfo) -> Bool {
    return
      lhs.identifier == rhs.identifier &&
        lhs.alt == rhs.alt &&
        lhs.localImageName == rhs.localImageName &&
        lhs.remoteImageName == rhs.remoteImageName &&
        lhs.descriptor == rhs.descriptor
  }
  
}

extension TKOnStreetParkingLocation: TKDisplayableRoute {
  
  public var routePath: [Any] {
    guard let polyline = parking.encodedPolyline else { return [] }
    return CLLocation.decodePolyLine(polyline)
  }
  
  public var selectionIdentifier: String? {
    return parking.identifier
  }
  
  public var routeColor: TKColor? {
    // we are using available spaces, instead of total spaces, here because
    // not all parking bays in a segment contains sensor. Available spaces
    // refer to those with sensors.
    guard let vacancy = parking.parkingVacancy else { return nil }
    switch vacancy {
    case .unknown: return #colorLiteral(red: 0.8117647059, green: 0.8, blue: 0.8039215686, alpha: 1)
    case .full: return UIColor.tkStateError
    case .limited: return UIColor.tkStateWarning
    case .plenty: return UIColor.tkStateSuccess
    }
  }
  
  public var routeDashPattern: [NSNumber]? { return nil }
  public var routeIsTravelled: Bool { return true }
}

// MARK: - RxDataSources

extension TKUINearbyViewModel.Item: Equatable {
  
  public static func ==(lhs: TKUINearbyViewModel.Item, rhs: TKUINearbyViewModel.Item) -> Bool {
    return lhs.identifier == rhs.identifier
  }
  
}

extension TKUINearbyViewModel.Item: IdentifiableType {
  public typealias Identity = String
  
  public var identity: Identity {
    return identifier
  }
}


extension TKUINearbyViewModel.Section: AnimatableSectionModelType {
  public typealias Item = TKUINearbyViewModel.Item
  public typealias Identity = String
  
  public init(original: TKUINearbyViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity { return "SingleSection" }
}
