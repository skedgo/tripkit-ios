//
//  TKAgendaTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

import RxSwift
import RxTest
import RxBlocking

import TripKit

@available(iOS 10.0, *)
class TKAgendaTest: XCTestCase {
  
  var input: TKAgendaInput!
  var components: DateComponents!
  
  // Rx helpers for tests
  var disposeBag = DisposeBag()
  var scheduler: TestScheduler!
  var recorder: TestableObserver<TKAgendaUploadResult>!
  
  
  override func setUp() {
    super.setUp()
    
    // test input
    input = try? TKAgendaInput.testInput()
    components = DateComponents(year: 2017, month: 5, day: 30)

    let env = ProcessInfo.processInfo.environment
    TripKit.apiKey = env["TRIPGO_API_KEY"]!
    
    // for now we have to run against the local server
    // TODO: Fix this (should be production ideally)
    SVKServer.serverType = .local
    
    // these tests need a fake token
    SVKServer.updateUserToken("tripkit-ios-tester-token")
    
    // rx test boilderplate
    disposeBag = DisposeBag()
    scheduler = TestScheduler(initialClock: 0)
    recorder = scheduler.createObserver(TKAgendaUploadResult.self)
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testInitialization() {
    XCTAssertNotNil(input)
    XCTAssertNotNil(components)
  }
  
  
  /// Tests receiving a proper error when trying to upload an agenda
  /// without a user token being set.
  func testMissingUserToken() {
    let token = SVKServer.userToken()
    defer { SVKServer.updateUserToken(token) }
    
    SVKServer.updateUserToken(nil)
    let testee = SVKServer.shared.rx.uploadAgenda(input, for: components)
    
    do {
      let _ = try testee.toBlocking().single()
      XCTFail("Observable should error out")
    } catch {
      switch error {
      case TKAgendaError.userIsNotLoggedIn: return // all good
      default: XCTFail("Unexpected error: \(error)")
      }
    }
    
  }
  
  func testUploadingInput() throws {
    let upload = SVKServer.shared.rx.uploadAgenda(input, for: components)
    let result1 = try upload.toBlocking().toArray()
    XCTAssertEqual(result1, [TKAgendaUploadResult.success])
    
    let delete = SVKServer.shared.rx.deleteAgenda(for: components)
    let result2 = try delete.toBlocking().toArray()
    XCTAssertEqual(result2, [true])
  }
  
  /// Tests uploading an input and then downloading again, making
  /// sure that it parses correctly both ways.
  func testUploadingThenDownloadingInput() throws {
    XCTFail("Not implemented yet")
  }
  
  /// Similar to Juptyer notebook Flow 1
  func testCreateOnDemandFlow() throws {
    let upload = SVKServer.shared.rx.uploadAgenda(input, for: components)
    let result1 = try upload.toBlocking().toArray()
    XCTAssertEqual(result1, [TKAgendaUploadResult.success])
    
    let fetch = SVKServer.shared.rx.fetchAgenda(for: components)
    let result2 = try fetch.toBlocking(timeout: 120).toArray()
    if let first = result2.first {
      switch first {
      case .success, .calculating: XCTAssert(true)
      default: XCTFail("Observable didn't start with calculating or success, but: \(first)")
      }
    } else {
      XCTFail("Observable didn't fire at all")
    }
    if let last = result2.last {
      switch last {
      case .success(let result):
        XCTAssertEqual(10, result.track.count)
        XCTAssertEqual(4, result.trips.count)
        XCTAssertEqual(4, result.inputs.count)
        
      default: XCTFail("Observable didn't end with success, but: \(last)")
      }
    } else {
      XCTFail("Observable didn't fire at all")
    }
    
    let delete = SVKServer.shared.rx.deleteAgenda(for: components)
    let result3 = try delete.toBlocking().toArray()
    XCTAssertEqual(result3, [true])
  }
  
  /// Similar to Juptyer notebook Flow 2
  func testCachingResult() {
    XCTFail("Not implemented yet")
  }
  
  /// Similar to Juptyer notebook Flow 3
  func testPostingFromNonOwningDevice() {
    XCTFail("Not implemented yet")
  }
  
}

fileprivate extension TKAgendaInput {
  
  static func testInput() throws -> TKAgendaInput {
    let home = TKAgendaInput.HomeInput(
      location: TKAgendaInput.Location(what3word: "schwärme.glaubt.wirkung")
    )
    
    let work = TKAgendaInput.EventInput(
      id: "work",
      title: "Work",
      location: TKAgendaInput.Location(what3word: "eintopf.kleid.flache"),
      startTime: try Date(iso8601: "2017-05-30T09:00:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T16:30:00+02:00"),
      priority: .routine
    )
    
    let meeting = TKAgendaInput.EventInput(
      id: "event",
      title: "Meeting",
      location: TKAgendaInput.Location(what3word: "taschen.ehrenvolle.erfinden"),
      startTime: try Date(iso8601: "2017-05-30T12:00:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T13:00:00+02:00"),
      priority: .calendarEvent
    )

    let excludedEvent = TKAgendaInput.EventInput(
      id: "event2",
      title: "Excluded Event",
      location: TKAgendaInput.Location(what3word: "taschen.ehrenvolle.erfinden"),
      startTime: try Date(iso8601: "2017-05-30T12:30:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T13:30:00+02:00"),
      priority: .calendarEvent,
      excluded: true
    )

    return TKAgendaInput(
      items: [
        .home(home),
        .event(work),
        .event(meeting),
        .event(excludedEvent)
      ]
    )
  }
  
}
