//
//  TKUINearbyMapManager+Home.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/3/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import TripKit

extension TKUINearbyMapManager: TKUICompatibleHomeMapManager {
  public func zoom(to city: TKRegion.City, animated: Bool) {
    mapView?.setCenter(city.coordinate, animated: animated)
  }
  
  public func select(_ annotation: MKAnnotation) {
    mapView?.selectAnnotation(annotation, animated: true)
  }
  
  public var nextFromMap: Observable<TKUIHomeCard.ComponentAction> {
    mapSelection
      .compactMap { [weak self] in
        guard let annotation = $0 else { return nil }
        return .handleSelection(.annotation(annotation), component: self?.viewModel)
      }
      .asObservable()
  }
  
}
