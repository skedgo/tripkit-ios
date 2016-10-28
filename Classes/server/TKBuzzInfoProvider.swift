//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import Marshal
import RxSwift


// MARK: - Fetcher methods -

extension TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: SVKRegion, completion: @escaping (RegionInformation?) -> Void)
  {
    SVKServer.fetchArray(RegionInformation.self,
                         method: .POST, path: "regionInfo.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "regions")
    { regions in
      completion(regions.first)
    }
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: @escaping (ParatransitInformation?) -> Void)
  {
    SVKServer.fetchArray(RegionInformation.self,
                         method: .POST, path: "regionInfo.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "regions")
    { regions in
      completion(regions.first?.paratransitInformation)
    }
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: @escaping ([ModeInfo]) -> Void)
  {
    SVKServer.fetchArray(RegionInformation.self,
                         method: .POST, path: "regionInfo.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "regions")
    { regions in
      completion(regions.first?.transitModes ?? [])
    }
  }
  
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, forRegion region: SVKRegion, completion: @escaping (LocationInformation?) -> Void) {
    
    let paras: [String: Any] = [
      "lat": coordinate.latitude,
      "lng": coordinate.longitude
    ]
    
    SVKServer.fetch(LocationInformation.self,
                    path: "locationInfo.json",
                    parameters: paras,
                    region: region,
                    completion: completion)
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchTransitAlerts(forRegion region: SVKRegion, completion: @escaping ([TransitAlertInformation]) -> Void) {
    
    SVKServer.fetchArray(TransitAlertInformation.self,
                         path: "alerts/transit.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "alerts",
                         completion: completion)
  }
  
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
        if let json = response as? [String: Any] {
          let alerts: [TransitAlertInformation]? = try? json.value(for: "alerts")
          return alerts ?? []
        } else {
          return []
        }
    }
  }
}


// MARK: - Helper Extensions -

extension SVKServer {
  
  fileprivate class func fetch<E: Unmarshaling>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: SVKRegion,
    keyPath: String? = nil,
    completion: @escaping (E?) -> Void
  )
  {
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      success: { _, response in
        guard let json = response as? [String: Any] else {
          preconditionFailure() // FIXME
        }
        do {
          let result: E
          if let keyPath = keyPath {
            result = try json.value(for: keyPath)
          } else {
            result = try E(object: json)
          }
          completion(result)
        } catch {
          SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
          completion(nil)
        }
    },
      failure: { error in
        SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
        completion(nil)
    })
  }
  
  fileprivate class func fetchArray<E: Unmarshaling>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: SVKRegion,
    keyPath: String? = nil,
    completion: @escaping ([E]) -> Void
    )
  {
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      success: { _, response in
        guard let json = response as? [String: Any] else {
          preconditionFailure() // FIXME
        }
        do {
          let result: [E]
          if let keyPath = keyPath {
            result = try json.value(for: keyPath)
          } else {
            result = try Array<E>.value(from: json)
          }
          completion(result)
        } catch {
          SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
          completion([])
        }
    },
      failure: { error in
        SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
        completion([])
    })
  }
  
}
