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

@testable import TripKit

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
    
    // for now we have to run against the local or beta server
    // TODO: Fix this (should be production ideally)
    SVKServer.serverType = .beta
    
    // these tests need a fake token
    SVKServer.updateUserToken("tripkit-ios-tester-token")
    
    // Always start with a clear cache
    TKFileCache.clearAllAgendas()
    
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
  
  /// Similar to Juptyer notebook Flow 5
  func testUploadingFetchingAndDeletingInput() throws {
    let upload = SVKServer.shared.rx.uploadAgenda(input, for: components)
    let result1 = try upload.toBlocking().toArray()
    XCTAssertEqual(result1, [TKAgendaUploadResult.success])
    
    let download = SVKServer.shared.rx.fetchAgendaInput(for: components)
    let result2 = try download.toBlocking().toArray()
    guard let last = result2.last else { XCTFail("Failed to download input"); return }
    XCTAssert(last == input)

    let delete = SVKServer.shared.rx.deleteAgenda(for: components)
    let result3 = try delete.toBlocking().toArray()
    XCTAssertEqual(result3, [true])
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
  /// 1. POST
  /// 2. GET results
  /// 3. Cache results and pretend app died
  /// 4. GET results again, passing hash code, should get 304 not modified
  func testCachingResult() throws {
    let upload = SVKServer.shared.rx.uploadAgenda(input, for: components)
    let result1 = try upload.toBlocking().toArray()
    XCTAssertEqual(result1, [TKAgendaUploadResult.success])
    
    let fetch = SVKServer.shared.rx.fetchAgenda(for: components)
    let result2 = try fetch.toBlocking(timeout: 120).toArray()
    guard case .success(let output)? = result2.last else { XCTFail(); return }
    XCTAssertNotNil(output)

    let fetch2 = SVKServer.shared.rx.fetchAgenda(for: components)
    let result3 = try fetch2.toBlocking(timeout: 120).toArray()
    guard case .cached(let cached)? = result3.first else { XCTFail(); return }
    guard case .noChange? = result3.last else { XCTFail(); return }
    XCTAssertEqual(cached.hashCode, output.hashCode)
  }
  
  /// Similar to Juptyer notebook Flow 4, using `updateAgenda` and updating with a new input
  func testCachingResult2() throws {
    // Start clean
    let delete = SVKServer.shared.rx.deleteAgenda(for: components)
    let result0 = try delete.toBlocking().toArray()
    XCTAssert(!result0.isEmpty)
    
    // Update first input
    let update1 = SVKServer.shared.rx.updateAgenda(input, for: components)
    let result1 = try update1.toBlocking().toArray()
    guard case .calculating? = result1.first else { XCTFail(); return }
    guard case .success(let uploaded1)? = result1.last else { XCTFail(); return }
    XCTAssertNotNil(uploaded1)

    // Update with second input
    let newInput = try TKAgendaInput.testInput(excludingSecondEvent: false)
    let update2 = SVKServer.shared.rx.updateAgenda(newInput, for: components)
    let result2 = try update2.toBlocking().toArray()
    guard case .cached(let cached)? = result2.first else { XCTFail(); return }
    guard case .success(let uploaded2)? = result2.last else { XCTFail(); return }
    XCTAssertNotNil(uploaded2)
    XCTAssertEqual(uploaded1.hashCode, cached.hashCode)
    XCTAssertNotEqual(uploaded1.hashCode, uploaded2.hashCode)
  }
  
  /// Similar to Juptyer notebook Flow 3
  func testPostingFromNonOwningDevice() throws {
    let device1 = "Device 1"
    let device2 = "Device 2"
    
    // POSTing from device1
    let upload1 = SVKServer.shared.rx.uploadAgenda(input, for: components, deviceId: device1)
    let result1 = try upload1.toBlocking().toArray()
    XCTAssertEqual(result1, [TKAgendaUploadResult.success])

    // POSTing from device2 should error
    let input2 = try TKAgendaInput.testInput(excludingSecondEvent: false)
    let upload2 = SVKServer.shared.rx.uploadAgenda(input2, for: components, deviceId: device2)
    let owningDeviceId: String
    do {
      _ = try upload2.toBlocking().toArray()
      XCTFail("Upload from device 2 should have failed")
      return
    } catch {
      switch error {
      case TKAgendaError.agendaLockedByOtherDevice(let owner):
        XCTAssertEqual(owner, device1)
        guard let owner = owner else {
          XCTFail("Didn't return owner")
          return
        }
        owningDeviceId = owner
      default:
        XCTFail("Unexpected error: \(error)")
        return
      }
    }
    
    // POSTing from 2 again, overwriting explicitly
    let upload2take2 = SVKServer.shared.rx.uploadAgenda(input2, for: components, deviceId: device2, overwritingDeviceId: owningDeviceId)
    do {
      let result2 = try upload2take2.toBlocking().toArray()
      XCTAssertEqual(result2, [TKAgendaUploadResult.success])
    } catch {
      XCTFail("Uploading and overwriting shouldn't have failed, but did with error: \(error)")
      return
    }

    // POSTing from device1 should error
    let upload1take2 = SVKServer.shared.rx.uploadAgenda(input2, for: components, deviceId: device1)
    do {
      _ = try upload1take2.toBlocking().toArray()
      XCTFail("Upload from device 1 should have failed")
    } catch {
      switch error {
      case TKAgendaError.agendaLockedByOtherDevice(let owner):
        XCTAssertEqual(owner, device2)
      default:
        XCTFail("Unexpected error: \(error)")
      }
    }
    
    // Clean-up at the end
    let delete = SVKServer.shared.rx.deleteAgenda(for: components, deviceId: device2)
    let result3 = try delete.toBlocking().toArray()
    XCTAssertEqual(result3, [true])
  }
  
}

