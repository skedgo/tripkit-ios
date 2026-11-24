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

  /// Replaces the regions with none at all, so this can't use `shared`: other
  /// suites run in parallel and rely on it having regions.
  @Test func savingToCache() async throws {
    let cacheURL = Self.temporaryCacheURL()
    defer { try? FileManager.default.removeItem(at: cacheURL) }
    let manager = TKRegionManager(cacheURL: cacheURL)

    // First save the good data
    let goodResponse = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await manager.updateRegions(from: goodResponse)
    #expect(try Self.cachedRegionCount(at: cacheURL) == 195)

    // Then save empty regions data
    await manager.updateRegions(from: try Self.emptyResponse())
    #expect(manager.hasRegions)
    #expect(manager.regions.count == 0)
    #expect(try Self.cachedRegionCount(at: cacheURL) == 0)

    // Then read the good data in again
    await manager.updateRegions(from: goodResponse)
    #expect(manager.hasRegions)
    #expect(manager.regions.count == 195)
    #expect(try Self.cachedRegionCount(at: cacheURL) == 195)
  }

  /// A read of the cache can finish after newer regions got set in the
  /// meantime, e.g., the one `shared` starts on creation, and must not replace
  /// them with its older ones.
  @Test func loadingFromCacheKeepsNewerRegions() async throws {
    let cacheURL = Self.temporaryCacheURL()
    defer { try? FileManager.default.removeItem(at: cacheURL) }
    let manager = TKRegionManager(cacheURL: cacheURL)

    let goodResponse = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await manager.updateRegions(from: goodResponse)
    let goodCache = try Data(contentsOf: cacheURL)

    await manager.updateRegions(from: try Self.emptyResponse())
    #expect(manager.regions.count == 0)

    // Stands in for a read that started before the update above
    try goodCache.write(to: cacheURL)
    await manager.loadRegionsFromCache()
    #expect(manager.regions.count == 0)
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

  static func temporaryCacheURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("regions-\(UUID().uuidString).json")
  }

  static func emptyResponse() throws -> TKAPI.RegionsResponse {
    try JSONDecoder().decode(TKAPI.RegionsResponse.self, withJSONObject: [
      "regions": [AnyHashable](),
      "modes": [String: AnyHashable](),
      "hashCode": 0
    ] as [String : Any])
  }

  static func cachedRegionCount(at url: URL) throws -> Int? {
    let cached = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: Data(contentsOf: url))
    return cached.regions?.count
  }

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
