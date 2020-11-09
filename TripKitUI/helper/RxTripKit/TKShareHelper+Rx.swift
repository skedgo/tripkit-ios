//
//  TKShareHelper+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

// MARK: - Query URLs

public extension TKShareHelper {
  
  /// Extracts the query details from a TripGo API-compatible deep link
  /// - parameter url: TripGo API-compatible deep link
  /// - parameter geocoder: Geocoder used for filling in missing information
  static func queryDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) -> Single<QueryDetails> {
    
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { return .error(ExtractionError.invalidURL) }
    
    // get the input from the query
    var tlat, tlng: Double?
    var name: String?
    var flat, flng: Double?
    var type: Int?
    var time: Date?
    var modes: [String] = .init()
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
        guard let date = TKParserHelper.parseDate(value) else { continue }
        time = date
      case "modes", "mode":
        modes.append(value)
      default:
//        TKLog.debug("TKShareHelper", text: "Ignoring \(item.name)=\(value)")
        continue
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
      return .error(ExtractionError.missingNecessaryInformation)
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
    let named = TKNamedCoordinate(coordinate: to)
    named.address = name
    return named.rx_valid(geocoder: geocoder)
      .map { valid in
        precondition(valid.coordinate.isValid)
        return QueryDetails(
          start: from.isValid ? from : nil,
          end: valid.coordinate,
          title: name,
          timeType: timeType,
          modes: modes
        )
    }
  }
  
}

// MARK: - Meet URLs

public extension TKShareHelper {

  static func meetingDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) -> Single<QueryDetails> {
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { return .error(ExtractionError.invalidURL) }
    
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
      return .error(ExtractionError.invalidURL)
    }
    
    return queryDetails(for: newUrl, using: geocoder)
  }
}

// MARK: - Stop URLs

public extension TKShareHelper {
  
  static func stopDetails(for url: URL) -> Single<StopDetails> {
    let pathComponents = url.path.components(separatedBy: "/")
    guard pathComponents.count >= 4 else { return .error(ExtractionError.missingNecessaryInformation) }
    
    let region = pathComponents[2]
    let code = pathComponents[3]
    let filter: String? = pathComponents.count >= 5 ? pathComponents[4] : nil
    
    let result = StopDetails(region: region, code: code, filter: filter)
    return .just(result)
  }
  
}

// MARK: - Service URLs

public extension TKShareHelper {

  static func serviceDetails(for url: URL) -> Single<ServiceDetails> {
    let pathComponents = url.path.components(separatedBy: "/")
    if pathComponents.count >= 5 {
      let region = pathComponents[2]
      let stopCode = pathComponents[3]
      let serviceID = pathComponents[4]
      
      let details = ServiceDetails(region: region, stopCode: stopCode, serviceID: serviceID)
      return .just(details)
    }

    // Old way of /service?regionName=...&stopCode=...&serviceID=...
    if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
      let region = items.value(for: "regionName"),
      let stop = items.value(for: "stopCode"),
      let service = items.value(for: "serviceID") {
      
      let details = ServiceDetails(region: region, stopCode: stop, serviceID: service)
      return .just(details)
      
    } else {
      return .error(ExtractionError.missingNecessaryInformation)
    }
  }
}

// MARK: - Helpers

extension Array where Element == URLQueryItem {
  
  fileprivate func value(for key: String) -> String? {
    guard let item = first(where: { $0.name == key }) else { return nil }
    
    return item.value?.removingPercentEncoding
  }
  
}

extension MKAnnotation {
  
  /// A Single passing back `self` if its coordinate is valid or it could get geocoded.
  public func rx_valid(geocoder: TKGeocoding) -> Single<MKAnnotation> {
    if coordinate.isValid {
      return .just(self)
    }
    
    guard let geocodable = TKNamedCoordinate.namedCoordinate(for: self) else {
      return .error(TKShareHelper.ExtractionError.invalidCoordinate)
    }
    
    return TKGeocoderHelper.rx.geocode(geocodable, using: geocoder, near: .world)
      .asObservable()
      .compactMap { [weak self] _ in self }
      .asSingle()
  }
  
}

