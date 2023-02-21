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
  
  // MARK: Union
  
  @discardableResult
  /// Merged the provided polygon into the caller
  /// - Parameter polygon: Polygon to merge into `self`
  /// - Returns: Whether the polygon was merged; return `false` if there's no overlap
  mutating func union(_ polygon: Polygon) throws -> Bool {
    let intersections = self.intersections(polygon)
    if intersections.count == 0 {
      return false
    }
    
    return try union(polygon, with: intersections, allowInverting: true)
  }
  
  @discardableResult
  mutating func union(_ polygon: Polygon, with intersections: [Intersection]) throws -> Bool {
    try union(polygon, with: intersections, allowInverting: true)
  }
  
  private mutating func union(_ polygon: Polygon, with intersections: [Intersection], allowInverting: Bool) throws -> Bool {
    if polygon.points.count < 3 || points.count < 3 {
      throw PolygonUnionError.invalidPolygon
    }
    if intersections.count == 0 {
      return false
    }
    
    var startLink: LinkedLine = firstLink
    
    // We need to start with a link that starts outside the polygon
    // that we are trying to add.
    while polygon.contains(startLink.line.start, onLine: true) {
      if let next = startLink.next {
        startLink = next
      } else {
        break
      }
    }
    if polygon.contains(startLink.line.start, onLine: true) {
      // This polygon is (deemed to be) a subset of the polygon that you're
      // trying to merge into it. If this happens, we try it  the other way
      // around.
      if allowInverting {
        var grower = polygon
        let invertedIntersections = grower.intersections(self)
        let merged = try grower.union(self, with: invertedIntersections, allowInverting: false)
        if merged {
          self = grower
          return true
        } else {
          return false
        }
      } else {
        throw PolygonUnionError.polygonIsSubset
      }
    }
    
    let startPoint = startLink.line.start
    var current = (point: startLink.line.start, link: startLink, onMine: true)

    var remainingIntersections = intersections
    var newPoints: [Point] = []
    
    #if DEBUG
    var steps: [UnionStep] = [
      .start(self, polygon, intersections, start: startPoint)
    ]
    #endif
    
    repeat {
      Polygon.append(current.point, to: &newPoints)
      
      #if DEBUG
      steps.append(current.onMine ? .extendMine(partial: newPoints) : .extendYours(partial: newPoints))
      #endif
      
      if newPoints.count - points.count > polygon.points.count * 2 {
        #if DEBUG
        print("Could not merge\n\n\(polygon.encodeCoordinates())\n\ninto\n\n\(encodeCoordinates())\n\n")
        throw PolygonUnionError.polygonTooComplex(steps)
        #else
        throw PolygonUnionError.polygonTooComplex
        #endif
      }
      
      let candidates = Polygon.potentialIntersections(
        in: remainingIntersections,
        startingAt: current.point,
        on: current.link,
        polygonStart: (mine: firstLink, yours: polygon.firstLink)
      )

      if let (index, closest, newOnMine) = closestIntersection(candidates, to: current.point), newOnMine != current.onMine {
        #if DEBUG
        steps.append(.intersect(closest, onMine: newOnMine))
        #endif
        
        remainingIntersections.remove(at: index)
        current = (point: closest.point, link: (newOnMine ? closest.mine : closest.yours).last!, onMine: newOnMine)
      
      } else {

        // the linked lines do not wrap around themselves, so we do that here manually
        let next: LinkedLine
        if let nextInPoly = current.link.next {
          next = nextInPoly
        } else if current.onMine {
          next = firstLink
        } else {
          next = polygon.firstLink
        }
        current = (point: next.line.start, link: next, onMine: current.onMine)
      }
      
    } while current.point != startPoint
    
    assert(newPoints.count > 2, "Should never end up with a line (or less) after merging")
    points = newPoints
    if points.first != points.last, let first = points.first {
      points.append(first)
    }
    
    #if DEBUG
//    let stepsGeoJSON: [String: Any] = [
//      "type": "FeatureCollection",
//      "features": steps.flatMap { $0.toGeoJSON(startOnly: false) }
//    ]
//    print(String(decoding: try JSONSerialization.data(withJSONObject: stepsGeoJSON, options: []), as: UTF8.self))
    #endif
    
    return true
  }
  
  
  fileprivate static func potentialIntersections(
    in intersections: [Intersection],
    startingAt start: Point,
    on link: LinkedLine,
    polygonStart: (mine: LinkedLine, yours: LinkedLine)
  ) -> [(Int, Intersection, Bool)] {
    
    var lineIntersections: [(Int, Intersection, Bool)] = []
    for (index, intersection) in intersections.enumerated() {
      // The intersection applies if it's for the same link AND if the intersection's point is on that link between `start` and the intersection's end, i.e., we can't go back if `start` is already further along the link than the intersections' point.
      guard intersection.appliesTo(link, start: start) else { continue }
      
      // The two lines intersection. For this intersection we want to continue on the one which has a smaller clock wise angle.
      // We compare your angle `line.start - point - other.line.end` to mine `line.start - point - line.end`.
      // It is possible that `point == other.line.end` in that case, we take the angle to `other.next.line.end`. Same thing with `point == line.end` in which case we compare to the angle to `line.next.end`
      
      let point = intersection.point
      
      func findAngle(for links: [LinkedLine], lastPoint: Point) -> (angle: Double, end: Point) {
        return links.map { link in
          let link = links.last!
          let end: Point
          if point == link.line.end {
            if let next = link.next {
              end = next.line.end
            } else {
              end = lastPoint
            }
          } else {
            end = link.line.end
          }
          
          let angle = calculateAngle(start: start, middle: point, end: end)
          return (angle, end)
        }.min { $0.angle < $1.angle }!
      }
      
      let (yourAngle, yourEnd) = findAngle(for: intersection.yours, lastPoint: polygonStart.yours.line.end)
      let (myAngle, myEnd) = findAngle(for: intersection.mine, lastPoint: polygonStart.mine.line.end)
      
      let continueOnMine: Bool
      
      if myAngle < yourAngle {
        continueOnMine = true
      } else if (yourAngle < myAngle) {
        continueOnMine = false
      } else {
        let myDistance = point.distance(from: myEnd)
        let yourDistance = point.distance(from: yourEnd)
        continueOnMine = myDistance > yourDistance
      }
      let candidate = (index, intersection, continueOnMine)
      lineIntersections.append(candidate)
    }
    
    return lineIntersections
    
  }
  

  fileprivate static func append(_ point: Point, to points: inout [Point]) {
    // 1) if we don't have a last point, just append it
    // 2) if we have a previous point and this is the same, skip it
    // 3) if we have two previous points and this is on the same line then remove the previous point and insert this one
    // 4) otherwise, append it
    if let last = points.last {
      if last == point {
        return // 2)
      }
      
      if points.count - 2 >= 0 {
        let lastLast = points[points.count - 2]
        if point != lastLast {
          let spanner = Line(start: lastLast, end: point)
          let next = Line(start: last, end: point)
          if (abs(spanner.m) > 1_000_000 && abs(next.m) > 1_000_000) // takes care of both being Infinity
              || abs(spanner.m - next.m) < 0.0001 {
            points.removeLast() // 3)
          }
        }
      }
    }
    
    points.append(point) // 1, 3, 4)
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
