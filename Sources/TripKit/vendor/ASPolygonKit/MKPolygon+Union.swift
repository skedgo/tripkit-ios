//
//  MKPolygon+Union.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

import MapKit

extension MKPolygon {
  
  class func union(_ polygons: [MKPolygon], completion: @escaping (Result<[MKPolygon], Error>) -> Void) {
    let queue = DispatchQueue(label: "MKPolygonUnionMerger", qos: .background)
    queue.async {
      let result = Result { try union(polygons) }
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
  
  class func union(_ polygons: [MKPolygon]) throws -> [MKPolygon] {
    let sorted = polygons.sorted(by: { first, second in
      return first.boundingMapRect.distanceFromOrigin < second.boundingMapRect.distanceFromOrigin
    })
    
    return try sorted.reduce([]) { polygons, polygon in
      return try union(polygons, with: polygon)
    }
  }
  
  class func union(_ polygons: [MKPolygon], with polygon: MKPolygon) throws -> [MKPolygon] {
    var grower = Polygon(polygon)
    var newArray: [MKPolygon] = []
    
    for existing in polygons {
      let existingStruct = Polygon(existing)
      if existingStruct.contains(grower) {
        grower = existingStruct
        continue
      }
      let intersections = grower.intersections(existingStruct)
      if intersections.count > 0 {
        let merged = try grower.union(existingStruct, with: intersections)
        if !merged {
          newArray.append(existing)
        }
      } else {
        newArray.append(existing)
      }
    }
    
    newArray.append(grower.polygon)
    return newArray
  }
  
  func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    if (!boundingMapRect.contains(MKMapPoint(coordinate))) {
      return false
    }
    
    // It's in the bounding rect, but is it in the detailed shape?
    let polygon = Polygon(self)
    let point = Point(ll: (coordinate.latitude, coordinate.longitude))
    return polygon.contains(point, onLine: true)
  }
}

extension MKMapRect {
  
  var distanceFromOrigin: Double {
    return sqrt( origin.x * origin.x + origin.y * origin.y )
  }
  
}

