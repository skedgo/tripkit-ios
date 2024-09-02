//
//  MKPolygon+Union.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

#if canImport(MapKit)
import MapKit
#endif

#if canImport(MapKit)
extension MKPolygon {
  func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
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
  
  var distanceFromOrigin: Double {
    return sqrt( origin.x * origin.x + origin.y * origin.y )
  }
  
}

//MARK: - Compatibility

extension Point {
  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
  
  var annotation: MKPointAnnotation {
    let point = MKPointAnnotation()
    point.coordinate = self.coordinate
    return point
  }
}

extension Line {
  var polyline: MKPolyline {
    var points = [start.coordinate, end.coordinate]
    return MKPolyline(coordinates: &points, count: points.count)
  }
}

extension Polygon {
  /// Creates a new polygon from an `MKPolygon`, ignoring interior polygons
  init(_ polygon: MKPolygon) {
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
  var polygon: MKPolygon {
    var coordinates = points.map { point in
      point.coordinate
    }
    return MKPolygon(coordinates: &coordinates, count: coordinates.count)
  }
}

#endif