fileprivate extension TKAgendaInput {
  
  static func testInput(excludingSecondEvent: Bool = true) throws -> TKAgendaInput {
    let home = TKAgendaInput.HomeInput(
      location: TKAgendaInput.Location(what3word: "schwärme.glaubt.wirkung")!
    )
    
    let work = TKAgendaInput.EventInput(
      id: "work",
      title: "Work",
      location: TKAgendaInput.Location(what3word: "eintopf.kleid.flache")!,
      startTime: try Date(iso8601: "2017-05-30T09:00:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T16:30:00+02:00"),
      priority: .routine
    )
    
    let meeting = TKAgendaInput.EventInput(
      id: "event",
      title: "Meeting",
      location: TKAgendaInput.Location(what3word: "taschen.ehrenvolle.erfinden")!,
      startTime: try Date(iso8601: "2017-05-30T12:00:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T13:00:00+02:00"),
      priority: .calendarEvent
    )

    let excludedEvent = TKAgendaInput.EventInput(
      id: "event2",
      title: "Excluded Event",
      location: TKAgendaInput.Location(what3word: "taschen.ehrenvolle.erfinden")!,
      startTime: try Date(iso8601: "2017-05-30T12:30:00+02:00"),
      endTime: try Date(iso8601: "2017-05-30T13:30:00+02:00"),
      priority: .calendarEvent,
      excluded: excludingSecondEvent
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

public func == (lhs: TKAgendaInput, rhs: TKAgendaInput) -> Bool {
  // Very simplified, but good enough for our purposes here
  return lhs.items.count == rhs.items.count
    && lhs.modes.count == rhs.modes.count
    && lhs.patterns.count == rhs.patterns.count
    && lhs.vehicles.count == rhs.vehicles.count
}
extension TKAgendaInput: Equatable { }

public func ==<T: Equatable> (lhs: TKAgendaFetchResult<T>, rhs: TKAgendaFetchResult<T>) -> Bool {
  switch (lhs, rhs) {
  case (.cached(let left), .cached(let right)): return left == right
  case (.success(let left), .success(let right)): return left == right
  case (.noChange, .noChange): return true
  case (.calculating, .calculating): return true
  default: return false
  }
}

