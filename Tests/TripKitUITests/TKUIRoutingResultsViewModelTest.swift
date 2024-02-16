//
//  TKUIRoutingResultsViewModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 16/2/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

final class TKUIRoutingResultsViewModelTest: XCTestCase {
  
  override func setUp() async throws {
    try await super.setUp()

    TKSettings.hiddenModeIdentifiers = []
    TKSettings.showWheelchairInformation = false
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
  

}
