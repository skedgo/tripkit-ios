//
//  TKLocationRestorationTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 25.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

import CoreLocation

@testable import TripKit

class TKLocationRestorationTest: XCTestCase {
    
  func testRestoringNamedCoordinate() {
    let namedCoordinate = SGKNamedCoordinate(latitude: 10, longitude: 10, name: "Name", address: "Address")
    
    let archiver = NSKeyedArchiver()
    archiver.encode(namedCoordinate)
    
    let unarchiver = NSKeyedUnarchiver(forReadingWith: archiver.encodedData)
    let restored = unarchiver.decodeObject() as? SGKNamedCoordinate
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored?.coordinate.latitude, namedCoordinate.coordinate.latitude)
    XCTAssertEqual(restored?.coordinate.longitude, namedCoordinate.coordinate.longitude)
    XCTAssertEqual(restored?.name, namedCoordinate.name)
    XCTAssertEqual(restored?.address, namedCoordinate.address)
  }
  
  func testRestoringStop() throws {
    let stop = try JSONDecoder().decode(STKStopCoordinate.self, withJSONObject: [
      "address": "Blacktown Station Platform 1",
      "class": "StopLocation",
      "code": "2148531",
      "id": "2148531",
      "lat": -33.76815,
      "lng": 150.90801,
      "modeInfo": [
        "alt": "train",
        "identifier": "pt_pub_train",
        "localIcon": "train"
      ],
      "name": "Blacktown Station Platform 1",
      "popularity": 2075,
      "services": "T1, T5",
      "shortName": "Platform 1",
      "stopCode": "2148531",
      "stopType": "train",
      "timezone": "Australia/Sydney",
      "wheelchairAccessible": true
      ]
    )
    
    let archiver = NSKeyedArchiver()
    archiver.encode(stop)
    
    let unarchiver = NSKeyedUnarchiver(forReadingWith: archiver.encodedData)
    let restored = unarchiver.decodeObject() as? STKStopCoordinate
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored?.coordinate.latitude, stop.coordinate.latitude)
    XCTAssertEqual(restored?.coordinate.longitude, stop.coordinate.longitude)
    XCTAssertEqual(restored?.name, stop.name)
    XCTAssertEqual(restored?.address, stop.address)
    XCTAssertEqual(restored?.stopCode, stop.stopCode)
    XCTAssertEqual(restored?.stopModeInfo.identifier, stop.stopModeInfo.identifier)
  }
  
  func testRestoringCarPod() throws {
    let pod = try JSONDecoder().decode(TKCarPodLocation.self, withJSONObject: [
      "address": "Mullens Street, Balmain",
      "carPod": [
        "identifier": "CND-AU_NSW_Sydney-418",
        "operator": [
          "color": [
            "blue": 134,
            "green": 82,
            "red": 253
          ],
          "name": "Car Next Door",
          "remoteIcon": "carnextdoor",
          "website": "http://www.carnextdoor.com.au"
        ],
        "vehicles": [
          [
            "description": "Volkswagen Golf\n2006 Grey Volkswagen Golf MANUAL",
            "name": "Car Next Door"
          ]
        ]
      ],
      "class": "CarPodLocation",
      "id": "CND-AU_NSW_Sydney-418",
      "lat": -33.86199,
      "lng": 151.17608,
      "modeInfo": [
        "alt": "Car Next Door",
        "color": [
          "blue": 134,
          "green": 82,
          "red": 253
        ],
        "description": "Car Next Door",
        "identifier": "me_car-s_CND",
        "localIcon": "car-share",
        "remoteIcon": "carnextdoor"
      ],
      "name": "Car Next Door",
      "timezone": "Australia/Sydney"
      ]
    )
    
    let archiver = NSKeyedArchiver()
    archiver.encode(pod)
    
    let unarchiver = NSKeyedUnarchiver(forReadingWith: archiver.encodedData)
    let restored = unarchiver.decodeObject() as? TKCarPodLocation
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored?.coordinate.latitude, pod.coordinate.latitude)
    XCTAssertEqual(restored?.coordinate.longitude, pod.coordinate.longitude)
    XCTAssertEqual(restored?.name, pod.name)
    XCTAssertEqual(restored?.address, pod.address)
    XCTAssertEqual(restored?.stopModeInfo.identifier, pod.stopModeInfo.identifier)
    XCTAssertEqual(restored?.carPod.operatorInfo.name, pod.carPod.operatorInfo.name)
  }
  
  func testRestoringCarPark() throws {
    let park = try! JSONDecoder().decode(TKCarParkLocation.self, withJSONObject: [
      "address": "Park Street & Pitt Street",
      "carPark": [
        "identifier": "CAR_PARK_20827842",
        "name": "Hilton Sydney",
        "openingHours": [
          "days": [
            [
              "name": "MONDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "0:00"
                ],
                [
                  "closes": "24:00",
                  "opens": "17:00"
                ]
              ]
            ],
            [
              "name": "TUESDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "0:00"
                ],
                [
                  "closes": "24:00",
                  "opens": "17:00"
                ]
              ]
            ],
            [
              "name": "WEDNESDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "0:00"
                ],
                [
                  "closes": "24:00",
                  "opens": "17:00"
                ]
              ]
            ],
            [
              "name": "THURSDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "0:00"
                ],
                [
                  "closes": "24:00",
                  "opens": "17:00"
                ]
              ]
            ],
            [
              "name": "FRIDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "0:00"
                ],
                [
                  "closes": "24:00",
                  "opens": "17:00"
                ]
              ]
            ],
            [
              "name": "SATURDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "6:00"
                ]
              ]
            ],
            [
              "name": "SUNDAY",
              "times": [
                [
                  "closes": "24:00",
                  "opens": "6:00"
                ]
              ]
            ]
          ],
          "timeZone": "Australia/Sydney"
        ],
        "operator": [
          "name": "Hilton Sydney",
          "website": "http://au.parkopedia.com/parking/carpark/hilton_sydney/2000/sydney_cbd/"
        ],
        "pricingTables": [
          [
            "currency": "AUD",
            "currencySymbol": "$",
            "entries": [
              [
                "duration": 3600,
                "label": "",
                "price": 20.0
              ],
              [
                "duration": 7200,
                "label": "",
                "price": 25.0
              ],
              [
                "duration": 86400,
                "label": "",
                "price": 29.0
              ]
            ],
            "title": "Mon-Fri 17:00-24:00 | Sat-Sun 6:00-24:00"
          ],
          [
            "currency": "AUD",
            "currencySymbol": "$",
            "entries": [
              [
                "duration": 1800,
                "label": "",
                "price": 8.0
              ],
              [
                "duration": 3600,
                "label": "",
                "price": 29.0
              ],
              [
                "duration": 7200,
                "label": "",
                "price": 65.0
              ],
              [
                "duration": 10800,
                "label": "",
                "price": 79.0
              ],
              [
                "duration": 86400,
                "label": "",
                "price": 84.0
              ]
            ],
            "title": "Mon-Fri 24hs"
          ]
        ]
      ],
      "class": "CarParkLocation",
      "id": "CAR_PARK_20827842",
      "lat": -33.87312,
      "lng": 151.20813,
      "modeInfo": [
        "alt": "Car park",
        "localIcon": "parking"
      ],
      "name": "Hilton Sydney",
      "timezone": "Australia/Sydney"
      ]
    )
    
    let archiver = NSKeyedArchiver()
    archiver.encode(park)
    
    let unarchiver = NSKeyedUnarchiver(forReadingWith: archiver.encodedData)
    let restored = unarchiver.decodeObject() as? TKCarParkLocation
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored?.coordinate.latitude, park.coordinate.latitude)
    XCTAssertEqual(restored?.coordinate.longitude, park.coordinate.longitude)
    XCTAssertEqual(restored?.name, park.name)
    XCTAssertEqual(restored?.address, park.address)
    XCTAssertEqual(restored?.stopModeInfo.identifier, park.stopModeInfo.identifier)
    XCTAssertNotNil(restored?.carPark.pricingTables)
    XCTAssertEqual(restored?.carPark.pricingTables?.count, park.carPark.pricingTables?.count)
    XCTAssertEqual(restored?.carPark.pricingTables?.first?.entries.count, park.carPark.pricingTables?.first?.entries.count)
    XCTAssertNotNil(restored?.carPark.openingHours)
    XCTAssertNotNil(restored?.carPark.operatorInfo)
    XCTAssertEqual(restored?.carPark.operatorInfo?.name, park.carPark.operatorInfo?.name)
  }
}
