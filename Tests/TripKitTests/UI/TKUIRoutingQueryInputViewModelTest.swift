//
//  TKUIRoutingQueryInputViewModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 23.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import MapKit

import RxSwift
import RxCocoa

@testable import TripKit
@testable import TripKitUI

#if SWIFT_PACKAGE
import TripKitObjc
#endif

class TKUIRoutingQueryInputViewModelTest: XCTestCase {
  
  func testStartsOnDestination() throws {
    let viewModel = TKUIRoutingQueryInputViewModel(inputs: .dummy)
    
    let mode = try viewModel.activeMode.toBlocking().first()
    XCTAssertEqual(mode, .destination)
    
    let routeEnabled = try viewModel.enableRouteButton.toBlocking().first()
    XCTAssertEqual(routeEnabled, false)
  }
  
  func testDefaultOriginIsCurrentLocation() throws {
    let viewModel = TKUIRoutingQueryInputViewModel(inputs: .dummy)
    
    let od = try viewModel.originDestination.toBlocking().first()
    XCTAssertEqual(od?.origin, Loc.CurrentLocation)
    XCTAssertEqual(od?.destination, "")
    
    let routeEnabled = try viewModel.enableRouteButton.toBlocking().first()
    XCTAssertEqual(routeEnabled, false)
  }

  func testStartsOnProvidedLocations() throws {
    let viewModel = TKUIRoutingQueryInputViewModel(
      origin: MKPointAnnotation.maroubra,
      destination: TKLocationManager.shared.currentLocation,
      inputs: .dummy
    )
    
    let od = try viewModel.originDestination.toBlocking().first()
    XCTAssertEqual(od?.origin, "Maroubra")
    XCTAssertEqual(od?.destination, Loc.CurrentLocation)
    
    let routeEnabled = try viewModel.enableRouteButton.toBlocking().first()
    XCTAssertEqual(routeEnabled, true)
  }
  
  func testStartsAutocompletingEmptyString() throws {
    let viewModel = TKUIRoutingQueryInputViewModel(
      inputs: .dummy,
      providers: [FakeAutocompleter()]
    )

    let sections = try XCTUnwrap(try viewModel.sections.toBlocking().first())
    let items = try XCTUnwrap(sections.first(where: { $0.identifier == "results"})?.items)
    XCTAssertEqual(items.count, FakeAutocompleter.cities.count)
    XCTAssertEqual(items.map { $0.title }, FakeAutocompleter.cities)
    
  }

  func testDoesNotShowAutocompletionAccessories() throws {
    let viewModel = TKUIRoutingQueryInputViewModel(
      inputs: .dummy,
      providers: [FakeAutocompleter()]
    )

    let items = try XCTUnwrap(try viewModel.sections.toBlocking().first()?.first?.items)
    XCTAssertEqual(items.compactMap { $0.accessory }, [])
  }

  func testInitial() throws {
    let results = run([])
    
    XCTAssertEqual(results, [
      "\(Loc.CurrentLocation) -- ",
    ])
  }
  
  func testTypingAndSelecting() throws {
    let results = run([
        .mode(.origin),
        .type("N"),
        .select("Nuremberg", index: 0),
        .mode(.destination),
        .type("B"),
        .select("Bahia Blanca", index: 0),
      ])
    
    XCTAssertEqual(results, [
      "\(Loc.CurrentLocation) -- ",
      "N -- ",
      "Nuremberg -- ",
      "Nuremberg -- B",
      "Nuremberg -- Bahia Blanca",
    ])
  }

  func testAutocompletingOne() throws {
    let results = run([
        .type("M"),
        .type("Melb"),
        .select("Melbourne", index: 0),
        .route
      ]).last
    
    XCTAssertEqual(results, "✅ \(Loc.CurrentLocation) -- Melbourne")
  }

  func testAutocompletingBothWithExplicitModeSelection() throws {
    let results = run([
        .mode(.origin),
        .type("N"),
        .select("Nuremberg", index: 0),
        .mode(.destination),
        .type("B"),
        .select("Bahia Blanca", index: 0),
        .route
      ]).last
    
    XCTAssertEqual(results, "✅ Nuremberg -- Bahia Blanca")
  }
  
  func testAutocompletingBothWithImplicitModeSelection() throws {
    let results = run([
        .type("B"),
        .select("Bahia Blanca", index: 0),
        .type("N"),
        .select("Nuremberg", index: 0),
        .route
      ]).last
    
    XCTAssertEqual(results, "✅ Nuremberg -- Bahia Blanca")
  }
  
  func testSwapping() throws {
    let results = run([
        .type("N"),
        .select("Nuremberg", index: 0),
        .swap,
        .mode(.destination),
        .type("B"),
        .select("Bahia Blanca", index: 0),
        .route
      ])
    
    XCTAssertEqual(results, [
      "\(Loc.CurrentLocation) -- ",
      "\(Loc.CurrentLocation) -- N",
      "\(Loc.CurrentLocation) -- Nuremberg",
      "Nuremberg -- \(Loc.CurrentLocation)",
      "Nuremberg -- B",
      "Nuremberg -- Bahia Blanca",
      "✅ Nuremberg -- Bahia Blanca"
    ])
  }
  
}

