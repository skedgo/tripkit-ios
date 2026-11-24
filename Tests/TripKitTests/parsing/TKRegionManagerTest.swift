//
//  TKRegionManagerTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 26.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(Testing)

import Foundation
import Testing

@testable import TripKitAPI
@testable import TripKit

@Suite(.serialized)
struct TKRegionManagerTest {

  private let regionData: Data

  init() async throws {
    regionData = try Self.dataFromJSON(named: "regions")
    let response = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await TKRegionManager.shared.updateRegions(from: response)
  }

  @Test func parsing() {
    #expect(TKRegionManager.shared.hasRegions)
    #expect(TKRegionManager.shared.regions.count == 195)
  }

  @Test func savingToCache() async throws {
    // First read the good data
    let data = TKRegionManager.readLocalCache()
    #expect(data != nil)

    // Then save empty regions data
    let rubbish = try JSONDecoder().decode(TKAPI.RegionsResponse.self, withJSONObject: [
      "regions": [AnyHashable](),
      "modes": [String: AnyHashable](),
      "hashCode": 0
    ] as [String : Any])
    let rubbishData = try JSONEncoder().encode(rubbish)
    await TKRegionManager.shared.updateRegions(from: rubbish)
    TKRegionManager.saveToCache(rubbishData)
    #expect(TKRegionManager.shared.hasRegions)
    #expect(TKRegionManager.shared.regions.count == 0)

    // Then read the good data in again
    let cachedResponse = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await TKRegionManager.shared.updateRegions(from: cachedResponse)
    #expect(TKRegionManager.shared.hasRegions)
    #expect(TKRegionManager.shared.regions.count == 195)
  }

  @Test func sortingModes() {
    let group1 = [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s_bysykkelen",
      "wa_wal"
    ]

    let group2 = [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "ps_tnc_UBER",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s",
      "wa_wal"
    ]

    let group3 = [
      "pt_pub",
      "me_car",
      "me_mot"
    ]

    func toRoutingModes(_ identifiers: [String]) -> [TKRegion.RoutingMode] {
      identifiers.map(TKRegion.RoutingMode.buildForTesting)
    }

    let sorted = TKRegionManager.sortedFlattenedModes([toRoutingModes(group1), toRoutingModes(group2), toRoutingModes(group3)]).map { $0.identifier }

    #expect(sorted == [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "ps_tnc_UBER",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s",
      "wa_wal"
    ])
  }

}

private extension TKRegionManagerTest {

  static func dataFromJSON(named name: String) throws -> Data {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let jsonPath = thisDirectory
      .deletingLastPathComponent()
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name)
      .appendingPathExtension("json")
    return try Data(contentsOf: jsonPath)
  }

}

#endif
