//
//  TKUIHomeCard+MapManager.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 26/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

/// This protocol defines the requirements for any map managers that want
/// to take control of the map in a `TKUIHomeCard`
public protocol TKUICompatibleHomeMapManager: TGCompatibleMapManager {
  
  /// This returns an observable sequence that emits an element whenever an
  /// action is triggered on the map
  var nextFromMap: Observable<TKUIHomeCard.ComponentAction> { get }
  
  /// This returns an observable sequence that emits an element whenever the
  /// map's mapRect changes
  var mapRect: Driver<MKMapRect> { get }
  
  /// This provides you an oppotunity to perform actions on the map when
  /// a `TKUIHomeCard` appears
  /// - Parameter appear: `true` when a home card just appeared
  func onHomeCardAppearance(_ appear: Bool)
  
  /// This is called when the user searches for and selects a city
  func zoom(to city: TKRegion.City, animated: Bool)
  
  /// This allows the map manager to respond to a `TKUIHomeCard`'s request
  /// to select an annotation on the map
  /// - Parameter annotation: The annotation to select on the map.
  func select(_ annotation: MKAnnotation)
  
}
