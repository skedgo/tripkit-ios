//
//  TKShareHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 29/08/2016.
//
//

import Foundation

import RxSwift

// MARK: - Query URLs

public extension TKShareHelper {
  
  enum ExtractionError: String, Error {
    case invalidURL
    case invalidCoordinate
    case missingNecessaryInformation
  }

  struct QueryDetails {
    public enum Time {
      case leaveASAP
      case leaveAfter(Date)
      case arriveBy(Date)
    }
    
    public let start: CLLocationCoordinate2D?
    public let end: CLLocationCoordinate2D
    public let title: String?
    public let timeType: Time
  }
  
  /// Extracts the query details from a TripGo API-compatible deep link
  /// - parameter url: TripGo API-compatible deep link
  /// - parameter geocoder: Geocoder used for filling in missing information
  static func queryDetails(for url: URL, using geocoder: SGGeocoder) -> Observable<QueryDetails> {
    
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { return Observable.error(ExtractionError.invalidURL) }
    
    // get the input from the query
    var tlat, tlng: Double?
    var name: String?
    var flat, flng: Double?
    var type: Int?
    var time: Date?
    for item in items {
      guard let value = item.value, !value.isEmpty else { continue }
      switch item.name {
      case "tlat":  tlat = Double(value)
      case "tlng":  tlng = Double(value)
      case "tname": name = value
      case "flat":  flat = Double(value)
      case "flng":  flng = Double(value)
      case "type":  type = Int(value)
      case "time":
        guard let since1970 = TimeInterval(value) else { continue }
        time = Date(timeIntervalSince1970: since1970)
      default:
        SGKLog.debug("OpenURLHelper", text: "Ignoring \(item.name)=\(value)")
      }
    }
    
    func coordinate(lat: Double?, lng: Double?) -> CLLocationCoordinate2D {
      if let lat = lat, let lng = lng {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
      } else {
        return kCLLocationCoordinate2DInvalid
      }
    }
    
    // we need a to coordinate OR a name
    let to = coordinate(lat: tlat, lng: tlng)
    guard to.isValid || name != nil else {
      return Observable.error(ExtractionError.missingNecessaryInformation)
    }
    
    // we're good to go, construct the time and from info
    let timeType: QueryDetails.Time
    if let type = type {
      switch (type, time != nil) {
      case (1, true): timeType = .leaveAfter(time!)
      case (2, true): timeType = .arriveBy(time!)
      default:        timeType = .leaveASAP
      }
    } else {
      timeType = .leaveASAP
    }
    let from = coordinate(lat: flat, lng: flng)
    
    // make sure we got a destination
    let named = SGKNamedCoordinate(coordinate: to)
    named.address = name
    return named.rx_valid(geocoder: geocoder)
      .map { valid in
        precondition(valid.coordinate.isValid)
        return QueryDetails(
          start: from.isValid ? from : nil,
          end: valid.coordinate,
          title: name,
          timeType: timeType
        )
    }
  }
  
}

extension TKShareHelper.QueryDetails {
  /// Converts the query details into a TripRequest
  /// - parameter tripKit: TripKit's managed object context into which
  ///                      to insert the request
  public func toTripRequest(in tripKit: NSManagedObjectContext) -> TripRequest {
    let from, to: MKAnnotation
    if let start = start, start.isValid {
      from = SGKNamedCoordinate(coordinate: start)
    } else {
      from = SGLocationManager.shared.currentLocation
    }
    
    if end.isValid {
      let named = SGKNamedCoordinate(coordinate: end)
      named.name = self.title
      to = named
    } else {
      to = SGLocationManager.shared.currentLocation
    }
    
    let timeType: SGTimeType
    let date: Date?
    switch self.timeType {
    case .leaveASAP:
      timeType = .leaveASAP
      date = nil
    case .leaveAfter(let time):
      timeType = .leaveAfter
      date = time
    case .arriveBy(let time):
      timeType = .arriveBefore
      date = time
    }
    
    return TripRequest.insert(from: from, to: to, for: date, timeType: timeType, into: tripKit)
  }
}

