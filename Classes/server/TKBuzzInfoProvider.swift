//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public final class RegionInformation: NSObject {
  
  public let publicTransportModes: [ModeInfo]
  public let allowsBicyclesOnPublicTransport: Bool
  public let supportsConcessionPricing: Bool
  public let hasWheelchairInformation: Bool
  public let paratransitInformation: ParatransitInformation?
  
  private init(transitModes: [ModeInfo], allowsBicyclesOnPublicTransport: Bool, hasWheelchairInformation: Bool, supportsConcessionPricing: Bool, paratransitInformation: ParatransitInformation?) {
    self.publicTransportModes = transitModes
    self.allowsBicyclesOnPublicTransport = allowsBicyclesOnPublicTransport
    self.hasWheelchairInformation = hasWheelchairInformation
    self.supportsConcessionPricing = supportsConcessionPricing
    self.paratransitInformation = paratransitInformation
  }
  
  private class func fromJSONResponse(response: AnyObject?) -> RegionInformation? {
    guard let JSON = response as? [String: AnyObject],
      let regions = JSON["regions"] as? [[String: AnyObject]],
      let region = regions.first else {
        return nil
    }
    
    let transitModes = ModeInfo.fromJSONResponse(response)
    let bicyclesOnTransit = region["allowsBicyclesOnPublicTransport"] as? Bool ?? false
    let wheelies = region["hasWheelchairInformation"] as? Bool ?? false
    let concession = region["supportsConcessionPricing"] as? Bool ?? false
    let para = ParatransitInformation.fromJSONResponse(response)
    
    return RegionInformation(transitModes: transitModes,
      allowsBicyclesOnPublicTransport: bicyclesOnTransit,
      hasWheelchairInformation: wheelies,
      supportsConcessionPricing: concession,
      paratransitInformation: para)
  }
}

public final class TransitAlertInformation: NSObject {
  public let title: String
  public let text: String?
  public let URL: NSURL?
  
  private init(title: String, text: String?, url: String?) {
    self.title = title
    self.text = text
    if let stringURL = url {
      self.URL = NSURL(string: stringURL)
    } else {
      self.URL = nil
    }
  }
  
  private class func alertsFromJSONResponse(response: AnyObject?) -> [TransitAlertInformation]? {
    guard
      let JSON = response as? [String: AnyObject],
      let array = JSON["alerts"] as? [[String: AnyObject]]
      else {
        return nil
    }
    
    let alerts = array.map { alertDict -> TransitAlertInformation in
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
  
  private init(name: String, URL: String, number: String) {
    self.name = name
    self.URL = URL
    self.number = number
  }
  
  private class func fromJSONResponse(response: AnyObject?) -> ParatransitInformation? {
    guard let JSON = response as? [String: AnyObject],
          let regions = JSON["regions"] as? [[String: AnyObject]],
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
  private class func fromJSONResponse(response: AnyObject?) -> [ModeInfo] {
    guard let JSON = response as? [String: AnyObject],
          let regions = JSON["regions"] as? [[String: AnyObject]],
          let region = regions.first,
          let array = region["transitModes"] as? [[String: AnyObject]] else {
      return []
    }
    
    return array.flatMap { ModeInfo(forDictionary: $0) }
  }
}

extension TKBuzzInfoProvider {

  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: SVKRegion, completion: RegionInformation? -> Void)
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
  public class func fetchTransitAlerts(forRegion region: SVKRegion, completion: [TransitAlertInformation]? -> Void) {
    let paras = [
      "region": region.name
    ]
    
    SVKServer.sharedInstance().hitSkedGoWithMethod(
      "GET",
      path: "alerts/transit.json",
      parameters: paras,
      region: region,
      success: { _, response in
        let result = TransitAlertInformation.alertsFromJSONResponse(response)
        completion(result)
      },
      failure: { _ in
        let result = TransitAlertInformation.alertsFromJSONResponse(nil)
        completion(result)
    })
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: ParatransitInformation? -> Void)
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
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: [ModeInfo] -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: ModeInfo.fromJSONResponse,
      completion: completion
    )
  }

  private class func fetchRegionInfo<E>(region: SVKRegion, transformer: AnyObject? -> E, completion: E -> Void)
  {
    let paras = [
      "region": region.name
    ]
    SVKServer.sharedInstance().hitSkedGoWithMethod(
      "POST",
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
}

public struct CarParkInfo {
  public let identifier: String
  public let name: String
  public let availableSpaces: Int?
  public let totalSpaces: Int?
  public let lastUpdate: NSDate?
}

public class LocationInformation : NSObject {
  public let what3word: String?
  public let what3wordInfoURL: NSURL?
  
  public let transitStop: STKStopAnnotation?
  
  public let carParkInfo: CarParkInfo?
  
  private init(what3word: String?, what3wordInfoURL: String?, transitStop: STKStopAnnotation?, carParkInfo: CarParkInfo?) {
    self.what3word = what3word
    if let URLString = what3wordInfoURL {
      self.what3wordInfoURL = NSURL(string: URLString)
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

// MARK: - Extensions

extension CarParkInfo {
  
  private init?(response: AnyObject?) {
    guard
      let JSON = response as? [String: AnyObject],
    let identifier = JSON["identifier"] as? String,
      let name = JSON["name"] as? String
      else {
        return nil
    }
    
    self.identifier = identifier
    self.name = name
    self.availableSpaces = JSON["availableSpaces"] as? Int
    self.totalSpaces = JSON["totalSpaces"] as? Int
    if let seconds = JSON["lastUpdate"] as? NSTimeInterval {
      self.lastUpdate = NSDate(timeIntervalSince1970: seconds)
    } else {
      self.lastUpdate = nil
    }
  }
  
}

extension LocationInformation {
  
  public convenience init?(response: AnyObject?) {
    guard let JSON = response as? [String: AnyObject] else {
      return nil
    }
    
    let details = JSON["details"] as? [String: AnyObject]
    let what3word = details?["w3w"] as? String
    let what3wordInfoURL = details?["w3wInfoURL"] as? String
    
    let stop: STKStopAnnotation?
    if let stopJSON = JSON["stop"] as? [String: AnyObject] {
      stop = TKParserHelper.simpleStopFromDictionary(stopJSON)
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
  public class func fetchLocationInformation(coordinate: CLLocationCoordinate2D, forRegion region: SVKRegion, completion: (LocationInformation?) -> Void) {
    let paras: [String: AnyObject] = [
      "lat": coordinate.latitude,
      "lng": coordinate.longitude
    ]
    
    SVKServer.sharedInstance().hitSkedGoWithMethod(
      "GET",
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

