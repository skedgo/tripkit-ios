//
//  SGKNamedCoordinate+SVKRegion.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension SGKNamedCoordinate {
  
  @objc public var regions: Set<SVKRegion> {
    return TKRegionManager.shared.localRegions(for: self.coordinate)
  }
  
}
