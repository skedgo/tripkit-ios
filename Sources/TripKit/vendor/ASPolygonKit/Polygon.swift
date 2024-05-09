//
//  Polygon.swift
//
//  Created by Adrian Schoenig on 18/2/17.
//
//

import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

typealias TKPolygon = Polygon

enum PolygonUnionError: Error, CustomDebugStringConvertible {
  
  #if DEBUG
  case polygonTooComplex([Polygon.UnionStep])
  #else
  case polygonTooComplex
  #endif
  case polygonIsSubset
  case invalidPolygon
  
  var debugDescription: String {
    switch self {
    case .polygonTooComplex: return "polygonTooComplex"
    case .polygonIsSubset: return "polygonIsSubset"
    case .invalidPolygon: return "invalidPolygon"
    }
  }
  
}

struct Polygon {
  #if DEBUG
  enum UnionStep {
    case start(Polygon, Polygon, [Intersection], start: Point)
    case extendMine(partial: [Point])
    case extendYours(partial: [Point])
    case intersect(Intersection, onMine: Bool)
  }
  #endif
  
  var points: [Point] {
    didSet {
      firstLink = Polygon.firstLink(for: points)
    }
  }
  
  var firstLink: LinkedLine
  
  init(pairs: [(Double, Double)]) {
    self.init(points: pairs.map { pair in
      Point(latitude: pair.0, longitude: pair.1)
    })
  }
  
  init(points: [Point]) {
    self.points = points
    firstLink = Polygon.firstLink(for: points)
  }

  
  // MARK: Basic info
  
  var description: String? {
    return points.reduce("[ ") { previous, point in
      let start = previous.utf8.count == 2 ? previous : previous + ", "
      return start + point.description
      } + " ]"
  }
  
  var minY: Double {
    return points.reduce(Double.infinity) { acc, point in
      return Double.minimum(acc, point.y)
    }
  }
  
  var maxY: Double {
    return points.reduce(Double.infinity * -1) { acc, point in
      return Double.maximum(acc, point.y)
    }
  }
  
  var minX: Double {
    return points.reduce(Double.infinity) { acc, point in
      return Double.minimum(acc, point.x)
    }
  }
  
  var maxX: Double {
    return points.reduce(Double.infinity * -1) { acc, point in
      return Double.maximum(acc, point.x)
    }
  }
  
  #if canImport(CoreGraphics)
  var boundingRect: CGRect {
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
  }
  #endif
  
  func isClockwise() -> Bool {
    var points: [Point] = self.points
    if let first = points.first, first != points.last {
      points.append(first)
    }
    
    let offsetPoints: [Point] = Array(points[1...] + [points[0]])
    let signedArea: Double = zip(points, offsetPoints).reduce(0) { area, pair in
      area + pair.0.x * pair.1.y - pair.1.x * pair.0.y
    }
    // Note: Actual area is `signedArea / 2`, but we just care about sign
    // Negative points means clock-wise; positive means counter-clockwise
    return signedArea < 0
  }
  
  func clockwise() -> Polygon {
    let result = isClockwise() ? self : Polygon(points: points.reversed())
    assert(result.isClockwise())
    return result
  }
  
  // MARK: Polygon as list of lines
  
  static func firstLink(for points: [Point]) -> LinkedLine {
    var first: LinkedLine? = nil
    var previous: LinkedLine? = nil
    for (index, point) in points.enumerated() {
      let nextIndex = (index == points.endIndex - 1) ? points.startIndex : index + 1
      let next = points[nextIndex]
      if next != point {
        let line = Line(start: point, end: next)
        let link = LinkedLine(line: line, next: nil)
        if first == nil {
          first = link
        }
        previous?.next = link
        previous = link
      }
    }
    return first!
  }
  
  // MARK: Polygon to polygon intersections
  
  func intersects(_ polygon: Polygon) -> Bool {
    return intersections(polygon).count > 0
  }
  
