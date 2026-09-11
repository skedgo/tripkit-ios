//
//  TKUIRoutingResultsOriginTitleTest.swift
//  TripKitUITests
//
//  Regression tests for RM26188 — the results card title showed "From …"
//  instead of "From Current Location" (and then the resolved address) when
//  planning a trip from the user's current location.
//

#if canImport(Testing)

import Foundation
import CoreData
import CoreLocation
import MapKit
import Testing

import RxSwift
import RxCocoa

@testable import TripKitAPI
@testable import TripKit
@testable import TripKitUI

@Suite(.serialized)
@MainActor
struct TKUIRoutingResultsOriginTitleTest {

  private let sydneyCBD = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)

  init() {
    TKUIRoutingResultsCard.config = .empty
  }

  @Test func destinationOnlyStartsWithCurrentLocationOrigin() {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let recorder = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { recorder.append($0) }).disposed(by: Self.disposeBag)

    #expect(recorder.values.first?.origin == Loc.CurrentLocation)
    #expect(recorder.values.first?.destination == "Central Station")
  }

  @Test func explicitPlaceholderOriginShowsCurrentLocation() {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: placeholder, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let recorder = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { recorder.append($0) }).disposed(by: Self.disposeBag)

    #expect(recorder.values.first?.origin == Loc.CurrentLocation)
  }

  @Test func locationsResolvedUpdatesPlaceholderOriginTitle() async throws {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: Self.disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: Self.disposeBag)

    let request = try await Self.waitForFirst(requests)
    let resolvedOrigin = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Home")
    request.fromLocation = resolvedOrigin

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(updated.last?.origin == "Home")
  }

  @Test func validNamedOriginIsUnaffectedByLocationsResolved() async throws {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Explicit Origin")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: origin, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: Self.disposeBag)

    #expect(titles.values.first?.origin == "Explicit Origin")

    viewModel.locationsResolved()
    try await Task.sleep(for: .milliseconds(400)) // give any (unexpected) async pipeline a chance to fire

    #expect(titles.values.last?.origin == "Explicit Origin", "A resolved, valid explicit origin must not be overridden")
  }

  @Test func geocodingFailureKeepsCurrentLocationTitle() async throws {
    TKNamedCoordinate.reverseGeocodeOverride = { _ in throw StubGeocodeError() }
    defer { TKNamedCoordinate.reverseGeocodeOverride = nil }

    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: Self.disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: Self.disposeBag)

    let request = try await Self.waitForFirst(requests)
    // No name, mimicking TKUIResultsFetcher's default replacementHandler.
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()
    try await Task.sleep(for: .milliseconds(400)) // let the failing geocode round-trip complete

    #expect(titles.values.count > countBeforeResolution, "Must still emit, even though geocoding failed")
    #expect(titles.values.last?.origin == Loc.CurrentLocation)
  }

  @Test func geocodingSuccessShowsResolvedAddress() async throws {
    let addressDictionary: [String: Any] = [
      "Street": "1 Test St",
      "City": "Sydney",
      "State": "NSW",
      "Country": "Australia",
    ]
    let mkPlacemark = MKPlacemark(coordinate: sydneyCBD, addressDictionary: addressDictionary)
    let stubbedPlacemark = CLPlacemark(placemark: mkPlacemark)
    let expectedAddress = try #require(TKAddressFormatter.singleLineAddress(for: stubbedPlacemark))

    TKNamedCoordinate.reverseGeocodeOverride = { _ in stubbedPlacemark }
    defer { TKNamedCoordinate.reverseGeocodeOverride = nil }

    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: Self.disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: Self.disposeBag)

    let request = try await Self.waitForFirst(requests)
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()
    try await Task.sleep(for: .milliseconds(400)) // let the stubbed geocode round-trip complete

    #expect(titles.values.count > countBeforeResolution)
    #expect(titles.values.last?.origin == expectedAddress)
  }

}

private struct StubGeocodeError: Error {}

private extension TKUIRoutingResultsOriginTitleTest {

  static let disposeBag = DisposeBag()

  static let emptyInputs: TKUIRoutingResultsViewModel.UIInput = (
    selected: .empty(),
    tappedSectionButton: .empty(),
    tappedSearch: .empty(),
    tappedDate: .empty(),
    tappedShowModes: .empty(),
    changedDate: .empty(),
    changedModes: .empty(),
    changedSortOrder: .empty(),
    changedSearch: .empty()
  )

  static let emptyMapInput: TKUIRoutingResultsViewModel.MapInput = (
    tappedMapRoute: .empty(),
    droppedPin: .empty(),
    tappedPin: .empty()
  )

  /// Polls a recorder until it has at least one value, or times out.
  static func waitForFirst<T>(_ recorder: Recorder<T>, timeout: Duration = .seconds(3)) async throws -> T {
    let deadline = ContinuousClock.now + timeout
    while recorder.values.isEmpty {
      guard ContinuousClock.now < deadline else {
        Issue.record("Timed out waiting for a value")
        throw TimeoutError()
      }
      try await Task.sleep(for: .milliseconds(20))
    }
    return recorder.values[0]
  }

  /// Polls a recorder until it has more than `count` values, or times out.
  static func waitForCount<T>(_ recorder: Recorder<T>, greaterThan count: Int, timeout: Duration = .seconds(3)) async throws -> [T] {
    let deadline = ContinuousClock.now + timeout
    while recorder.values.count <= count {
      guard ContinuousClock.now < deadline else {
        Issue.record("Timed out waiting for more values")
        throw TimeoutError()
      }
      try await Task.sleep(for: .milliseconds(20))
    }
    return recorder.values
  }

  struct TimeoutError: Error {}

}

/// Records values driven synchronously on the main thread by a `Driver`. Not
/// actor-isolated on purpose: everything touching it happens on the main
/// thread within these `@MainActor` tests, same as production `.drive` calls.
private final class Recorder<T>: @unchecked Sendable {
  private(set) var values: [T] = []
  func append(_ value: T) { values.append(value) }
}

#endif
