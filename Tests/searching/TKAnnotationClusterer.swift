//
//  TKGeoJSONClusterTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 03.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKGeoJSONClusterTest: XCTestCase {
  
  func testClustering() throws {
    let result = """
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.140531,
          49.45365
        ]
      },
      "properties": {
        "gid": "openstreetmap:venue:way:26962430",
        "layer": "venue",
        "source": "openstreetmap",
        "name": "Großparkplatz Tiergarten",
        "distance": 5.538,
        "label": "Großparkplatz Tiergarten, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.137549,
          49.450693
        ]
      },
      "properties": {
        "gid": "openstreetmap:venue:node:4398847490",
        "layer": "venue",
        "source": "openstreetmap",
        "name": "Tiergarten",
        "distance": 5.545,
        "label": "Tiergarten, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.13771,
          49.450527
        ]
      },
      "properties": {
        "gid": "openstreetmap:address:way:32882349",
        "layer": "address",
        "source": "openstreetmap",
        "name": "Am Tiergarten 31",
        "housenumber": "31",
        "street": "Am Tiergarten",
        "distance": 5.565,
        "label": "Am Tiergarten 31, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.132152,
          49.445979
        ]
      },
      "properties": {
        "gid": "openstreetmap:venue:node:1705484235",
        "layer": "venue",
        "source": "openstreetmap",
        "name": "Wohnstift am Tiergarten",
        "distance": 5.578,
        "label": "Wohnstift am Tiergarten, Nuremberg, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.151276,
          49.491747
        ]
      },
      "properties": {
        "gid": "openstreetmap:venue:node:914609500",
        "layer": "venue",
        "source": "openstreetmap",
        "name": "Tiergarten Nürnberg",
        "distance": 5.613,
        "label": "Tiergarten Nürnberg, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.131896,
          49.445136
        ]
      },
      "properties": {
        "gid": "openstreetmap:venue:way:492670560",
        "layer": "venue",
        "source": "openstreetmap",
        "name": "Wohnstift am Tiergarten",
        "housenumber": "30",
        "street": "Bingstraße",
        "distance": 5.629,
        "label": "Wohnstift am Tiergarten, Nuremberg, Germany"
      },
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.138811,
          49.450018
        ]
      },
      "properties": {
        "gid": "openstreetmap:address:way:185714565",
        "layer": "address",
        "source": "openstreetmap",
        "name": "Am Tiergarten 28",
        "housenumber": "28",
        "street": "Am Tiergarten",
        "distance": 5.663,
        "label": "Am Tiergarten 28, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.139314,
          49.450341
        ]
      },
      "properties": {
        "gid": "openstreetmap:address:way:34091789",
        "layer": "address",
        "source": "openstreetmap",
        "name": "Am Tiergarten 30",
        "housenumber": "30",
        "street": "Am Tiergarten",
        "distance": 5.671,
        "label": "Am Tiergarten 30, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.139102,
          49.449605
        ]
      },
      "properties": {
        "gid": "openstreetmap:address:way:34054282",
        "layer": "address",
        "source": "openstreetmap",
        "name": "Am Tiergarten 30a",
        "housenumber": "30a",
        "street": "Am Tiergarten",
        "distance": 5.707,
        "label": "Am Tiergarten 30a, Germany"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          11.138857,
          49.449128
        ]
      },
      "properties": {
        "gid": "openstreetmap:address:way:34054283",
        "layer": "address",
        "source": "openstreetmap",
        "name": "Am Tiergarten 32",
        "housenumber": "32",
        "street": "Am Tiergarten",
        "distance": 5.725,
        "label": "Am Tiergarten 32, Germany"
      }
    }
  ]
}
"""
    
    let geojson = try JSONDecoder().decode(TKGeoJSON.self, from: result.data(using: .utf8)!)
    
    let annotations = geojson.toNamedCoordinates()
    XCTAssertEqual(annotations.count, 10)
    
    let clusters = TKAnnotationClusterer.cluster(annotations)
    XCTAssertEqual(clusters.count, 5)
  }
  
}
