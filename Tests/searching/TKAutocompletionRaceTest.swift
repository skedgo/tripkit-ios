//
//  TKAutocompletionRaceTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 15.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxCocoa
import RxTest

@testable import TripKitUI

fileprivate let 💥 = [-1]

class TKAutocompletionRaceTest: XCTestCase {
  
  func testBestInFirstBatch() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([1, 3], at: 1),
      ([2, 6], at: 3),
      ([4, 5], at: 6),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(5, [1, 2]),
      .next(6, [1, 2, 3, 4, 5, 6]),
      .completed(6),
    ]))
  }
  
  func testBestInSecondBatch() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([3, 4], at: 1),
      ([5, 6], at: 3),
      ([1, 2], at: 6),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(5, [3, 4]),
      .next(6, [3, 4, 1, 2, 5, 6]),
      .completed(6),
    ]))
  }
  
  func testTopInBoth() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([1, 3], at: 1),
      ([4, 6], at: 3),
      ([2, 5], at: 6),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(5, [1, 3]),
      .next(6, [1, 3, 2, 4, 5, 6]),
      .completed(6),
    ]))
  }
  
  func testAllInFirstBatch() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([1, 3], at: 1),
      ([4, 6], at: 3),
      ([2, 5], at: 4),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(4, [1, 2, 3, 4, 5, 6]),
      .completed(4),
    ]))
  }

  func testAllInSecondBatch() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([1, 3], at: 6),
      ([4, 6], at: 7),
      ([2, 5], at: 8),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(8, [1, 2, 3, 4, 5, 6]),
      .completed(8),
    ]))
  }
  
  func testNoResults() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([], at: 3)
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(3, []),
      .completed(3),
    ]))
  }
  
  func testNoInput() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .completed(0),
    ]))
  }
  
  func testErrorInOne() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      ([1, 3], at: 1),
      (💥, at: 3),
      ([2, 5], at: 6),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(5, [1, 3]),
      .next(6, [1, 3, 2, 5]),
      .completed(6),
    ]))
  }

  func testErrorInAll() throws {
    let simulated = runSimulation(cutOff: 5, fastSpots: 2, [
      (💥, at: 1),
      (💥, at: 3),
      (💥, at: 6),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(6, []),
      .completed(6),
    ]))
  }

}

// MARK: - Running the simulations

extension TKAutocompletionRaceTest {
  
  private struct InputError: Error {}
  
  func runSimulation(cutOff: TestTime, fastSpots: Int, _ inputs: [([Int], at: TestTime)]) -> [Recorded<Event<[Int]>>] {
    
    let bag = DisposeBag()
    let scheduler = TestScheduler(initialClock: 0)
    let observer = scheduler.createObserver([Int].self)
    
    let inputEvents: [[Recorded<Event<[Int]>>]] = inputs.map { input in
      if input.0 == 💥 {
        return [
          .error(input.at, InputError())
        ]
      } else {
        return [
          .next(input.at, input.0),
          .completed(input.at)
        ]
      }
    }

    SharingScheduler.mock(scheduler: scheduler) {
      let observables = inputEvents
        .map(scheduler.createHotObservable)
        .map { $0.asObservable() }
      
      let processed = Observable.stableRace(observables, cutOff: .seconds(cutOff), fastSpots: fastSpots)
      
      processed
        .bind(to: observer)
        .disposed(by: bag)
      scheduler.start()
      scheduler.stop()
    }

    return observer.events
  }
  
}
