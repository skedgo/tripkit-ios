//
//  TKUIModePickerTest.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 25.02.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

fileprivate func enabledModes(_ enabled: [String], allow candidate: String?) -> Bool {
  guard let candidate = candidate else { return false }
  return TKModeHelper.modesContain(Set(enabled), Set([candidate]))
}

class TKUIModePickerTest: XCTestCase {
  
  func buildPicker(_ modes: [TKModeInfo]) -> TKUIModePicker<TKModeInfo> {
    let picker = TKUIModePicker<TKModeInfo>()
    picker.configure(all: modes) { enabledModes(["pt_pub"], allow: $0.identifier) }
    return picker
  }
  
  func testPicksEnabledModesByDefault() {
    let picker = buildPicker(.moegel)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train", "pt_pub_tram"])
  }
  
  func testParkingModeShouldBeDisabledBeDefault() {
    let picker = buildPicker(.parkin)
    XCTAssert(!picker.pickedModes.map { $0.alt }.contains("Car park"), "Should not include car park by default")
  }
  
  func testRemoveUnavailableModes() {
    let picker = buildPicker(.moegel)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train", "pt_pub_tram"])
    
    // Now, let's go to Rehhof where there's no tram
    picker.configure(all: .rehhof) { ["pt_pub", "me_car-s_FLINK"].contains($0.identifier ?? "") }
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
  }
  
  func testMaintainDisabledModes() {
    let picker = buildPicker(.rehhof)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
    
    picker.setMode(.bus, selected: false)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_train"])
    
    // Now, let's go to Mögel and make sure bus doesn't reappear
    picker.configure(all: .moegel)
    XCTAssert(!picker.pickedModes.contains(.bus), "\(TKModeInfo.bus.identifier!) should have been removed, but we get: \(picker.pickedModes.identifiers.joined(separator: ", "))")
  }
  
  func testRememberDisabledModeEvenIfItWentAway() {
    let picker = buildPicker(.moegel)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train", "pt_pub_tram"])
    
    picker.setMode(.tram, selected: false)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
    
    // Now, let's go to Rehhof where there's no tram anyway
    picker.configure(all: .rehhof)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
    
    // Now, let's go to the parking which get's tram again
    picker.configure(all: .parkin)
    XCTAssert(!picker.pickedModes.contains(.tram), "\(TKModeInfo.tram.identifier!) should have been removed, but we get: \(picker.pickedModes.identifiers.joined(separator: ", "))")
  }
  
}

fileprivate extension String {
  var mode: TKModeInfo {
    let id = self
    let json = """
      {
        "identifier": "\(id)",
        "alt": "\(id)"
      }
      """
    return try! JSONDecoder().decode(TKModeInfo.self, from: json.data(using: .utf8)!)
  }
}

fileprivate extension TKModeInfo {
  static let bus       = "pt_pub_bus".mode
  static let train     = "pt_pub_train".mode
  static let tram      = "pt_pub_tram".mode
  static let flinkster = "me_car-s_FLINK".mode

  static let parking: TKModeInfo = {
    let json = """
      {
        "alt": "Car park",
        "identifier": "\(TKSegment.StationaryType.parkingOffStreet.rawValue)",
        "localImageName": "parking"
      }
    """
    return try! JSONDecoder().decode(TKModeInfo.self, from: json.data(using: .utf8)!)
  }()
}

fileprivate extension Array where Element == TKModeInfo {
  
  static var rehhof: [TKModeInfo] { return [.bus, .train] }
  
  static var moegel: [TKModeInfo] { return [.bus, .train, .tram, .flinkster] }
  
  static var parkin: [TKModeInfo] { return [.bus, .tram, .parking] }
  
}

fileprivate extension Set where Element == TKModeInfo {
  
  var identifiers: Set<String> {
    let ids = compactMap { $0.identifier }
    return Set<String>(ids)
  }
  
}
