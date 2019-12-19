//
//  TKUIComposingMapManager.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 28.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public class TKUIComposingMapManager: TGMapManager {
  
  let top: TGMapManager
  let bottom: TGMapManager
  
  /// Map manager, that delegates work to the provided component map managers.
  ///
  /// Works best in conjunction with `TKUIMapManager` subclasses, as that'll
  /// make sure that one map manager will properly configure the annotations and
  /// overlays the same another would.
  ///
  /// - Parameters:
  ///   - composing: Will take charge of map *and* be the map's delegate.
  ///   - below: Will take charge of map, but *not* become its delegate.
  public init(composing: TKUIMapManager, onTopOf below: TGMapManager) {
    self.top = composing
    self.bottom = below
  }
  
  public override func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    // Not calling super on purpose. Leave to components.
    
    bottom.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)

    // Called last, so that it'll end up the map's delegate
    top.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
  }
  
  public override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    // Not calling super on purpose. Leave to components.

    top.cleanUp(mapView, animated: animated)
    bottom.cleanUp(mapView, animated: animated)
  }
  
}
