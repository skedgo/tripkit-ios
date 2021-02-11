//
//  TKBuzzInfoProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - Fetcher methods

extension TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: TKRegion, completion: @escaping (TKAPI.RegionInfo?) -> Void)
  {
    TKServer.shared.fetch(RegionInfoResponse.self,
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
  public class func fetchParatransitInformation(forRegion region: TKRegion, completion: @escaping (TKAPI.Paratransit?) -> Void)
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
  public class func fetchPublicTransportModes(forRegion region: TKRegion, completion: @escaping ([TKModeInfo]) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      completion(info?.transitModes ?? [])
    }
  }
  

  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchLocationInformation(_ annotation: MKAnnotation, for region: TKRegion, completion: @escaping (TKAPI.LocationInfo?) -> Void) {
    
    let paras: [String: Any]
    if let named = annotation as? TKNamedCoordinate, let identifier = named.locationID {
      paras = [ "identifier": identifier, "region": region.name ]
    } else {
      paras = [ "lat": annotation.coordinate.latitude, "lng": annotation.coordinate.longitude ]
    }
    
    TKServer.shared.fetch(TKAPI.LocationInfo.self,
                           path: "locationInfo.json",
                           parameters: paras,
                           region: region,
                           completion: completion)
  }
  
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, for region: TKRegion, completion: @escaping (TKAPI.LocationInfo?) -> Void) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    fetchLocationInformation(annotation, for: region, completion: completion)
  }
  
  // MARK: - Transit alerts
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchTransitAlerts(forRegion region: TKRegion, completion: @escaping ([TKAPI.Alert]) -> Void) {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.parserJsonVersion
    ]

    TKServer.shared.fetch(AlertsTransitResponse.self,
                           path: "alerts/transit.json",
                           parameters: paras,
                           region: region)
    { response in
      let mappings = response?.alerts ?? []
      completion(mappings.map { $0.alert })
    }
  }
  
  // MARK: - Accessibility
  
  /**
   Asynchronously fetches information about whether the provided region supports
   wheelchair.
   
   - Note: Completion block is executed on the main thread.
   */
  @objc
  public class func fetchWheelchairSupportInformation(forRegion region: TKRegion, completiton: @escaping (Bool) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      let isSupported: Bool
      if let info = info {
        isSupported = info.transitWheelchairAccessibility || info.streetWheelchairAccessibility
      } else {
        isSupported = false
      }
      completiton(isSupported)
    }
  }
  
}

// MARK: - Response data model

extension TKBuzzInfoProvider {
  
  struct RegionInfoResponse: Codable {
    let regions: [TKAPI.RegionInfo]
    let server: String?
  }
  
  public struct AlertsTransitResponse: Codable {
    public let alerts: [TKAPI.AlertMapping]
  }
  
}

// MARK: - Codable helper Extensions

extension TKServer {
  
  fileprivate func fetch<E: Decodable>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: TKRegion,
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
          TKLog.debug("TKBuzzInfoProvider", text: "Empty response when fetching \(path), paras: \(parameters ?? [:])")
          completion(nil)
          return
        }

        do {
          let decoder = JSONDecoder()
          // This will need adjusting down the track (when using ISO8601)
          let result = try decoder.decode(type, from: data)
          completion(result)
        } catch {
          TKLog.debug("TKBuzzInfoProvider", text: "Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])")
          completion(nil)
        }
    },
      failure: { error in
        TKLog.debug("TKBuzzInfoProvider", text: "Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])")
        completion(nil)
    })
  }
  
}