  func intersections(_ polygon: Polygon) -> [Intersection] {
    var intersections : [Intersection] = []
    for link in firstLink {
      for other in polygon.firstLink {
        if let point = link.line.intersection(with: other.line) {
          
          if let index = intersections.firstIndex(where: { $0.point == point} ) {
            // Account for the case where the intersection is at a corner of the polygon
            var updated = intersections[index]
            if !updated.mine.contains(link) {
              updated.mine.append(link)
            }
            if !updated.yours.contains(other) {
              updated.yours.append(other)
            }
            intersections[index] = updated

          } else {
            let intersection = Intersection(point: point, mine: [link], yours: [other])
            intersections.append(intersection)
          }

        }
      }
    }
    return intersections
  }
  
  // MARK: Contains point check
  
  fileprivate func numberOfIntersections(_ line: Line) -> Int {
    var count = 0
    for link in firstLink {
      if let point = link.line.intersection(with: line) {
        if point != line.start && point != line.end {
          count += 1
        }
      }
    }
    return count
  }
  
  /// Check if the polygon contains a point
  /// - Parameters:
  ///   - point: The point to check
  ///   - onLine: `true` if the contains check should succeed when the point is right on the edge of the polygon
  /// - Returns: Whether the polygon contains the point
  func contains(_ point: Point, onLine: Bool) -> Bool {
    if onLine {
      for link in firstLink {
        if link.line.contains(point) {
          return true
        }
      }
    }
    
    let ray = Line(start: point, end: Point(x: 0, y: 0)) // assuming no polygon contains the coast of africa
    return numberOfIntersections(ray) % 2 == 1
  }
  
  /// Checks if the polygon contains the provided polygon
  /// - Parameter polygon: The polygon to check for containment
  /// - Returns: Whether `self` contains `polygon`, ignoring interior polygons of either
  func contains(_ polygon: Polygon) -> Bool {
    for point in polygon.points {
      if !contains(point, onLine: false) {
        return false
      }
    }
    return true
  }

}

// To find the polygon between the two polygons, we see if there's an intersection between each pair of lines between the polygons. First we need to get the lines in a polygon.

class LinkedLine: Sequence, Equatable {
  let line: Line
  var next: LinkedLine?
  
  init(line: Line, next: LinkedLine?) {
    self.line = line
    self.next = next
  }
  
  func makeIterator() -> AnyIterator<LinkedLine> {
    var this: LinkedLine? = self
    return AnyIterator {
      let ret = this
      this = this?.next
      return ret
    }
  }
}

func ==(lhs: LinkedLine, rhs: LinkedLine) -> Bool {
  return lhs.line == rhs.line
}


// Let's calculate the intersections and keep for each intersection information about which line this intersection is with

struct Intersection {
  let point: Point
  var mine: [LinkedLine]
  var yours: [LinkedLine]
  
  fileprivate func appliesTo(_ link: LinkedLine, start: Point) -> Bool {
    guard mine.contains(link) || yours.contains(link) else { return false }
    
    let linkStart = link.line.start
    let toPoint = point.distance(from: linkStart)
    let toStart = start.distance(from: linkStart)
    return toStart <= toPoint
  }
  
}

// For this exercise we assume that one polygon is never part of another, so we only need to deal with two cases: There's an overlap or there's none. Note, that if there's an overlap, we should have at least two intersection points.
// What do we do with the intersections?
// For each line that intersects we need to deal with the case that it has multiple intersections. Typically we are only concerned about the closest then.

private func closestIntersection(_ intersections: [(Int, Intersection, Bool)], to point: Point) -> (Int, Intersection, Bool)? {
  if (intersections.count <= 1) {
    return intersections.first
  } else {
    // the closest is the one with the least distance from the points to the intersection
    return intersections.reduce(nil) { prior, entry in
      if prior == nil || entry.1.point.distance(from: point) < prior!.1.point.distance(from: point) {
        return entry
      } else {
        return prior
      }
    }
  }
}

private func calculateAngle(start: Point, middle: Point, end: Point) -> Double {
  let v1 = Point(x: start.x - middle.x, y: start.y - middle.y)
  let v2 = Point(x: end.x - middle.x, y: end.y - middle.y)
  let arg1 = v1.x * v2.y - v1.y * v2.x
  let arg2 = v1.x * v2.x + v1.y * v2.y
  let atan = atan2(arg1, arg2)
  let degrees = atan * -180/Double.pi
  if degrees < 0 {
    return degrees + 360
  } else {
    return degrees
  }
}
