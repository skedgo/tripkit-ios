//
//  TKUITripOverviewViewModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 02.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxCocoa

import RxTest
import RxBlocking

@testable import TripKitUI

class TKUITripOverviewViewModelTest: TKTestCase {

  func testFirstSegmentWhenStartingAtStation() throws {
    let trip = self.trip(fromFilename: "routing-pt-realtime")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let sections = try XCTUnwrap( viewModel.sections.toBlocking().first())
    let departure = try XCTUnwrap(sections.first?.items.first)
    guard case let .terminal(item) = departure else { return XCTFail() }
    
    XCTAssertEqual(item.title, "Leave Rehhof")
    XCTAssertEqual(item.subtitle, "Platform 1")
    XCTAssertNotNil(item.time)
    XCTAssertNotNil(item.connection)
    XCTAssertTrue(item.isStart)
  }
  
  func testSubtitlesWithPlatformInformation() throws {
    let trip = self.trip(fromFilename: "routing-pt-realtime")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let items = try XCTUnwrap( viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.count, 9)
    
    let subtitles = items.subtitles
    XCTAssertEqual(subtitles, [
      "Platform 1",
      "Platform 3",
      "Platform U1-1",
      "Platform 2"
    ])
    
    // Don't include the platform in the moving segments
    for item in items {
      guard case let .moving(item) = item else { continue }
      XCTAssertEqual(item.notes?.contains("1\n"), false)
      XCTAssertEqual(item.notes?.contains("U1-1\n"), false)
    }
  }
  
  func testContinuation() throws {
    let trip = self.trip(fromFilename: "routing-pt-continuation")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let items = try XCTUnwrap( viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.count, 5)
    
    // Platform only in subtitles (but not at continuation itself!)
    let subtitles = items.subtitles
    XCTAssertEqual(subtitles, [
      "Platform 1",
      "Platform 2"
    ])
    for item in items {
      if case let .moving(item) = item {
        XCTAssertEqual(item.notes?.contains("1\n"), false)
        XCTAssertEqual(item.notes?.contains("2\n"), false)
      }
      if case let .stationary(item) = item {
        // Stationary should be marked as stop-over
        XCTAssertTrue(item.isContinuation)
      }
    }
    
    // Times, only at start and end
    let times = items.timeInfos
    XCTAssertEqual(times.count, 2)
    XCTAssertEqual(times, [
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575495780)
      ),
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575498204)
      ),
    ])
  }

  func testTripWithRealTime() throws {
    let trip = self.trip(fromFilename: "routing-pt-realtime")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let items = try XCTUnwrap( viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.count, 9)
    
    // Should only display the times of PT segments, and then
    // both departure + arrival for these. (ETA is in the title)
    let times = items.timeInfos
    XCTAssertEqual(times.count, 4)
    XCTAssertEqual(times, [
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575298640),
        timetableTime: Date(timeIntervalSince1970: 1575298680)
      ),
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575299270),
        timetableTime: Date(timeIntervalSince1970: 1575299220)
      ),
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575299740),
        timetableTime: Date(timeIntervalSince1970: 1575299540)
      ),
      TKUITripOverviewViewModel.TimeInfo(
        actualTime: Date(timeIntervalSince1970: 1575299900),
        timetableTime: Date(timeIntervalSince1970: 1575299820)
      ),
    ])
  }
  
  func testImpossibleTripDueToDelay() throws {
    let trip = self.trip(fromFilename: "routing-pt-impossible")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let items = try XCTUnwrap(viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.count, 10)
    
    guard case let .impossible(_, title) = items[4] else { return XCTFail() }
    XCTAssertEqual(title, Loc.YouMightNotMakeThisTransfer)
  }

  func testImpossibleTripDueToCancellation() throws {
    let trip = self.trip(fromFilename: "routing-pt-cancelled")
    let viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let items = try XCTUnwrap(viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.count, 10)
    
    guard case let .impossible(_, title) = items[2] else { return XCTFail() }
    XCTAssertEqual(title, Loc.ServiceHasBeenChancelled)
  }

}

extension Array where Element == TKUITripOverviewViewModel.Section.Item {
  var subtitles: [String] {
    compactMap { item -> String? in
      switch item {
      case .moving, .alert, .impossible: return nil
      case .stationary(let item): return item.subtitle
      case .terminal(let item): return item.subtitle
      }
    }
  }
  
  var timeInfos: [TKUITripOverviewViewModel.TimeInfo] {
    flatMap { item -> [TKUITripOverviewViewModel.TimeInfo] in
      switch item {
      case .moving, .alert, .impossible: return []
      case .stationary(let item): return [item.startTime, item.endTime].compactMap { $0 }
      case .terminal(let item): return [item.time].compactMap { $0 }
      }
    }
  }
}
