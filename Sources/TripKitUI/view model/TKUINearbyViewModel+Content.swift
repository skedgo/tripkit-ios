//
//  TKUINearbyViewModel+Content.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 27.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TripKit

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
    let mapCenter: CLLocationCoordinate2D
    
    var annotations: [TKModeCoordinate] {
      return locations.filter { !($0 is TKDisplayableRoute) }
    }
    
    var overlays: [MKOverlay] {
      return locations
        .compactMap { $0 as? TKDisplayableRoute }
        .compactMap { TKRoutePolyline(route: $0) }
    }
    
  }
  
  static func buildNearbyLocations(limitTo mode: String?, strictModeMatch: Bool, fixedLocation: MKAnnotation?, mapRect: Driver<MKMapRect?>, refresh: Observable<Void>, onError errorPublisher: PublishSubject<Error>) -> Observable<ViewContent>
  {
    /// Observable combining the user's device location and locations that are nearby.
    /// This includes all nearby locations, regardless of filtering status. To get the
    /// same thing filtered, use `filteredNearby`.
    
    let newRect: Observable<MKMapRect?>
      
    if let fixed = fixedLocation {
      let region = MKCoordinateRegion(center: fixed.coordinate, latitudinalMeters: 750, longitudinalMeters: 750)
      newRect = .just(MKMapRect.forCoordinateRegion(region))
    
    } else {
      newRect = mapRect.asObservable()
      .scan(nil) { good, candidate in
        guard let prev = good, let new = candidate else { return good ?? candidate }
        
        if let distance = prev.centerCoordinate.distance(from: new.centerCoordinate), distance > 250 {
          return new // we moved far enough
        } else if abs(prev.length - new.length) > 500 {
          return new // zoomed in our out
        } else {
          return prev
        }
      }
      .distinctUntilChanged {
        guard let old = $0, let new = $1 else { return false }
        return MKMapRectEqualToRect(old, new)
      }
    }
    
    /// *All* the locations near current coordinate (either from device location
    /// or the user moving the map).
    return Observable.combineLatest(newRect, refresh.startWith(()))
      .flatMapLatest { (mapRect, _) -> Observable<([TKModeCoordinate], CLLocationCoordinate2D)> in
        guard let mapRect = mapRect else { return .just( ([], .invalid) ) }
        let radius = mapRect.length * 1.5
        return TKLocationProvider.fetchLocations(
            center: mapRect.centerCoordinate,
            radius: radius,
            limit: fixedLocation != nil ? 1000 : 100,
            modes: mode.flatMap { [$0] },
            strictModeMatch: strictModeMatch
          )
          .asObservable()
          .catch { error in
            errorPublisher.onNext(error)
            return .just([])
          }
          .map { ($0, mapRect.centerCoordinate) }
      }
      .map { ViewContent(locations: $0.0, mapCenter: $0.1) }
  }
  
  static func filterNearbyContent(_ content: ViewContent, pickedModes: Set<TKModeInfo>?, allModes: [TKModeInfo], focusOn annotation: MKAnnotation?) -> ViewContent {
    if let focus = annotation {
      let byFocus = content.locations.filter { location in
        return location.coordinate.latitude == focus.coordinate.latitude && location.coordinate.longitude == focus.coordinate.longitude
      }
      return ViewContent(locations: byFocus, mapCenter: content.mapCenter)
      
    } else {
      let byModes: [TKModeCoordinate]
      
      if let modes = pickedModes {
        TKUserProfileHelper.update(pickedModes: modes, allModes: Set(allModes))
      }
      
      byModes = content.locations.filter  { location in
        return TKUserProfileHelper.isSharedVehicleModeEnabled(mode: location.stopModeInfo)
      }
      
      return ViewContent(locations: byModes, mapCenter: content.mapCenter)
    }
  }
  
  static func buildSections(content: ViewContent, deviceLocation: Observable<CLLocation>, deviceHeading: Observable<CLLocationDirection>, selectedLocationID: String? = nil) -> [Section] {
    
    // The items also get the device location and heading so that the UI can update accordingly
    // *even if* the number of items or their sort order isn't changing.
    //
    // Note that, we use the `anotations` property of `ViewContent` to build sections. This allows
    // us to exclude elements that are `MKOverlay`, e.g., on-street parking locations. 
    var items = content.annotations.map { Item(for: $0, distanceFrom: deviceLocation, deviceHeading: deviceHeading) }
    
    // We sort by the distance to the centre of the map; might not be idea.
    items.sort {
      if let first = $0.modeCoordinate.coordinate.distance(from: content.mapCenter), let second = $1.modeCoordinate.coordinate.distance(from: content.mapCenter) {
        return first < second
      } else {
        return $0.title < $1.title
      }
    }
    
    // If user selected one from the nearby card, let's move the item to the top.
    if let selected = selectedLocationID, let selectedIndex = items.firstIndex(where: { $0.modeCoordinate.locationID == selected} ) {
      items.swapAt(0, selectedIndex)
    }
    
    return [Section(items:items)]
  }
  
}

// MARK: - Helpers

fileprivate extension MKMapRect {
  var centerCoordinate: CLLocationCoordinate2D {
    return MKMapPoint(x: midX, y: midY).coordinate
  }
  
  var length: CLLocationDistance {
    let metres = MKMetersPerMapPointAtLatitude(centerCoordinate.latitude)
    return max(width, height) * metres
  }
}

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
    let coordinates = CLLocationCoordinate2D.decodePolyline(polyline)
    return coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
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

// MARK: - RxDataSources protocol conformance

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
