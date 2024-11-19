//
//  Geometry.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

import Foundation

public struct Point: Hashable {
  // MARK: Point as a lat/long pair
  
  public init(latitude: Double, longitude: Double) {
    self.y = latitude
    self.x = longitude
  }
  
  var lat: Double { y }
  var lng: Double { x }
  
  var description: String {
    String(format: "(%.6f,%.6f)", lat, lng)
  }
  
  // MARK: Point as a x/y pair
  // It's easier to do math using own x/y values as lat/longs can be confusing mathematically as they don't follow the directions of the typical x/y coordinate system. latitudes are positive up, longitudes are positive right, while we'd like x to be positive right and y to be positive up.
  
  let x: Double
  let y: Double
  
  init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
  
  // MARK: Pythagoras
  func distance(from point: Point) -> Double {
    let delta_x = point.x - x
    let delta_y = point.y - y
    return sqrt(delta_y * delta_y + delta_x * delta_x)
  }
}

extension Point: Equatable {}
public func ==(lhs: Point, rhs: Point) -> Bool {
  let epsilon = 0.000001
  return abs(lhs.lat - rhs.lat) < epsilon
      && abs(lhs.lng - rhs.lng) < epsilon
}

/// A line is defined by two points
struct Line: Hashable {
  let start: Point
  let end: Point

  // Inferred from start + end
  let m: Double
  let b: Double
  
  init(start: Point, end: Point) {
    assert(start != end)
    
    self.start = start
    self.end = end
    
    if (end.x == start.x) {
      m = Double.infinity
    } else {
      m = (end.y - start.y) / (end.x - start.x)
    }
    
    if m == Double.infinity {
      b = 0
    } else {
      b = start.y - m * start.x
    }
    
  }
  
  // MARK: Mathmatical formula
  // Special care needs to be taken where start.x == end.x, i.e., vertical lines.
  
  var formula: String {
    if m == Double.infinity {
      return "y = *"
    } else {
      return String(format: "y = %.1f x + %.1f", m, b)
    }
  }
  
  var description: String {
    return String(format: "%@ - %@", start.description, end.description)
  }
  
  //MARK: Contains check
  
  func contains(_ point: Point) -> Bool {
    if m == Double.infinity {
      return inRange( (point.x, point.y) )
    }
    
    let epsilon = 0.000001
    let y = m * point.x + b
    if abs(y - point.y) < epsilon {
      return inRange( (point.x, point.y) )
    } else {
      return false
    }
  }
  
  //MARK: Intersection of lines
  
  func inRange(_ xy: (Double, Double)) -> Bool {
    let x = xy.0
    let y = xy.1
    return x.inBetween(start.x, and: end.x)
        && y.inBetween(start.y, and: end.y)
  }
  
  func intersection(with line: Line) -> Point? {
    // The intersection is where the two lines meet. Mathematically that's by solving the two formulae. Since these lines have a specific start + end, we also need to check that the intersection lies within the range.
    // Special care needs to be taken where start.x == end.x, i.e., vertical lines.
    
    if (m == line.m) {
      if inRange( (line.start.x, line.start.y) ) {
        return line.start
      } else if line.inRange( (start.x, start.y )) {
        return start
      } else {
        return nil
      }
    }
    
    var x : Double
    if (m == Double.infinity) {
      x = start.x
    } else if (line.m == Double.infinity) {
      x = line.start.x
    } else {
      x = (line.b - b) / (m - line.m)
    }
    
    var y : Double
    if (m == Double.infinity) {
      y = line.m * x + line.b
    } else {
      y = m * x + b
    }
    
    if (inRange((x, y)) && line.inRange((x, y))) {
      return Point(x: x, y: y)
    }
    return nil
  }
}

extension Double {
  func inBetween(_ some: Double, and another: Double) -> Bool {
    let eps = 0.000001
    return self >= min(some, another) - eps && self <= max(some, another) + eps
  }
}
