//
//  Polygon+GeoJSON.swift
//
//
//  Created by Adrian Schönig on 4/11/21.
//

import Foundation

extension Point {
  var geoJSON: [String: Any] {
    [
      "type": "Point",
      "coordinates": [x, y]
    ]
  }
}

extension Line {
  var geoJSON: [String: Any] {
    [
      "type": "LineString",
      "coordinates": [
        [start.x, start.y],
        [end.x, end.y]
      ]
    ]
  }
}

extension Intersection {
  var geoJSON: [String: Any] {
    [
      "type": "GeometryCollection",
      "geometries": [point.geoJSON] + (mine + yours).map(\.line.geoJSON)
    ]
  }
}

extension Polygon {
  var geoJSON: [String: Any] {
    [
      "type": "Polygon",
      "coordinates": [
        points.map { [$0.x, $0.y] }
      ]
    ]
  }
}

#if DEBUG
extension Polygon.UnionStep {
  func toGeoJSON(startOnly: Bool) -> [[String: Any]] {
    switch self {
    case let .start(mine, yours, intersections, start):
      if startOnly {
        var features: [[String: Any]] = [
          [
            "type": "Feature",
            "properties": ["name": "Mine"],
            "geometry": mine.geoJSON
          ], [
            "type": "Feature",
            "properties": ["name": "Yours"],
            "geometry": yours.geoJSON,
          ], [
            "type": "Feature",
            "properties": ["name": "Start"],
            "geometry": start.geoJSON
          ]
        ]
        features.append(contentsOf: intersections.enumerated().map { index, inter in
          [
            "type": "Feature",
            "properties": ["name": "Intersection \(index)"],
            "geometry": inter.geoJSON
          ]
        })
        return features
      } else {
        return [[
          "type": "Feature",
          "properties": ["name": "Start"],
          "geometry": [
            "type": "GeometryCollection",
            "geometries": [
              mine.geoJSON,
              yours.geoJSON,
              start.geoJSON
            ]
          ] as [String : Any]
        ]]
      }
      
    case let .extendYours(points):
      guard !startOnly else { return [] }
      
      return [[
        "type": "Feature",
        "properties": ["name": "On yours"],
        "geometry": [
          "type": "LineString",
          "coordinates": points.map { [$0.x, $0.y] }
        ] as [String : Any]
      ]]

    case let .extendMine(points):
      guard !startOnly else { return [] }
      
      return [[
        "type": "Feature",
        "properties": ["name": "On mine"],
        "geometry": [
          "type": "LineString",
          "coordinates": points.map { [$0.x, $0.y] }
        ] as [String : Any]
      ]]
      
    case let .intersect(intersection, onMine):
      guard !startOnly else { return [] }

      return [[
        "type": "Feature",
        "properties": ["name": "Intersecting on \(onMine ? "mine" : "yours")"],
        "geometry": intersection.geoJSON
      ]]
    }
  }
}
#endif
