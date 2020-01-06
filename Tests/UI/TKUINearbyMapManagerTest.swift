//
//  NearbyMapManagerTest.swift
//  TripGoAppKitTests
//
//  Created by Adrian Schönig on 30.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxCocoa
import RxTest

@testable import TripKitUI

class NearbyMapManagerTest: XCTestCase {
  
  func testCenterFollowingUser() throws {
    let simulated = runSimulation([
      .track(.follow),
      .move(CLLocationCoordinate2D(latitude: 1, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 2, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 3, longitude: 0)),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(200, CLLocationCoordinate2D(latitude: 1, longitude: 0) as CLLocationCoordinate2D?),
      .completed(500)
    ]))
  }
  
  func testManuallyChangingLocation() throws {
    let simulated = runSimulation([
      .track(.follow),
      .move(CLLocationCoordinate2D(latitude: 1, longitude: 0)),
      .track(.none),
      .move(CLLocationCoordinate2D(latitude: 2, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 3, longitude: 0)),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(200, CLLocationCoordinate2D(latitude: 1, longitude: 0) as CLLocationCoordinate2D?),
      .next(400, CLLocationCoordinate2D(latitude: 2, longitude: 0) as CLLocationCoordinate2D?),
      .next(500, CLLocationCoordinate2D(latitude: 3, longitude: 0) as CLLocationCoordinate2D?),
      .completed(600)
    ]))
  }

  func testTogglingTrackingModes() throws {
    let simulated = runSimulation([
      .track(.follow),
      .move(CLLocationCoordinate2D(latitude: 1, longitude: 0)),
      .track(.none),
      .move(CLLocationCoordinate2D(latitude: 2, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 3, longitude: 0)),
      .track(.follow),
      .move(CLLocationCoordinate2D(latitude: 4, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 5, longitude: 0)),
      .track(.followWithHeading),
      .move(CLLocationCoordinate2D(latitude: 6, longitude: 0)),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(200, CLLocationCoordinate2D(latitude: 1, longitude: 0) as CLLocationCoordinate2D?),
      .next(400, CLLocationCoordinate2D(latitude: 2, longitude: 0) as CLLocationCoordinate2D?),
      .next(500, CLLocationCoordinate2D(latitude: 3, longitude: 0) as CLLocationCoordinate2D?),
      .next(700, CLLocationCoordinate2D(latitude: 4, longitude: 0) as CLLocationCoordinate2D?),
      .completed(1100)
    ]))
  }
  
  func testOnlyMoving() throws {
    let simulated = runSimulation([
      .move(CLLocationCoordinate2D(latitude: 1, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 2, longitude: 0)),
      .move(CLLocationCoordinate2D(latitude: 3, longitude: 0)),
    ])
    
    XCTAssertEqual(simulated, Recorded.events([
      .next(100, CLLocationCoordinate2D(latitude: 1, longitude: 0) as CLLocationCoordinate2D?),
      .next(200, CLLocationCoordinate2D(latitude: 2, longitude: 0) as CLLocationCoordinate2D?),
      .next(300, CLLocationCoordinate2D(latitude: 3, longitude: 0) as CLLocationCoordinate2D?),
      .completed(400)
    ]))
  }
}

// MARK: - Running the simulations

extension NearbyMapManagerTest {

  enum UserAction {
    case track(MKUserTrackingMode)
    case move(CLLocationCoordinate2D)
  }
  
  func runSimulation(_ actions: [UserAction]) -> [Recorded<Event<CLLocationCoordinate2D?>>] {
    let bag = DisposeBag()
    let scheduler = TestScheduler(initialClock: 0)
    let observer = scheduler.createObserver(CLLocationCoordinate2D?.self)

    // Set-up input
    var centers: [Recorded<Event<CLLocationCoordinate2D>>] = []
    var modes:   [Recorded<Event<MKUserTrackingMode>>]     = []
    for (index, action) in actions.enumerated() {
      let time: TestTime = (index + 1) * 100
      switch action {
      case .track(let mode): modes.append(.next(time, mode))
      case .move(let center): centers.append(.next(time, center))
      }
    }
    let time: TestTime = (actions.count + 1) * 100
    modes.append(Recorded.completed(time))
    centers.append(Recorded.completed(time))

    // Prepare our observable
    let merged = TKUINearbyMapManager.buildMapCenter(
      tracking: scheduler.createHotObservable(modes).asObservable(),
      center: scheduler.createHotObservable(centers).asObservable()
    )
    
    // Run the simulation
    merged
      .bind(to: observer)
      .disposed(by: bag)
    scheduler.start()
    return observer.events
  }
  
}

extension CLLocationCoordinate2D: Equatable {
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return abs(lhs.latitude - rhs.latitude) < 0.1 && abs(rhs.longitude - rhs.longitude) < 0.1
  }
}
