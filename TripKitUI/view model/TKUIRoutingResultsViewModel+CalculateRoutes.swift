//
//  TKUIRoutingResultsViewModel+CalculateRoutes.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension TKUIRoutingResultsViewModel {
  
  public struct RouteBuilder: Codable {
    fileprivate enum SelectionMode: String, Equatable, Codable {
      case origin
      case destination
    }
    
    public enum Time: Equatable, Codable {
      private enum CodingKeys: String, CodingKey {
        case type
        case date
      }
      
      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let date = try? container.decode(Date.self, forKey: .date)
        switch (type, date) {
        case ("leaveAfter", .some(let date)): self = .leaveAfter(date)
        case ("arriveBefore", .some(let date)): self = .arriveBefore(date)
        default: self = .leaveASAP
        }
      }
      
      public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .leaveASAP:
          try container.encode("leaveASAP", forKey: .type)
        case .leaveAfter(let date):
          try container.encode("leaveAfter", forKey: .type)
          try container.encode(date, forKey: .date)
        case .arriveBefore(let date):
          try container.encode("arriveBefore", forKey: .type)
          try container.encode(date, forKey: .date)
        }
      }
      
      case leaveASAP
      case leaveAfter(Date)
      case arriveBefore(Date)
    }
    
    init(destination: MKAnnotation) {
      self.init(mode: .origin, destination: TKNamedCoordinate.namedCoordinate(for: destination))
    }
    
    fileprivate init(mode: SelectionMode, origin: TKNamedCoordinate? = nil, destination: TKNamedCoordinate? = nil, time: Time = .leaveASAP) {
      self.mode = mode
      self.origin = origin
      self.destination = destination
      self.time = time
    }
    
    fileprivate var mode: SelectionMode
    fileprivate(set) var origin: TKNamedCoordinate?
    fileprivate(set) var destination: TKNamedCoordinate?
    fileprivate(set) var time: Time

    fileprivate static var empty = RouteBuilder(mode: .destination)
  }
  
}

// MARK: - Builder

extension TKUIRoutingResultsViewModel {
  
  static func watch(_ initial: RouteBuilder, inputs: UIInput, mapInput: MapInput) -> Observable<RouteBuilder> {
    
    typealias BuilderInput = (date: RouteBuilder.Time?, pin: CLLocationCoordinate2D?, forceRefresh: Bool)
    
    // When changing modes, force refresh
    let refresh: Observable<BuilderInput> = inputs.changedModes.asObservable()
      .map { _ in (date: nil, pin: nil, forceRefresh: true) }
      .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
    
    // When changing date, switch to that date
    let date: Observable<BuilderInput> = inputs.changedDate.asObservable()
      .distinctUntilChanged()
      .map { (date: $0, pin: nil, forceRefresh: false) }

    // When dropping pin, set it
    let pin: Observable<BuilderInput> = mapInput.droppedPin.asObservable()
      .map { (date: nil, pin: $0, forceRefresh: false) }

    let relevantInput = Observable.merge(date, pin, refresh)
    
    return relevantInput
      .scan(initial) { previous, change in
        var updated = previous
        if let time = change.date {
          updated.time = time
        }
        if let pin = change.pin {
          updated.dropPin(at: pin)
        }
        return updated
      }
      .startWith(initial)
  }
  
  static func locationsChanged(in builder: RouteBuilder) -> Observable<RouteBuilder> {
    // This looks fairly complicated but all it does is monitoring the builder's
    // origin and destination annotations for changes to their coordinates, and
    // then triggers a rebuild.
    var origin: Observable<CLLocationCoordinate2D?> = .empty()
    var destination: Observable<CLLocationCoordinate2D?> = .empty()
    if let asObject = builder.origin {
      origin = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    if let asObject = builder.destination {
      destination = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
    }
    return Observable.merge(origin, destination)
      .map { _ in builder }
  }
  
}

extension TKUIRoutingResultsViewModel.RouteBuilder {
  
  mutating func dropPin(at coordinate: CLLocationCoordinate2D) {
    let annotation = TKNamedCoordinate(coordinate: coordinate)
    
    switch mode {
    case .origin:
      annotation.title = Loc.StartLocation
      origin = annotation
      mode = .destination
    case .destination:
      annotation.title = Loc.EndLocation
      destination = annotation
      mode = .origin
    }
  }
  
}

// MARK: - Fetching routes

extension TKUIRoutingResultsViewModel {
  
