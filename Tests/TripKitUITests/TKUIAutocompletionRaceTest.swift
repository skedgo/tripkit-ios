//
//  TKUIAutocompletionRaceTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 15.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxCocoa

@testable import TripKit
@testable import TripKitUI

fileprivate let 💥 = [-1]

class TKUIAutocompletionRaceTest: XCTestCase {
  
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
  
  func testStableRace() throws {
    let inputs: [([TKAutocompletionResult], at: TestTime)] = [
      ([TKAutocompletionResult(object: "1", title: "Campbell High School", image: .iconAlert, score: 50)], at: 100),
      ([TKAutocompletionResult(object: "2", title: "Highway 17", image: .iconAlert, score: 5)], at: 200),
      ([TKAutocompletionResult(object: "3", title: "Campbell High School", image: .iconAlert, score: 45)], at: 300),
      ([TKAutocompletionResult(object: "4", title: "Campbell High School Athletics", image: .iconAlert, score: 40)], at: 400),
      ([TKAutocompletionResult(object: "5", title: "Campbell High School", image: .iconAlert, score: 35)], at: 500),
      ([TKAutocompletionResult(object: "6", title: "Campbell HS - Basketball Courts", image: .iconAlert, score: 30)], at: 600)
    ]
    
    let expected: [Recorded<Event<[TKAutocompletionResult]>>] = [
      .next(600, [
        TKAutocompletionResult(object: "5", title: "Campbell High School", image: .iconAlert, score: 50),
        TKAutocompletionResult(object: "4", title: "Campbell High School Athletics", image: .iconAlert, score: 40),
        TKAutocompletionResult(object: "6", title: "Campbell HS - Basketball Courts", image: .iconAlert, score: 30),
        TKAutocompletionResult(object: "2", title: "Highway 17", image: .iconAlert, score: 5)
      ]),
      .completed(600)
    ]
    
    let simulated = runAutoCompleteSimulation(cutOff: 5, fastSpots: 2, inputs)
            
    XCTAssertEqual(simulated, expected)
  }

}

// MARK: - Running the simulations

extension TKUIAutocompletionRaceTest {
  
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
      
      // Threshold set to nil to ignore Levenshtein distance handling for this simulation
      let processed = Observable.stableRace(observables, cutOff: .seconds(cutOff), fastSpots: fastSpots, threshold: nil)
      
      processed
        .bind(to: observer)
        .disposed(by: bag)
      scheduler.start()
      scheduler.stop()
    }

    return observer.events
  }
  
  func runAutoCompleteSimulation(cutOff: TestTime, fastSpots: Int, _ inputs: [([TKAutocompletionResult], at: TestTime)]) -> [Recorded<Event<[TKAutocompletionResult]>>] {
    
    let bag = DisposeBag()
    let scheduler = TestScheduler(initialClock: 0)
    let observer = scheduler.createObserver([TKAutocompletionResult].self)
    
    let inputEvents: [[Recorded<Event<[TKAutocompletionResult]>>]] = inputs.map { input in
      if input.0.isEmpty {
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
              
      let processed = Observable.stableRace(observables, cutOff: .seconds(cutOff), fastSpots: fastSpots, comparer: { $0.score > $1.score }, threshold: 4, getTitle: { $0.title })
              
      processed
        .bind(to: observer)
        .disposed(by: bag)
      scheduler.start()
      scheduler.stop()
    }

    return observer.events
    }
}


