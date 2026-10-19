//
//  TKUIRoutingResultsSelectionTest.swift
//  TripKitUITests
//
//  The results list should select the same trip by default as the map shows,
//  i.e., the visible trip of the preferred (or first) trip group, rather than
//  the first row, as rows of a group are sorted by time.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

final class TKUIRoutingResultsSelectionTest: TKTestCase {

  /// Mirrors how the results card builds its sections: groups by score, and
  /// the trips within a group by time.
  private func sections(for request: TripRequest) -> [TKUIRoutingResultsViewModel.Section] {
    request.tripGroups
      .sorted { ($0.visibleTrip?.totalScore ?? .infinity) < ($1.visibleTrip?.totalScore ?? .infinity) }
      .map { group in
        let trips = group.trips.sorted { $0.departureTime < $1.departureTime }
        return .init(items: trips.map { .trip($0, lastUpdateURL: nil) })
      }
  }

  func testDefaultSelectionIsVisibleTripOfFirstGroup() throws {
    let request = try request(fromFilename: "routing-cycle-train-cycle")
    request.preferredGroup = nil
    let sections = sections(for: request)

    // Like a later departure scoring better than the first one
    let firstSection = try XCTUnwrap(sections.first)
    let firstGroup = try XCTUnwrap(firstSection.items.first?.trip?.tripGroup)
    let laterTrip = try XCTUnwrap(firstSection.items.last?.trip)
    XCTAssertNotEqual(firstSection.items.first?.trip, laterTrip)
    firstGroup.visibleTrip = laterTrip

    XCTAssertEqual(sections.bestItem?.trip, laterTrip)
  }

  func testDefaultSelectionFollowsPreferredGroup() throws {
    let request = try request(fromFilename: "routing-cycle-train-cycle")
    let sections = sections(for: request)

    let otherGroup = try XCTUnwrap(sections[1].items.first?.trip?.tripGroup)
    let otherTrip = try XCTUnwrap(otherGroup.trips.first { $0 != otherGroup.visibleTrip })
    otherTrip.setAsPreferredTrip()

    XCTAssertEqual(sections.bestItem?.trip, otherTrip)
  }

  func testDefaultSelectionWhenPreferredGroupIsNotShown() throws {
    let request = try request(fromFilename: "routing-cycle-train-cycle")
    let sections = Array(sections(for: request).prefix(1))
    let firstGroup = try XCTUnwrap(sections.first?.items.first?.trip?.tripGroup)
    request.preferredGroup = request.tripGroups.first { $0 != firstGroup }

    XCTAssertEqual(sections.bestItem?.trip, firstGroup.visibleTrip)
  }

  func testDefaultSelectionWithoutTrips() {
    let sections: [TKUIRoutingResultsViewModel.Section] = [.init(items: [.progress])]
    guard case .progress = sections.bestItem else {
      return XCTFail("Expected progress item, got \(String(describing: sections.bestItem))")
    }
  }

}