  static func fetch(for request: Observable<TripRequest?>, errorPublisher: PublishSubject<Error>) -> Observable<TKResultsFetcher.Progress> {
    return request
      .filter { $0 != nil }
      .map { $0! }
      .distinctUntilChanged()
      .filter { $0.managedObjectContext != nil }
      .flatMapLatest { request in
        // Fetch the trip and handle errors in here, to not abort the outer observable
        return TKResultsFetcher
          .streamTrips(for: request, classifier: TKMetricClassifier())
          .catchError { error in
            errorPublisher.onNext(error)
            return .just(.finished)
          }
    }
  }
  
}

// MARK: - Routing

extension TKUIRoutingResultsViewModel {
  
  static func regionForModes(for builder: RouteBuilder) -> TKRegion {
    let start = builder.origin?.coordinate
    let end = builder.destination?.coordinate
    
    if let start = start, let end = end {
      return TKRegionManager.shared.region(containing: start, end)
    } else if let start = start, let local = TKRegionManager.shared.localRegions(containing: start).first {
      return local
    } else {
      return .international
    }
  }
  
}

extension TripRequest {
  
  var builder: TKUIRoutingResultsViewModel.RouteBuilder {
    
    let time: TKUIRoutingResultsViewModel.RouteBuilder.Time
    switch type {
    case .leaveASAP, .none:
      time = .leaveASAP
    case .leaveAfter:
      time = .leaveAfter(self.time!)
    case .arriveBefore:
      time = .arriveBefore(self.time!)
    }
    
    return TKUIRoutingResultsViewModel.RouteBuilder(
      mode: .destination,
      origin: fromLocation,
      destination: toLocation,
      time: time
    )
    
  }
  
}

extension TKUIRoutingResultsViewModel.RouteBuilder.Time {
  
  init(timeType: TKTimeType, date: Date) {
    switch timeType {
    case .leaveASAP, .none:
      self = .leaveASAP
    case .leaveAfter:
      self = .leaveAfter(date)
    case .arriveBefore:
      self = .arriveBefore(date)
    }
  }
  
  var date: Date {
    switch self {
    case .leaveASAP: return Date()
    case .leaveAfter(let date): return date
    case .arriveBefore(let date): return date
    }
  }
  
  var timeType: TKTimeType {
    switch self {
    case .leaveASAP: return .leaveASAP
    case .leaveAfter: return .leaveAfter
    case .arriveBefore: return .arriveBefore
    }
  }
  
  
}

extension TKUIRoutingResultsViewModel.RouteBuilder {
  
  var titles: (title: String, subtitle: String?) {
    let destinationName = destination?.title ?? nil
    let originName = origin?.title ?? nil
    
    let title: String
    if let name = destinationName {
      title = Loc.To(location: name)
    } else {
      title = Loc.PlanTrip
    }
    
    let subtitle: String
    if let name = originName {
      subtitle = Loc.From(location: name)
    } else {
      subtitle = Loc.FromCurrentLocation
    }
    return (title, subtitle)
  }
  
  var timeZone: TimeZone {
    switch time {
    case .leaveASAP, .leaveAfter:
      if let location = origin, let timeZone = TKRegionManager.shared.timeZone(for: location.coordinate) {
        return timeZone
      } else {
        fallthrough // prefer arrival time zone, over current
      }
      
    case .arriveBefore:
      if let location = destination, let timeZone = TKRegionManager.shared.timeZone(for: location.coordinate) {
        return timeZone
      }
    }
    return .current
  }
  
  func generateRequest() -> TripRequest? {
    guard let destination = destination else { return nil }
    
    let origin = self.origin ?? TKLocationManager.shared.currentLocation
    
    return TripRequest.insert(
      from: origin, to: destination,
      for: time.date, timeType: time.timeType,
      into: TripKit.shared.tripKitContext
    )
  }
  
}

// MARK: - Protocol conformance

public func ==(lhs: TKUIRoutingResultsViewModel.RouteBuilder, rhs: TKUIRoutingResultsViewModel.RouteBuilder) -> Bool {
  return lhs.time == rhs.time
    && lhs.origin === rhs.origin
    && lhs.destination === rhs.destination
    && lhs.mode == rhs.mode
}
extension TKUIRoutingResultsViewModel.RouteBuilder: Equatable { }

