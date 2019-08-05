//
//  TKUIModePickerTest.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 25.02.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

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
    
    let bus = picker.pickedModes.first!
    picker.setMode(bus, selected: false)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_train"])
    
    // Now, let's go to Mögel and make sure bus doesn't reappear
    picker.configure(all: .moegel)
    XCTAssert(!picker.pickedModes.contains(bus), "\(bus.identifier!) should have been removed, but we get: \(picker.pickedModes.identifiers.joined(separator: ", "))")
  }
  
  func testRememberDisabledModeEvenIfItWentAway() {
    let picker = buildPicker(.moegel)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train", "pt_pub_tram"])
    
    let tram = picker.pickedModes.last!
    picker.setMode(tram, selected: false)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
    
    // Now, let's go to Rehhof where there's no tram anyway
    picker.configure(all: .rehhof)
    XCTAssertEqual(picker.pickedModes.identifiers, ["pt_pub_bus", "pt_pub_train"])
    
    // Now, let's go to the parking which get's tram again
    picker.configure(all: .parkin)
    XCTAssert(!picker.pickedModes.contains(tram), "\(tram.identifier!) should have been removed, but we get: \(picker.pickedModes.identifiers.joined(separator: ", "))")
  }
  
}

fileprivate extension Array where Element == TKModeInfo {
  
  static var rehhof: [TKModeInfo] { return ["pt_pub_bus", "pt_pub_train"].modes }
  
  static var moegel: [TKModeInfo] { return ["pt_pub_bus", "pt_pub_train", "pt_pub_tram", "me_car-s_FLINK"].modes }
  
  static var parkin: [TKModeInfo] { return ["pt_pub_bus", "pt_pub_tram"].modes + [.parking] }
  
  
  var identifiers: [String] {
    return compactMap { $0.identifier }
  }
  
}

fileprivate extension Array where Element == String {
  
  var modes: [TKModeInfo] {
    return map { id in
      let json = """
      {
      "identifier": "\(id)",
      "alt": "\(id)"
      }
      """
      return try! JSONDecoder().decode(TKModeInfo.self, from: json.data(using: .utf8)!)
    }
  }
  
}

fileprivate extension TKModeInfo {
  static var parking: TKModeInfo {
    let json = """
      {
        "alt": "Car park",
        "localImageName": "parking"
      }
    """
    return try! JSONDecoder().decode(TKModeInfo.self, from: json.data(using: .utf8)!)
  }
}
