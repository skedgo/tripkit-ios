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
    components = DateComponents(year: 2017, month: 5, day: 20)
    
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
  
  func testUploadingInput() throws {
    let testee = SVKServer.shared.rx.uploadAgenda(input, for: components)
    
    let result = try testee.toBlocking(timeout: 2).toArray()
    
    XCTAssertEqual(result, [TKAgendaUploadResult.success])
  }
  
  /// Mirrors Juptyer notebook Flow 1
  func testCreateOnDemandFlow() {
    XCTFail("Not implemented yet")
  }
  
  /// Mirrors Juptyer notebook Flow 2
  func testCachingResult() {
    XCTFail("Not implemented yet")
  }
  
  /// Mirrors Juptyer notebook Flow 3
  func testPostingFromNonOwningDevice() {
    XCTFail("Not implemented yet")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
        // Put the code you want to measure the time of here.
    }
  }
    
}

public func ==(lhs: TKAgendaUploadResult, rhs: TKAgendaUploadResult) -> Bool {
  switch (lhs, rhs) {
  case (.success, .success): return true
  case (.noChange, .noChange): return true
  case (.denied(let ldenial), .denied(let rdenial)): return ldenial == rdenial
  default: return false
  }
}
extension TKAgendaUploadResult: Equatable {}

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
