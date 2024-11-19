//
//  TKSortableAnnotation.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#if canImport(MapKit)

import Foundation
import MapKit

@objc
public protocol TKSortableAnnotation : MKAnnotation {
  var sortScore: Int { get }
}

#endif
