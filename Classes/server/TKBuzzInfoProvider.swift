//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

public final class RegionInformation: NSObject {
  
  public let streetBikePaths: Bool
  public let streetWheelchairAccessibility: Bool
  public let transitModes: [ModeInfo]
  public let transitBicycleAccessibility: Bool
  public let transitConcessionPricing: Bool
  public let transitWheelchairAccessibility: Bool
  public let paratransitInformation: ParatransitInformation?
  
  private init(
    streetBikePaths: Bool,
    streetWheelchairAccessibility: Bool,
    transitModes: [ModeInfo],
    transitBicycleAccessibility: Bool,
    transitWheelchairAccessibility: Bool,
    transitConcessionPricing: Bool,
    paratransitInformation: ParatransitInformation?)
  {
    self.streetBikePaths = streetBikePaths
    self.streetWheelchairAccessibility = streetWheelchairAccessibility
    self.transitModes = transitModes
    self.transitBicycleAccessibility = transitBicycleAccessibility
    self.transitConcessionPricing = transitConcessionPricing
    self.transitWheelchairAccessibility = transitWheelchairAccessibility
    self.paratransitInformation = paratransitInformation
  }
  
  fileprivate class func fromJSONResponse(_ response: Any?) -> RegionInformation? {
    guard let JSON = response as? [String: Any],
      let regions = JSON["regions"] as? [[String: Any]],
      let region = regions.first else {
        return nil
    }
    
    // For backwards compatibility. Can get removed, once all SkedGo servers have been updated
    let transitBicycleAccessibility =
      region["transitBicycleAccessibility"] as? Bool
        ?? region["allowsBicyclesOnPublicTransport"] as? Bool
        ?? false
    let transitWheelchairAccessibility =
      region["transitWheelchairAccessibility"] as? Bool
        ?? region["hasWheelchairInformation"] as? Bool
        ?? false
    let transitConcessionPricing =
      region["transitConcessionPricing"] as? Bool
        ?? region["supportsConcessionPricing"] as? Bool
        ?? false
    
    return RegionInformation(
      streetBikePaths: region["streetBikePaths"] as? Bool ?? false,
      streetWheelchairAccessibility: region["streetWheelchairAccessibility"] as? Bool ?? false,
      transitModes: ModeInfo.fromJSONResponse(response),
      transitBicycleAccessibility: transitBicycleAccessibility,
      transitWheelchairAccessibility: transitWheelchairAccessibility,
      transitConcessionPricing: transitConcessionPricing,
      paratransitInformation: ParatransitInformation.fromJSONResponse(response)
    )
  }
}

public final class TransitAlertInformation: NSObject, TKAlert {
  public let title: String
  public let text: String?
  public let URL: String?
  public let icon: UIImage?
  public let iconURL: URL?
  public let lastUpdated: Date?
  
  private init(title: String, text: String? = nil, url: String? = nil, icon: UIImage? = nil, iconURL: URL? = nil, lastUpdated: Date? = nil) {
    self.title = title
    self.text = text
    self.URL = url
    self.icon = icon
    self.iconURL = iconURL
    self.lastUpdated = lastUpdated
  }
  
  fileprivate class func alertsFromJSONResponse(response: Any?) -> [TransitAlertInformation]? {
    guard
      let JSON = response as? [String: Any],
      let array = JSON["alerts"] as? [[String: Any]]
      else {
        return nil
    }
    
    let alerts = array.flatMap { dict -> TransitAlertInformation? in
      guard let alertDict = dict["alert"] as? [String: Any] else {
        return nil
      }
      
      let title = alertDict["title"] as? String ?? ""
      let text = alertDict["text"] as? String
      let stringURL = alertDict["url"] as? String
      return TransitAlertInformation(title: title, text: text, url: stringURL)
    }
    
    return alerts
  }
}

/**
 Informational class for paratransit information (i.e., transport for people with disabilities).
 Contains name of service, URL with more information and phone number.
 
 - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
 */
public final class ParatransitInformation: NSObject {
  public let name: String
  public let URL: String
  public let number: String
  
  fileprivate init(name: String, URL: String, number: String) {
    self.name = name
    self.URL = URL
    self.number = number
  }
  
  fileprivate class func fromJSONResponse(_ response: Any?) -> ParatransitInformation? {
    guard let JSON = response as? [String: Any],
          let regions = JSON["regions"] as? [[String: Any]],
          let region = regions.first,
          let dict = region["paratransit"] as? [String: String],
          let name = dict["name"],
          let URL = dict["URL"],
          let number = dict["number"] else {
      return nil
    }
    
    return ParatransitInformation(name: name, URL: URL, number: number)
  }
}

extension ModeInfo {
  fileprivate class func fromJSONResponse(_ response: Any?) -> [ModeInfo] {
    guard let JSON = response as? [String: Any],
          let regions = JSON["regions"] as? [[String: Any]],
          let region = regions.first,
          let array = region["transitModes"] as? [[String: Any]] else {
      return []
    }
    
    return array.flatMap { ModeInfo(for: $0) }
  }
}

