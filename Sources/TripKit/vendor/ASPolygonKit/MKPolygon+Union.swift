//
//  MKPolygon+Union.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

#if canImport(MapKit)
import MapKit
#endif

extension Polygon {
  public static func union(_ polygons: [Polygon]) throws -> [Polygon] {
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
  
  public static func union(_ polygons: [Polygon], with polygon: Polygon) throws -> [Polygon] {
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

#if canImport(MapKit)
extension MKPolygon {
  
  public class func union(_ polygons: [MKPolygon], completion: @escaping (Result<[MKPolygon], Error>) -> Void) {
    let queue = DispatchQueue(label: "MKPolygonUnionMerger", qos: .background)
    queue.async {
      let result = Result { try union(polygons) }
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
  
  public class func union(_ polygons: [MKPolygon]) throws -> [MKPolygon] {
    let sorted = polygons.sorted(by: { first, second in
      return first.boundingMapRect.distanceFromOrigin < second.boundingMapRect.distanceFromOrigin
    })
    
    return try sorted.reduce([]) { polygons, polygon in
      return try union(polygons, with: polygon)
    }
  }

  
  public class func union(_ polygons: [MKPolygon], with polygon: MKPolygon) throws -> [MKPolygon] {
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
  
  public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    if (!boundingMapRect.contains(MKMapPoint(coordinate))) {
      return false
    }
    
    // It's in the bounding rect, but is it in the detailed shape?
    let polygon = Polygon(self)
    let point = Point(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return polygon.contains(point, onLine: true)
  }
}

extension MKMapRect {
  
  public var distanceFromOrigin: Double {
    return sqrt( origin.x * origin.x + origin.y * origin.y )
  }
  
}

//MARK: - Compatibility

extension Point {
  public var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
  
  public var annotation: MKPointAnnotation {
    let point = MKPointAnnotation()
    point.coordinate = self.coordinate
    return point
  }
}

extension Line {
  public var polyline: MKPolyline {
    var points = [start.coordinate, end.coordinate]
    return MKPolyline(coordinates: &points, count: points.count)
  }
}

extension Polygon {
  /// Creates a new polygon from an `MKPolygon`, ignoring interior polygons
  public init(_ polygon: MKPolygon) {
    let count = polygon.pointCount
    var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
    let range = NSRange(location: 0, length: count)
    polygon.getCoordinates(&coordinates, range: range)
    
    points = coordinates.map { coordinate in
      Point(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    firstLink = Polygon.firstLink(for: points)
  }
  
  /// The polygon as an `MKPolygon`, ignoring interior polygons
  public var polygon: MKPolygon {
    var coordinates = points.map { point in
      point.coordinate
    }
    return MKPolygon(coordinates: &coordinates, count: coordinates.count)
  }
}

#endif
