//
//  TKUIRoutingResultsViewModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 16/2/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import MapKit

@testable import TripKit
@testable import TripKitUI

final class TKUIRoutingResultsViewModelTest: XCTestCase {
  
  override func setUp() async throws {
    try await super.setUp()

    TKUIRoutingResultsCard.config = .empty
    TKSettings.hiddenModeIdentifiers = []
    TKSettings.showWheelchairInformation = false
  }
  
  override func tearDown() {
    TKUIRoutingResultsCard.config = .empty
    super.tearDown()
  }
  
  func testDefaultModes() {
    let available: [TKTransportMode] = [
      .publicTransport,
      .bicycle, .bicycleShared,
      .car,
      .walking, .wheelchair
    ]
    let adjusted = TKSettings.adjustedEnabledModeIdentifiers(available.map(\.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.publicTransport.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.bicycle.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.bicycleShared.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.car.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.walking.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.wheelchair.modeIdentifier))
  }
  
  func testDefaultModesSansWheelchairSettings() {
    TKSettings.showWheelchairInformation = true
    
    let available: [TKTransportMode] = [
      .publicTransport,
      .bicycle, .bicycleShared,
      .car,
      .walking, .wheelchair
    ]
    let adjusted = TKSettings.adjustedEnabledModeIdentifiers(available.map(\.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.publicTransport.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.bicycle.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.bicycleShared.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.car.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.walking.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.wheelchair.modeIdentifier))
  }
  
  func testEnablingWheelchairAutodisablesOtherModes() {
    XCTAssertFalse(TKSettings.showWheelchairInformation)
    
    let available: [TKTransportMode] = [
      .publicTransport,
      .bicycle, .bicycleShared,
      .car,
      .walking, .wheelchair
    ]
    let all = available.map(\.modeIdentifier)
    
    var enabled = TKSettings.adjustedEnabledModeIdentifiers(all)
    enabled.insert(TKTransportMode.wheelchair.modeIdentifier)
    
    let adjusted = TKSettings.updateAdjustedEnabledModeIdentifiers(enabled: Array(enabled), all: all)
    XCTAssertTrue(adjusted.contains(TKTransportMode.publicTransport.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.bicycle.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.bicycleShared.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.car.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.walking.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.wheelchair.modeIdentifier))
    
    XCTAssertTrue(TKSettings.showWheelchairInformation)
  }
  
  func testDisablingWalkingEnablesWheelchairAndAutodisablesOtherModes() {
    XCTAssertFalse(TKSettings.showWheelchairInformation)
    
    let available: [TKTransportMode] = [
      .publicTransport,
      .bicycle, .bicycleShared,
      .car,
      .walking, .wheelchair
    ]
    let all = available.map(\.modeIdentifier)
    
    var enabled = TKSettings.adjustedEnabledModeIdentifiers(all)
    enabled.remove(TKTransportMode.walking.modeIdentifier)
    
    let adjusted = TKSettings.updateAdjustedEnabledModeIdentifiers(enabled: Array(enabled), all: all)
    XCTAssertTrue(adjusted.contains(TKTransportMode.publicTransport.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.bicycle.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.bicycleShared.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.car.modeIdentifier))
    XCTAssertFalse(adjusted.contains(TKTransportMode.walking.modeIdentifier))
    XCTAssertTrue(adjusted.contains(TKTransportMode.wheelchair.modeIdentifier))
    
    XCTAssertTrue(TKSettings.showWheelchairInformation)
  }
  
  func testCustomModesAreInjectedIntoAvailableModes() {
    TKUIRoutingResultsCard.config.customModes = [
      .init(identifier: "custom_park_ride", title: "Park & Ride", subtitle: "Drive + public transport", icon: .badgeHeart)
    ]
    
    let region = TKRegion(
      forTestingWithCode: "test",
      modes: [
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier
      ],
      cities: []
    )
    
    let available = TKUIRoutingResultsCard.config.routingModes(in: [region])
    
    XCTAssertEqual(
      available.map(\.identifier),
      [
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier,
        "custom_park_ride"
      ]
    )
  }
  
  func testRoutingModeRequestGroupAdjusterCanInjectMixedModeRequests() {
    TKUIRoutingResultsCard.config.customModes = [
      .init(identifier: "custom_park_ride", title: "Park & Ride", icon: .badgeHeart)
    ]
    TKUIRoutingResultsCard.config.routingModeRequestGroupAdjuster = { selected, defaultGroups in
      var adjustedGroups = defaultGroups
      guard selected.contains("custom_park_ride") else { return adjustedGroups }
      adjustedGroups.insert([
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier
      ])
      return adjustedGroups
    }
    
    let adjusted = TKUIRoutingResultsCard.config.routingModeRequestGroups(
      for: [
        "custom_park_ride",
        TKTransportMode.walking.modeIdentifier
      ]
    )
    
    XCTAssertEqual(
      adjusted,
      [
        [TKTransportMode.walking.modeIdentifier],
        [
          TKTransportMode.publicTransport.modeIdentifier,
          TKTransportMode.car.modeIdentifier
        ]
      ]
    )
  }
  
  func testCustomModeGroupingDoesNotFlattenIntoBackendModes() {
    TKUIRoutingResultsCard.config.customModes = [
      .init(identifier: "custom_park_ride", title: "Park & Ride", icon: .badgeHeart)
    ]
    TKUIRoutingResultsCard.config.routingModeRequestGroupAdjuster = { selected, defaultGroups in
      var adjustedGroups = defaultGroups
      guard selected.contains("custom_park_ride") else { return adjustedGroups }
      adjustedGroups.insert([
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier
      ])
      return adjustedGroups
    }
    
    let selected: Set<String> = ["custom_park_ride"]
    
    XCTAssertEqual(
      TKUIRoutingResultsCard.config.routingModeIdentifiers(for: selected),
      []
    )
    XCTAssertEqual(
      TKUIRoutingResultsCard.config.routingModeRequestGroups(for: selected),
      [[
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier
      ]]
    )
  }
  
  func testAlwaysGroupModeIdentifierPrefixesAdjusterMergesMatchingModes() {
    TKUIRoutingResultsCard.config.routingModeRequestGroupAdjuster =
      TKUIRoutingResultsCard.Configuration.alwaysGroupModeIdentifierPrefixes([
        "pt_ltd_SCHOOLBUS"
      ])
    
    let adjusted = TKUIRoutingResultsCard.config.routingModeRequestGroups(
      for: [
        "pt_pub",
        "pt_ltd_SCHOOLBUS_1",
        "pt_ltd_SCHOOLBUS_2",
        "pt_ltd_SCHOOLBUS_3",
        TKTransportMode.walking.modeIdentifier,
        TKTransportMode.bicycle.modeIdentifier
      ]
    )
    
    XCTAssertEqual(
      adjusted,
      [
        ["pt_pub"],
        [
          "pt_ltd_SCHOOLBUS_1",
          "pt_ltd_SCHOOLBUS_2",
          "pt_ltd_SCHOOLBUS_3"
        ],
        [TKTransportMode.walking.modeIdentifier],
        [TKTransportMode.bicycle.modeIdentifier],
        [
          "pt_pub",
          "pt_ltd_SCHOOLBUS_1",
          "pt_ltd_SCHOOLBUS_2",
          "pt_ltd_SCHOOLBUS_3",
          TKTransportMode.walking.modeIdentifier,
          TKTransportMode.bicycle.modeIdentifier
        ]
      ]
    )
  }
  

}