extension TKBuzzInfoProvider {

  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: SVKRegion, completion: @escaping (RegionInformation?) -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: RegionInformation.fromJSONResponse,
      completion: completion
    )
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchTransitAlerts(forRegion region: SVKRegion, completion: @escaping ([TransitAlertInformation]?) -> Void) {
    let paras = [
      "region": region.name
    ]
    
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: "GET",
      path: "alerts/transit.json",
      parameters: paras,
      region: region,
      success: { _, response in
        let result = TransitAlertInformation.alertsFromJSONResponse(response: response)
        completion(result)
      },
      failure: { _ in
        completion(nil)
    })
  }
  
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: @escaping (ParatransitInformation?) -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: ParatransitInformation.fromJSONResponse,
      completion: completion
    )
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: @escaping ([ModeInfo]) -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: ModeInfo.fromJSONResponse,
      completion: completion
    )
  }

  fileprivate class func fetchRegionInfo<E>(_ region: SVKRegion, transformer: @escaping (Any?) -> E, completion: @escaping (E) -> Void)
  {
    let paras = [
      "region": region.name
    ]
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: "POST",
      path: "regionInfo.json",
      parameters: paras,
      region: region,
      success: { _, response in
        let result = transformer(response)
        completion(result)
      },
      failure: { _ in
        let result = transformer(nil)
        completion(result)
      })
  }
  
  // MARK: - Rx variants.
  
  /**
   Asynchronously fetches transit alerts for the provided region using Rx.
   */
  public class func rx_fetchTransitAlerts(forRegion region: SVKRegion) -> Observable<[TKAlert]> {
    let paras: [String: Any] = [
      "region": region.name as Any
    ]
    
    return SVKServer.sharedInstance().rx
      .hit(.GET, path: "alerts/transit.json", parameters: paras, region: region)
      .map { (_, response) -> [TKAlert] in
        if let jsonResponse = response?.dictionaryObject {
          let alerts = TransitAlertInformation.alertsFromJSONResponse(response: jsonResponse)
          return alerts ?? []
        } else {
          return []
        }
    }
  }
}

public struct CarParkInfo {
  public let identifier: String
  public let name: String
  public let availableSpaces: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?
}

public class LocationInformation : NSObject {
  public let what3word: String?
  public let what3wordInfoURL: URL?
  
  public let transitStop: STKStopAnnotation?
  
  public let carParkInfo: CarParkInfo?
  
  fileprivate init(what3word: String?, what3wordInfoURL: String?, transitStop: STKStopAnnotation?, carParkInfo: CarParkInfo?) {
    self.what3word = what3word
    if let URLString = what3wordInfoURL {
      self.what3wordInfoURL = URL(string: URLString)
    } else {
      self.what3wordInfoURL = nil
    }
    
    self.transitStop = transitStop
    self.carParkInfo = carParkInfo
  }
  
  public var hasRealTime: Bool {
    if let carParkInfo = carParkInfo {
      return carParkInfo.availableSpaces != nil
    } else {
      return false
    }
  }
}

// MARK: - Protocol

@objc public protocol TKAlert {
  
  var icon: UIImage? { get }
  var iconURL: URL? { get }
  var title: String { get }
  var text: String? { get }
  var URL: String? { get }
  var lastUpdated: Date? { get }
  
}

// MARK: - Extensions

extension CarParkInfo {
  
  fileprivate init?(response: Any?) {
    guard
      let JSON = response as? [String: Any],
    let identifier = JSON["identifier"] as? String,
      let name = JSON["name"] as? String
      else {
        return nil
    }
    
    self.identifier = identifier
    self.name = name
    self.availableSpaces = JSON["availableSpaces"] as? Int
    self.totalSpaces = JSON["totalSpaces"] as? Int
    if let seconds = JSON["lastUpdate"] as? TimeInterval {
      self.lastUpdate = Date(timeIntervalSince1970: seconds)
    } else {
      self.lastUpdate = nil
    }
  }
  
}

extension LocationInformation {
  
  public convenience init?(response: Any?) {
    guard let JSON = response as? [String: Any] else {
      return nil
    }
    
    let details = JSON["details"] as? [String: Any]
    let what3word = details?["w3w"] as? String
    let what3wordInfoURL = details?["w3wInfoURL"] as? String
    
    let stop: STKStopAnnotation?
    if let stopJSON = JSON["stop"] as? [String: Any] {
      stop = TKParserHelper.simpleStop(from: stopJSON)
    } else {
      stop = nil
    }
    
    let carParkInfo = CarParkInfo(response: JSON["carPark"])
    
    self.init(what3word: what3word, what3wordInfoURL: what3wordInfoURL, transitStop: stop, carParkInfo: carParkInfo)
  }
  
}

extension TKBuzzInfoProvider {
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
  */
  public class func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, forRegion region: SVKRegion, completion: @escaping (LocationInformation?) -> Void) {
    let paras: [String: Any] = [
      "lat": coordinate.latitude,
      "lng": coordinate.longitude
    ]
    
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: "GET",
      path: "locationInfo.json",
      parameters: paras,
      region: region,
      success: { _, response in
        completion(LocationInformation(response: response))
      },
      failure: { _ in
        completion(nil)
      })
    
  }
  
}

