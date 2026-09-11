//
//  TKUIRoutingResultsEndpointTitleTest.swift
//  TripKitUITests
//
//  Regression tests for RM26188 — the results card title (and the query
//  input's field text after "Change Route") showed "…"/"Location" instead of
//  "Current Location" (and then the resolved address) for either endpoint of
//  a trip planned from/to the user's current location.
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
struct TKUIRoutingResultsEndpointTitleTest {

  private let sydneyCBD = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)

  // Instance, not static: Swift Testing creates a fresh struct per `@Test`, so
  // this - and everything disposed into it - is torn down between tests
  // rather than accumulating subscriptions across the whole suite.
  private let disposeBag = DisposeBag()

  init() {
    TKUIRoutingResultsCard.config = .empty
  }

  @Test func destinationOnlyStartsWithCurrentLocationOrigin() {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let recorder = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { recorder.append($0) }).disposed(by: disposeBag)

    #expect(recorder.values.first?.origin == Loc.CurrentLocation)
    #expect(recorder.values.first?.destination == "Central Station")
  }

  @Test func explicitPlaceholderOriginShowsCurrentLocation() {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: placeholder, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let recorder = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { recorder.append($0) }).disposed(by: disposeBag)

    #expect(recorder.values.first?.origin == Loc.CurrentLocation)
  }

  @Test func locationsResolvedUpdatesPlaceholderOriginTitle() async throws {
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

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
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

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
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    let request = try await Self.waitForFirst(requests)
    // No name, mimicking TKUIResultsFetcher's default replacementHandler.
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(updated.last?.origin == Loc.CurrentLocation)
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
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    let request = try await Self.waitForFirst(requests)
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(updated.last?.origin == expectedAddress)
  }

  @Test func changingDateAfterResolutionDoesNotRevertOriginTitle() async throws {
    // `changedDate` is driven manually so we can trigger a builder rebuild
    // *after* resolution, the way picking a new time in the UI would.
    let changedDate = PublishSubject<TKUIRoutingResultsViewModel.RouteBuilder.Time>()
    let inputs: TKUIRoutingResultsViewModel.UIInput = (
      selected: .empty(),
      tappedSectionButton: .empty(),
      tappedSearch: .empty(),
      tappedDate: .empty(),
      tappedShowModes: .empty(),
      changedDate: changedDate.asAssertingSignal(),
      changedModes: .empty(),
      changedSortOrder: .empty(),
      changedSearch: .empty()
    )

    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: inputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    let request = try await Self.waitForFirst(requests)
    request.fromLocation = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Home")

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()
    _ = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(titles.values.last?.origin == "Home")

    // Rebuild the builder (and thus re-subscribe to the origin annotation's
    // KVO, which re-emits its initial value) the way picking a new time does.
    let requestCountBeforeDateChange = requests.values.count
    changedDate.onNext(.leaveAfter(Date().addingTimeInterval(3600)))
    _ = try await Self.waitForCount(requests, greaterThan: requestCountBeforeDateChange)

    #expect(titles.values.last?.origin == "Home", "Picking a new time must not revert the resolved origin title back to the placeholder")
  }

  @Test func pickingNewOriginViaSearchUpdatesTitle() async throws {
    let changedSearch = PublishSubject<TKUIRoutingResultsViewModel.SearchResult>()
    let inputs: TKUIRoutingResultsViewModel.UIInput = (
      selected: .empty(),
      tappedSectionButton: .empty(),
      tappedSearch: .empty(),
      tappedDate: .empty(),
      tappedShowModes: .empty(),
      changedDate: .empty(),
      changedModes: .empty(),
      changedSortOrder: .empty(),
      changedSearch: changedSearch.asAssertingSignal()
    )

    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: inputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    #expect(titles.values.first?.origin == Loc.CurrentLocation)

    let newOrigin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "New Origin")
    let countBeforeSearch = titles.values.count
    changedSearch.onNext(TKUIRoutingResultsViewModel.SearchResult(mode: .origin, location: newOrigin))

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeSearch)
    #expect(updated.last?.origin == "New Origin")
  }

  // MARK: - Destination endpoint (symmetric with origin)

  @Test func placeholderDestinationStartsWithCurrentLocationTitle() {
    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: placeholder, origin: origin, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let recorder = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { recorder.append($0) }).disposed(by: disposeBag)

    #expect(recorder.values.first?.destination == Loc.CurrentLocation)
    #expect(recorder.values.first?.origin == "Home")
  }

  @Test func locationsResolvedUpdatesPlaceholderDestinationTitle() async throws {
    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: placeholder, origin: origin, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    let request = try await Self.waitForFirst(requests)
    request.toLocation = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Work")

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(updated.last?.destination == "Work")
  }

  @Test func placeholderDestinationGeocodingFailureKeepsCurrentLocationTitle() async throws {
    TKNamedCoordinate.reverseGeocodeOverride = { _ in throw StubGeocodeError() }
    defer { TKNamedCoordinate.reverseGeocodeOverride = nil }

    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: placeholder, origin: origin, inputs: Self.emptyInputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    let request = try await Self.waitForFirst(requests)
    // No name, mimicking TKUIResultsFetcher's default replacementHandler.
    request.toLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()

    let updated = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)
    #expect(updated.last?.destination == Loc.CurrentLocation)
  }

  // MARK: - Query input hand-off (`.showSearch`)

  @Test func tappedSearchHandsOffCurrentLocationDestinationTitle() {
    let tappedSearch = PublishSubject<Void>()
    let inputs = Self.inputs(tappedSearch: tappedSearch.asAssertingSignal())

    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let placeholder = TKLocationManager.shared.currentLocation
    let viewModel = TKUIRoutingResultsViewModel(destination: placeholder, origin: origin, inputs: inputs, mapInput: Self.emptyMapInput)

    let nextEvents = Recorder<TKUIRoutingResultsViewModel.Next>()
    viewModel.next.emit(onNext: { nextEvents.append($0) }).disposed(by: disposeBag)

    tappedSearch.onNext(())

    guard case .showSearch(_, let destination, _) = nextEvents.values.last else {
      Issue.record("Expected a .showSearch event")
      return
    }
    #expect(destination?.title == Loc.CurrentLocation)
  }

  @Test func tappedSearchHandsOffCurrentLocationOriginTitleBeforeAndAfterResolution() async throws {
    let tappedSearch = PublishSubject<Void>()
    let inputs = Self.inputs(tappedSearch: tappedSearch.asAssertingSignal())

    let placeholder = TKLocationManager.shared.currentLocation
    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: placeholder, inputs: inputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let nextEvents = Recorder<TKUIRoutingResultsViewModel.Next>()
    viewModel.next.emit(onNext: { nextEvents.append($0) }).disposed(by: disposeBag)

    let requests = Recorder<TripRequest>()
    viewModel.request.drive(onNext: { requests.append($0) }).disposed(by: disposeBag)

    tappedSearch.onNext(())
    guard case .showSearch(let originBefore, _, _) = nextEvents.values.last else {
      Issue.record("Expected a .showSearch event")
      return
    }
    #expect(originBefore?.title == Loc.CurrentLocation)

    // Resolve, and wait for the card title itself to move on to "Home" - the
    // query input hand-off must still show the placeholder, not that address.
    let request = try await Self.waitForFirst(requests)
    request.fromLocation = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Home")
    let countBeforeResolution = titles.values.count
    viewModel.locationsResolved()
    _ = try await Self.waitForCount(titles, greaterThan: countBeforeResolution)

    tappedSearch.onNext(())
    guard case .showSearch(let originAfter, _, _) = nextEvents.values.last else {
      Issue.record("Expected a second .showSearch event")
      return
    }
    #expect(originAfter?.title == Loc.CurrentLocation)
  }

  // MARK: - "Change Route" → "Route" (`changedSearch` then `tappedSearch`)

  @Test func changeRouteThenRouteKeepsCurrentLocationOriginTitle() async throws {
    let changedSearch = PublishSubject<TKUIRoutingResultsViewModel.SearchResult>()
    let tappedSearch = PublishSubject<Void>()
    let inputs = Self.inputs(tappedSearch: tappedSearch.asAssertingSignal(), changedSearch: changedSearch.asAssertingSignal())

    let destination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    // Named, not implicit: switching this to the placeholder is then a real
    // title change ("Home" -> "Current Location"), not a same-value no-op that
    // `distinctUntilChanged()` would (correctly) swallow.
    let initialOrigin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: initialOrigin, inputs: inputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let nextEvents = Recorder<TKUIRoutingResultsViewModel.Next>()
    viewModel.next.emit(onNext: { nextEvents.append($0) }).disposed(by: disposeBag)

    let placeholder = TKLocationManager.shared.currentLocation
    let countBeforeSearch = titles.values.count
    changedSearch.onNext(TKUIRoutingResultsViewModel.SearchResult(mode: .origin, location: placeholder))
    let updatedTitles = try await Self.waitForCount(titles, greaterThan: countBeforeSearch)
    #expect(updatedTitles.last?.origin == Loc.CurrentLocation)

    tappedSearch.onNext(())
    guard case .showSearch(let origin, _, _) = nextEvents.values.last else {
      Issue.record("Expected a .showSearch event")
      return
    }
    #expect(origin?.title == Loc.CurrentLocation)
  }

  @Test func changeRouteThenRouteKeepsCurrentLocationDestinationTitle() async throws {
    let changedSearch = PublishSubject<TKUIRoutingResultsViewModel.SearchResult>()
    let tappedSearch = PublishSubject<Void>()
    let inputs = Self.inputs(tappedSearch: tappedSearch.asAssertingSignal(), changedSearch: changedSearch.asAssertingSignal())

    let initialDestination = TKNamedCoordinate(latitude: sydneyCBD.latitude, longitude: sydneyCBD.longitude, name: "Central Station")
    let origin = TKNamedCoordinate(latitude: -33.8398, longitude: 151.2095, name: "Home")
    let viewModel = TKUIRoutingResultsViewModel(destination: initialDestination, origin: origin, inputs: inputs, mapInput: Self.emptyMapInput)

    let titles = Recorder<(origin: String?, destination: String?)>()
    viewModel.originDestination.drive(onNext: { titles.append($0) }).disposed(by: disposeBag)

    let nextEvents = Recorder<TKUIRoutingResultsViewModel.Next>()
    viewModel.next.emit(onNext: { nextEvents.append($0) }).disposed(by: disposeBag)

    let placeholder = TKLocationManager.shared.currentLocation
    let countBeforeSearch = titles.values.count
    changedSearch.onNext(TKUIRoutingResultsViewModel.SearchResult(mode: .destination, location: placeholder))
    let updatedTitles = try await Self.waitForCount(titles, greaterThan: countBeforeSearch)
    #expect(updatedTitles.last?.destination == Loc.CurrentLocation)

    tappedSearch.onNext(())
    guard case .showSearch(_, let destination, _) = nextEvents.values.last else {
      Issue.record("Expected a .showSearch event")
      return
    }
    #expect(destination?.title == Loc.CurrentLocation)
  }

}

private struct StubGeocodeError: Error {}

private extension TKUIRoutingResultsEndpointTitleTest {

  static let emptyInputs: TKUIRoutingResultsViewModel.UIInput = inputs()

  /// `emptyInputs` with just `tappedSearch`/`changedSearch` swapped for a
  /// subject-backed signal a test can drive directly.
  static func inputs(
    tappedSearch: Signal<Void> = .empty(),
    changedSearch: Signal<TKUIRoutingResultsViewModel.SearchResult> = .empty()
  ) -> TKUIRoutingResultsViewModel.UIInput {
    (
      selected: .empty(),
      tappedSectionButton: .empty(),
      tappedSearch: tappedSearch,
      tappedDate: .empty(),
      tappedShowModes: .empty(),
      changedDate: .empty(),
      changedModes: .empty(),
      changedSortOrder: .empty(),
      changedSearch: changedSearch
    )
  }

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
