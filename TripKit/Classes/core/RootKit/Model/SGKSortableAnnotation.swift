//
//  SGKSortableAnnotation.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import MapKit

@objc
public protocol SGKSortableAnnotation : MKAnnotation {
  var sortScore: Int { get }
}
