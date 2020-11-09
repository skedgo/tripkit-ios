//
//  MKPolygon+Union.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

import MapKit

extension MKPolygon {
  
  @objc(unionOfPolygons:completionHandler:)
  class func union(_ polygons: [MKPolygon], completion: @escaping ([MKPolygon]) -> Void) {
    let queue = DispatchQueue(label: "MKPolygonUnionMerger", qos: .background)
    queue.async {
      let result = union(polygons)
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
  
  @objc(unionOfPolygons:)
  class func union(_ polygons: [MKPolygon]) -> [MKPolygon] {
    
    let sorted = polygons.sorted(by: { first, second in
      return first.boundingMapRect.distanceFromOrigin < second.boundingMapRect.distanceFromOrigin
    })
    
    return sorted.reduce([]) { polygons, polygon in
      return union(polygons, with: polygon)
    }
    
    //    return polygons.reduce([]) { polygons, polygon in
    //      return union(polygons, with: polygon)
    //    }
    
  }
  
  @objc(unionOfPolygons:withPolygon:)
  class func union(_ polygons: [MKPolygon], with polygon: MKPolygon) -> [MKPolygon] {
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
        do {
          try grower.union(existingStruct, with: intersections)
        } catch {
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

