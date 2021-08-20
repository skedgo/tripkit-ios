//
//  TKNamedCoordinate+TKRegion.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension TKNamedCoordinate {
  
  @objc public var regions: Set<TKRegion> {
    return TKRegionManager.shared.localRegions(containing: self.coordinate)
  }
  
}
