//
//  TKBuzzInfoProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

// MARK: - Fetcher methods

extension TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: SVKRegion, completion: @escaping (API.RegionInfo?) -> Void)
  {
    SVKServer.shared.fetch(RegionInfoResponse.self,
                           method: .POST, path: "regionInfo.json",
                           parameters: ["region": region.name],
                           region: region)
    { result in
      completion(result?.regions.first)
    }
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: @escaping (API.Paratransit?) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      completion(info?.paratransit)
    }
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  @objc
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: @escaping ([ModeInfo]) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      completion(info?.transitModes ?? [])
    }
  }
  

  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchLocationInformation(_ annotation: MKAnnotation, for region: SVKRegion, completion: @escaping (API.LocationInfo?) -> Void) {
    
    let paras: [String: Any]
    if let named = annotation as? SGKNamedCoordinate, let identifier = named.locationID {
      paras = [ "identifier": identifier, "region": region.name ]
    } else {
      paras = [ "lat": annotation.coordinate.latitude, "lng": annotation.coordinate.longitude ]
    }
    
    SVKServer.shared.fetch(API.LocationInfo.self,
                           path: "locationInfo.json",
                           parameters: paras,
                           region: region,
                           completion: completion)
  }
  
  // MARK: - Transit alerts
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchTransitAlerts(forRegion region: SVKRegion, completion: @escaping ([API.Alert]) -> Void) {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.defaultDictionary()["v"] as! Int
    ]

    SVKServer.shared.fetch(AlertsTransitResponse.self,
                           path: "alerts/transit.json",
                           parameters: paras,
                           region: region)
    { response in
      let mappings = response?.alerts ?? []
      completion(mappings.map { $0.alert })
    }
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region using Rx.
   */
  public class func rx_fetchTransitAlerts(forRegion region: SVKRegion) -> Observable<[API.Alert]> {
    return rx_fetchTransitAlertMappings(forRegion: region)
      .map { $0.map {$0.alert} }
  }
  
  public class func rx_fetchTransitAlertMappings(forRegion region: SVKRegion) -> Observable<[API.AlertMapping]> {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.defaultDictionary()["v"] as! Int
    ]
    
    return SVKServer.shared.rx
      .hit(.GET, path: "alerts/transit.json", parameters: paras, region: region)
      .map { (_, _, data) -> [API.AlertMapping] in
        let decoder = JSONDecoder()
        // This will need adjusting down the track (when using ISO8601)
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let data = data else { return [] }
        let response = try decoder.decode(AlertsTransitResponse.self, from: data)
        return response.alerts
      }
  }
  
  // MARK: - Accessibility
  
  /**
   Asynchronously fetches information about whether the provided region supports
   wheelchair.
   
   - Note: Completion block is executed on the main thread.
   */
  @objc
  public class func fetchWheelchairSupportInformation(forRegion region: SVKRegion, completiton: @escaping (Bool) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      let isSupoorted = info?.transitWheelchairAccessibility ?? info?.streetWheelchairAccessibility ?? false
      completiton(isSupoorted)
    }
  }
  
}

// MARK: - Response data model

extension TKBuzzInfoProvider {
  
  struct RegionInfoResponse: Codable {
    let regions: [API.RegionInfo]
    let server: String?
  }
  
  struct AlertsTransitResponse: Codable {
    let alerts: [API.AlertMapping]
  }
  
}


// MARK: - Codable helper Extensions

extension SVKServer {
  
  fileprivate func fetch<E: Decodable>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: SVKRegion,
    completion: @escaping (E?) -> Void
    )
  {
    hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      success: { _, _, data in
        guard let data = data else {
          SGKLog.debug("TKBuzzInfoProvider") { "Empty response when fetching \(path), paras: \(parameters ?? [:])" }
          completion(nil)
          return
        }

        do {
          let decoder = JSONDecoder()
          // This will need adjusting down the track (when using ISO8601)
          let result = try decoder.decode(type, from: data)
          completion(result)
        } catch {
          SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])" }
          completion(nil)
        }
    },
      failure: { error in
        SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])" }
        completion(nil)
    })
  }
  
}
