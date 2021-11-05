//
//  MKPolygon+Union.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

import MapKit

extension Polygon {
  static func union(_ polygons: [Polygon]) throws -> [Polygon] {
    let sorted = polygons.sorted { first, second in
      if first.minY < second.minY {
        return true
      } else if second.minY < first.minY {
        return false
      } else {
        return first.minX < second.minX
      }
    }
    
    return try sorted.reduce([]) { polygons, polygon in
      try union(polygons, with: polygon)
    }
  }
  
  static func union(_ polygons: [Polygon], with polygon: Polygon) throws -> [Polygon] {
    var grower = polygon.clockwise()
    var newArray: [Polygon] = []
    
    for existing in polygons {
      if existing.contains(grower) {
        grower = existing
        continue
      }
      let clockwise = existing.clockwise()
      let intersections = grower.intersections(clockwise)
      if intersections.count > 0 {
        let merged = try grower.union(clockwise, with: intersections)
        if !merged {
          newArray.append(clockwise)
        }
      } else {
        newArray.append(clockwise)
      }
    }
    
    newArray.append(grower)
    return newArray
  }
  
}

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
  
  class func union(_ mkPolygons: [MKPolygon]) throws -> [MKPolygon] {
    let polygons = mkPolygons.map(Polygon.init)
    let union = try Polygon.union(polygons)
    return union.map(\.polygon)
  }
  
}
