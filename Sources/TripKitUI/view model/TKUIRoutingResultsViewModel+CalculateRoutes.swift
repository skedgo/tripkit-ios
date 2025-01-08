//
//  TKUIRoutingResultsViewModel+CalculateRoutes.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

import RxSwift

import TripKit

extension TKUIRoutingResultsViewModel {
  
  struct RouteBuilder: Codable {
    enum Time: Equatable, Codable {
      private enum CodingKeys: String, CodingKey {
        case type
        case date
      }
      
      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let date = try? container.decode(Date.self, forKey: .date)
        switch (type, date) {
        case ("leaveAfter", .some(let date)): self = .leaveAfter(date)
        case ("arriveBefore", .some(let date)): self = .arriveBefore(date)
        default: self = .leaveASAP
        }
      }
      
      func encode(to encoder: Encoder) throws {
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
    
    @MainActor
    init(destination: MKAnnotation, origin: MKAnnotation? = nil) {
      self.mode = origin == nil ? .origin : .destination
      self.select = .destination
      self.origin = origin.map(TKNamedCoordinate.namedCoordinate(for:))
      self.destination = TKNamedCoordinate.namedCoordinate(for: destination)
      self.time = TKUIRoutingResultsCard.config.timePickerConfig.allowsASAP ? .leaveASAP : nil
    }
    
    @MainActor
    fileprivate init(mode: TKUIRoutingResultsViewModel.SearchMode, origin: TKNamedCoordinate? = nil, destination: TKNamedCoordinate? = nil, time: Time? = nil) {
      self.mode = mode
      self.origin = origin
      self.destination = destination
      self.time = time ?? (TKUIRoutingResultsCard.config.timePickerConfig.allowsASAP ? .leaveASAP : nil)
    }
    
    fileprivate(set) var mode: TKUIRoutingResultsViewModel.SearchMode
    fileprivate(set) var select: TKUIRoutingResultsViewModel.SearchMode?
    fileprivate(set) var origin: TKNamedCoordinate?
    fileprivate(set) var destination: TKNamedCoordinate?
    fileprivate(set) var time: Time?

    @MainActor fileprivate static var empty = RouteBuilder(mode: .destination)
  }
  
}

// MARK: - Builder

extension TKUIRoutingResultsViewModel {
  
  static func buildId(for builder: RouteBuilder, force: Bool = false) -> String {
    guard !force else { return UUID().uuidString }
    var id: String
    if let time = builder.time {
      id = "\(time.timeType.rawValue)-\(Int(time.date.timeIntervalSince1970))-"
    } else {
      id = "unknown-"
    }
    if let origin = builder.origin {
      id.append("\(Int(origin.coordinate.latitude * 100_000)),\(Int(origin.coordinate.longitude * 100_000)),\(origin.address ?? "")")
    }
    if let destination = builder.destination {
      id.append("\(Int(destination.coordinate.latitude * 100_000)),\(Int(destination.coordinate.longitude * 100_000)),\(destination.address ?? "")")
    }
    return id
  }
  
  static func watch(_ initial: RouteBuilder, inputs: UIInput, mapInput: MapInput) -> Observable<(RouteBuilder, id: String)> {
    
    typealias BuilderInput = (
      date: RouteBuilder.Time?,
      search: SearchResult?,
      pin: CLLocationCoordinate2D?,
      forceRefresh: Bool
    )
    
    // When changing modes, force refresh
    let refresh: Observable<BuilderInput> = inputs.changedModes.asObservable()
      .map { _ in (date: nil, search: nil, pin: nil, forceRefresh: true) }
    
    // When changing date, switch to that date
    let date: Observable<BuilderInput> = inputs.changedDate.asObservable()
      .distinctUntilChanged()
      .map { (date: $0, search: nil, pin: nil, forceRefresh: false) }

    // When dropping pin, set it
    let pin: Observable<BuilderInput> = mapInput.droppedPin.asObservable()
      .map { (date: nil, search: nil, pin: $0, forceRefresh: false) }
    
    // ...
    let search: Observable<BuilderInput> = inputs.changedSearch.asObservable()
      .map { (date: nil, search: $0, pin: nil, forceRefresh: false) }

    let relevantInput = Observable.merge(date, search, pin, refresh)
    
    return relevantInput
      .scan( (initial, buildId(for: initial)) ) { previous, change in
        var updated = previous.0
        
        if let time = change.date {
          updated.time = time
        }
        
        if let pin = change.pin {
          updated.select = updated.mode
          updated.dropPin(at: pin)
        }
        
        if let search = change.search {
          if search.mode == .origin {
            updated.origin = TKNamedCoordinate.namedCoordinate(for: search.location)
          } else {
            updated.destination = TKNamedCoordinate.namedCoordinate(for: search.location)
          }
          updated.select = .none
        }
        
        return (updated, id: Self.buildId(for: updated, force: change.forceRefresh) )
      }
      .startWith( (initial, id: buildId(for: initial)) )
  }
  
