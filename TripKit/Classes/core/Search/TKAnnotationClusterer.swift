//
//  TKAnnotationClusterer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 03.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import MapKit

protocol TKClusterable: MKAnnotation {
  var clusterIdentifier: String? { get }
}

class TKAnnotationClusterer {
  private init() {
  }
  
  static func cluster(_ annotations: [MKAnnotation]) -> [MKAnnotation] {
    return annotations
      .reduce(into: [TKClusterAnnotation]()) { acc, annotation in
        for existing in acc {
          if existing.absorb(annotation) {
            return
          }
        }
        acc.append(TKClusterAnnotation(memberAnnotations: [annotation]))
      }
      .compactMap {
        return $0.memberAnnotations.count > 1 ? $0 : $0.memberAnnotations.first
      }
  }
}

class TKClusterAnnotation: NSObject {
  var memberAnnotations: [MKAnnotation]
  let clusterIdentifier: String?
  
  init(memberAnnotations: [MKAnnotation]) {
    self.memberAnnotations = memberAnnotations
    self.clusterIdentifier = (memberAnnotations.first as? TKClusterable)?.clusterIdentifier
    super.init()
  }
  
  func absorb(_ annotation: MKAnnotation) -> Bool {
    guard
      let clusterable = annotation as? TKClusterable,
      clusterIdentifier == clusterable.clusterIdentifier,
      let distance = coordinate.distance(from: clusterable.coordinate),
      distance < 250 else {
        return false
    }
    
    memberAnnotations.append(annotation)
    return true
  }
}

extension TKClusterAnnotation: TKClusterable {
  var coordinate: CLLocationCoordinate2D {
    return memberAnnotations.first?.coordinate ?? kCLLocationCoordinate2DInvalid
  }
  
  var title: String? {
    // TODO: Could be smarter and try to find a minimalist title
    return memberAnnotations.first?.title ?? nil
  }
  
  var subtitle: String? {
    // TODO: Could alternatively show the number of additional things in the cluster
    return memberAnnotations.first?.subtitle ?? nil
  }
}