// MARK: - Test helpers

extension TKUIRoutingQueryInputViewModelTest {
  enum Input {
    case type(String)
    case mode(TKUIRoutingResultsViewModel.SearchMode)
    case select(String, index: Int)
    case swap
    case route
  }
  
  func run(_ actions: [Input]) -> [String] {
    let faker = FakeAutocompleter()
    
    let bag = DisposeBag()
    let scheduler = TestScheduler(initialClock: 0)
    let observer = scheduler.createObserver(String.self)
    
    // set-up inputs
    var searches = [Recorded<Event<(String, forced: Bool)>>]()
    var selections = [Recorded<Event<TKUIRoutingQueryInputViewModel.Item>>]()
    var modes = [Recorded<Event<TKUIRoutingResultsViewModel.SearchMode>>]()
    var swaps = [Recorded<Event<Void>>]()
    var routes = [Recorded<Event<Void>>]()
    for (index, action) in actions.enumerated() {
      let time: TestTime = (index + 1) * 100
      switch action {
      case .type(let text): searches.append(.next(time, (text, forced: false)))
      case .mode(let mode): modes.append(.next(time, mode))
      case .swap: swaps.append(.next(time, ()))
      case .route: routes.append(.next(time, ()))
      
      case .select(let text, let index):
        let result = TKAutocompletionResult()
        result.provider = faker
        result.title = text
        let autocompletion = TKUIAutocompletionViewModel.AutocompletionItem(
          index: index, completion: result, includeAccessory: false
        )
        let item = TKUIRoutingQueryInputViewModel.Item.autocompletion(autocompletion)
        selections.append(.next(time, item))
      }
    }

    let viewModel = TKUIRoutingQueryInputViewModel(inputs: TKUIRoutingQueryInputViewModel.UIInput(
      searchText: scheduler.createHotObservable(searches).asObservable(),
      tappedDone: scheduler.createHotObservable(routes).asSignal(onErrorSignalWith: .empty()),
      selected: scheduler.createHotObservable(selections).asSignal(onErrorSignalWith: .empty()),
      selectedSearchMode: scheduler.createHotObservable(modes).asSignal(onErrorSignalWith: .empty()),
      tappedSwap: scheduler.createHotObservable(swaps).asSignal(onErrorSignalWith: .empty())
    ), providers: [faker])
    
    // recording
    
    viewModel.originDestination
      .asObservable()
      .map { "\($0.origin) -- \($0.destination)" }
      .bind(to: observer)
      .disposed(by: bag)
    
    viewModel.selections
      .asObservable()
      .map { (($0.0.title ?? nil) ?? "", ($0.1.title ?? nil) ?? "") }
      .map { "✅ \($0) -- \($1)" }
      .bind(to: observer)
      .disposed(by: bag)
    
    // get the results
    
    scheduler.start()
    
    return observer.events
      .compactMap { event in
        switch event.value {
        case .next(let item): return item
        default: return nil
        }
      }
  }
}

fileprivate extension MKPointAnnotation {
  static let maroubra: MKPointAnnotation = {
    let annotation = MKPointAnnotation()
    annotation.title = "Maroubra"
    annotation.coordinate = CLLocationCoordinate2D(latitude: -33.870748, longitude: 151.205968)
    return annotation
  }()
}

fileprivate extension TKUIRoutingQueryInputViewModel.UIInput {
  static let dummy = TKUIRoutingQueryInputViewModel.UIInput(
    searchText: .empty(),
    tappedDone: .empty()
  )
}

fileprivate extension TKUIRoutingQueryInputViewModel.Item {
  var title: String {
    switch self {
    case .action(let action): return action.title
    case .autocompletion(let item): return item.title
    case .currentLocation: return "Current Location"
    }
  }
  
  var accessory: UIImage? {
    switch self {
    case .action, .currentLocation: return nil
    case .autocompletion(let item): return item.accessoryImage
    }
  }
}

fileprivate class FakeAutocompleter: TKAutocompleting {
  static let cities = [
    "Sydney", "Melbourne",
    "Bahia Blanca",
    "Nuremberg", "Munich", "Madrid", "London", "Helsinki",
    "Ho Chi Minh City"
  ]
  
  func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    let results = Self.cities
      .filter { $0.starts(with: input) || input.isEmpty }
      .map { name -> TKAutocompletionResult in
        let result = TKAutocompletionResult()
        result.title = name
        result.image = TKAutocompletionResult.image(forType: .city)
        result.accessoryButtonImage = TKAutocompletionResult.image(forType: .history)
        result.object = name
        result.score = 100 - (Self.cities.firstIndex(of: name) ?? 100)
        return result
      }
    completion(.success(results))
  }
  
  func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    let annotation = MKPointAnnotation()
    annotation.title = result.title
    annotation.coordinate = kCLLocationCoordinate2DInvalid
    completion(.success(annotation))
  }

}