// MARK: - Meet URLs

public extension TKShareHelper {

  static func meetingDetails(for url: URL, using geocoder: SGGeocoder) -> Observable<QueryDetails> {
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { return Observable.empty() }
    
    var adjusted = items.compactMap { item -> URLQueryItem? in
      guard let value = item.value, !value.isEmpty else { return nil }
      switch item.name {
      case "lat":   return URLQueryItem(name: "tlat",  value: value)
      case "lng":   return URLQueryItem(name: "tlng",  value: value)
      case "at":    return URLQueryItem(name: "time",  value: value)
      case "name":  return URLQueryItem(name: "tname", value: value)
      default:      return nil
      }
    }
    
    adjusted.append(URLQueryItem(name: "type", value: "2"))
    
    components.queryItems = adjusted
    guard let newUrl = components.url else {
      assertionFailure()
      return Observable.empty()
    }
    
    return queryDetails(for: newUrl, using: geocoder)
  }
}

// MARK: - Stop URLs

public extension TKShareHelper {
  
  struct StopDetails {
    public let region: String
    public let code: String
    public let filter: String?
  }
  
  static func stopDetails(for url: URL) -> Observable<StopDetails> {
    let pathComponents = url.path.components(separatedBy: "/")
    guard pathComponents.count >= 4 else { return Observable.empty() }
    
    let region = pathComponents[2]
    let code = pathComponents[3]
    let filter: String? = pathComponents.count >= 5 ? pathComponents[4] : nil
    
    let result = StopDetails(region: region, code: code, filter: filter)
    return Observable.just(result)
  }
}

extension TKShareHelper.StopDetails {
  /// Converts the stop details into a StopLocation
  /// - parameter tripKit: TripKit's managed object context into which
  ///                      to insert the stop location
  public func toStopLocation(in tripKit: NSManagedObjectContext) -> StopLocation {
    let stop = StopLocation.fetchOrInsertStop(forStopCode: code, inRegionNamed: region, intoTripKitContext: tripKit)
    stop.filter = filter
    return stop
  }
}

// MARK: - Service URLs

public extension TKShareHelper {
  
  struct ServiceDetails {
    public let region: String
    public let stopCode: String
    public let serviceID: String
  }

  static func serviceDetails(for url: URL) -> Observable<ServiceDetails> {
    let pathComponents = url.path.components(separatedBy: "/")
    if pathComponents.count >= 5 {
      let region = pathComponents[2]
      let stopCode = pathComponents[3]
      let serviceID = pathComponents[4]
      
      let details = ServiceDetails(region: region, stopCode: stopCode, serviceID: serviceID)
      return Observable.just(details)
    }

    // Old way of /service?regionName=...&stopCode=...&serviceID=...
    if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
      let region = items.value(for: "regionName"),
      let stop = items.value(for: "stopCode"),
      let service = items.value(for: "serviceID") {
      
      let details = ServiceDetails(region: region, stopCode: stop, serviceID: service)
      return Observable.just(details)
      
    } else {
      return Observable.empty()
    }
  }
}

extension Array where Element == URLQueryItem {
  
  fileprivate func value(for key: String) -> String? {
    guard let item = first(where: { $0.name == key }) else { return nil }
    
    return item.value?.removingPercentEncoding
  }
  
}


// MARK: - Helpers

extension MKAnnotation {
  
  /// An Observable passing back `self` if its coordinate is valid or it could get geocoded.
  public func rx_valid(geocoder: SGGeocoder) -> Observable<MKAnnotation> {
    if coordinate.isValid {
      return Observable.just(self)
    }
    
    guard let geocodable = SGKNamedCoordinate.namedCoordinate(for: self) else {
      return Observable.error(TKShareHelper.ExtractionError.invalidCoordinate)
    }
    
    return Observable.create() { observer in
      SGBaseGeocoder.geocode(geocodable, using: geocoder, near: .world) { (result: SGBaseGeocoder.Result) -> Void in
        switch result {
        case .success:
          observer.onNext(self)
          observer.onCompleted()
        case .error(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }
  
}