  static func locationsChanged(in builder: RouteBuilder, id: String) -> Observable<(RouteBuilder, id: String)> {
    // This looks fairly complicated but all it does is monitoring the builder's
    // origin and destination annotations for changes to their coordinates, and
    // then triggers a rebuild.
    
    func isCloseEnough(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> Bool {
      guard let distance = first.distance(from: second) else { return true }
      return distance < 50
    }
    
    var origin: Observable<(RouteBuilder, id: String)> = .empty()
    var destination: Observable<(RouteBuilder, id: String)> = .empty()
    if let asObject = builder.origin {
      origin = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
        .compactMap { [weak asObject] _ in asObject?.coordinate }
        .distinctUntilChanged(isCloseEnough)
        .flatMap { [weak asObject] _ in RouteBuilder.needAddress(asObject, retryLimit: 3, delay: 1) }
        .map { _ in (builder, Self.buildId(for: builder)) }
    }
    if let asObject = builder.destination {
      destination = asObject.rx.observeWeakly(CLLocationCoordinate2D.self, "coordinate")
        .compactMap { [weak asObject] _ in asObject?.coordinate }
        .distinctUntilChanged(isCloseEnough)
        .flatMap { [weak asObject] _ in RouteBuilder.needAddress(asObject, retryLimit: 3, delay: 1) }
        .map { _ in (builder, Self.buildId(for: builder)) }
    }
    return Observable.merge(origin, destination)
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
  
  static func fetch(for request: Observable<TripRequest>, skipInitial: Bool, limitTo modes: Set<String>? = nil, errorPublisher: PublishSubject<Error>) -> Observable<TKUIResultsFetcher.Progress> {
    return request
      .filter { $0.managedObjectContext != nil }
      .flatMapLatest { request -> Observable<TKUIResultsFetcher.Progress> in
        if skipInitial, request.hasTrips, !request.expandForFavorite {
          return .just(.finished)
        }
        
        if let restricted = modes, !Set(restricted).isSubset(of: Set(request.spanningRegion.modeIdentifiers)) {
          assertionFailure("Try to limit search results to modes that are not supported in the region.")
        }
        
        // Fetch the trip and handle errors in here, to not abort the outer observable
        return TKUIResultsFetcher
          .streamTrips(for: request, modes: modes, classifier: TKMetricClassifier())
          .do(onNext: { progress in
            if progress == .finished {
              try? request.managedObjectContext?.save()
            }
          })
          .catch { error in
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
  
  @MainActor
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
  
  var timeZone: TimeZone {
    switch time {
    case .leaveASAP, .leaveAfter, .none:
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
  
  func reverseGeocodeLocations() -> Observable<(origin: String?, destination: String?)> {
    let originObservable = Self.needAddress(origin, retryLimit: 5, delay: 5)
    let destinationObservable = Self.needAddress(destination, retryLimit: 5, delay: 5)
    return Observable
      .combineLatest(originObservable, destinationObservable) { (origin: $0, destination: $1) }
      .distinctUntilChanged { $0.origin == $1.origin && $0.destination == $1.destination }
  }
  
  static func needAddress(_ location: TKNamedCoordinate?, retryLimit: Int, delay: Int) -> Observable<String?> {
    if let from = location?.title, from != Loc.Location {
      return .just(from)
    } else if let location {
      return Self.geocode(location, retryLimit: retryLimit, delay: delay).catchAndReturn(nil)
    } else {
      return .just(nil)
    }
  }
  
  private static func geocode(_ location: TKNamedCoordinate, retryLimit: Int, delay: Int) -> Observable<String?> {
    return CLGeocoder().rx
      .reverseGeocode(namedCoordinate: location)
      .asObservable()
      .retry { errors in
        return errors.enumerated().flatMap { (index, error) -> Observable<Int> in
          guard index < retryLimit else { throw error }
          return Observable<Int>.timer(RxTimeInterval.seconds(delay), scheduler: MainScheduler.instance)
        }
      }
  }
  
  func generateRequest() -> TripRequest? {
    guard let destination = destination, let time = time else { return nil }
    
    let origin = self.origin ?? TKLocationManager.shared.currentLocation
    
    return TripRequest.insert(
      from: origin, to: destination,
      for: time.date, timeType: time.timeType,
      into: TripKit.shared.tripKitContext
    )
  }
  
  var timeString: (text: String, highlight: Bool) {
    switch time {
    case .some(let time):
      return (time.timeString(in: timeZone), time != .leaveASAP)

    case .none:
      return (Loc.SetTime, true)
    }
  }
  
}

extension TKUIRoutingResultsViewModel.RouteBuilder.Time {
  func timeString(in timeZone: TimeZone) -> String {
    let timePickerConfigurator = TKUIRoutingResultsCard.config.timePickerConfig
    switch self {
    case .leaveASAP:
      return Loc.LeaveNow
    
    case .leaveAfter(let time):
      return Self.timeString(prefix: timePickerConfigurator.leaveAtLabel, time: time, in: timeZone)

    case .arriveBefore(let time):
      return Self.timeString(prefix: timePickerConfigurator.arriveByLabel, time: time, in: timeZone)
    }
  }
  
  private static func timeString(prefix: String, time: Date?, in timeZone: TimeZone?) -> String {
    var string = prefix
    string.append(" ")
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    formatter.locale = .current
    formatter.doesRelativeDateFormatting = true
    formatter.timeZone = timeZone
    
    if let time = time {
      var timeString = formatter.string(from: time)
      timeString = timeString.replacingOccurrences(of: " pm", with: "pm")
      timeString = timeString.replacingOccurrences(of: " am", with: "am")
      string.append(timeString.localizedLowercase)
    }
    
    if let offset = timeZone?.secondsFromGMT(), let short = timeZone?.abbreviation(), offset != TimeZone.current.secondsFromGMT() {
      string.append(" ")
      string.append(short)
    }
    
    return string
  }
}

// MARK: - RxDataSources protocol conformance

extension TKUIRoutingResultsViewModel.RouteBuilder: Equatable {
  static func ==(lhs: TKUIRoutingResultsViewModel.RouteBuilder, rhs: TKUIRoutingResultsViewModel.RouteBuilder) -> Bool {
    return lhs.time == rhs.time
      && lhs.origin === rhs.origin
      && lhs.destination === rhs.destination
      && lhs.mode == rhs.mode
  }
}

// MARK: -

extension Reactive where Base: CLGeocoder {
  
  func reverseGeocode(namedCoordinate: TKNamedCoordinate) -> Single<String?> {
    return Single.create { single in
      let location = CLLocation(latitude: namedCoordinate.coordinate.latitude, longitude: namedCoordinate.coordinate.longitude)
      
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
        if let error {
          single(.failure(error))
        } else {
          if let first = placemarks?.first {
            // TODO: Shouldn't always overwrite the name, e.g., if it's from a favourite
            namedCoordinate.assignPlacemark(first, includeName: true)
          }
          single(.success(placemarks?.first?.name))
        }
      }
      
      return Disposables.create()
    }
  }
  
}

