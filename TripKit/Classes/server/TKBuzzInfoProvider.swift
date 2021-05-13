//
//  TKBuzzInfoProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - Fetcher methods

public enum TKBuzzInfoProvider {
  
  public static func downloadContent(of service: Service, embarkationDate: Date, region: TKRegion?, completion: @escaping (Service, Bool) -> Void) {
    assert(service.managedObjectContext?.parent != nil || Thread.isMainThread)
    guard !service.isRequestingServiceData else { return }
    
    service.isRequestingServiceData = true
    TKServer.shared.requireRegions { error in
      if let error = error {
        TKLog.warn("Error fetching regions: \(error)")
        service.isRequestingServiceData = false
        completion(service, false)
        return
      }
      
      guard let region = region ?? service.region else {
        service.isRequestingServiceData = false
        completion(service, false)
        return
      }
      
      let paras: [String: Any] = [
        "region": region.name,
        "serviceTripID": service.code,
        "operator": service.operatorName ?? "",
        "embarkationDate": embarkationDate.timeIntervalSince1970,
        "encode": true
      ]
      
      TKServer.shared.hitSkedGo(
        withMethod: "GET",
        path: "service.json",
        parameters: paras,
        region: region,
        callbackOnMain: false) { _, response, _ in
        service.managedObjectContext?.perform {
          service.isRequestingServiceData = false
          let success = Self.addContent(from: response as? [String: Any] ?? [:], to: service)
          completion(service, success)
        }
        
      } failure: { error in
        TKLog.info("Error response: \(error)")
        service.managedObjectContext?.perform {
          service.isRequestingServiceData = false
          completion(service, false)
        }
      }
    }
  }
  
  @discardableResult
  public static func addContent(from response: [String: Any], to service: Service) -> Bool {
    guard
      let context = service.managedObjectContext,
      response["error"] == nil,
      let shapes = response["shapes"] as? [[String: Any]]
    else {
      return false
    }
    assert(context.parent != nil || Thread.isMainThread)

    if let realTime = response["realTimeStatus"] as? String {
      TKCoreDataParserHelper.adjust(service, forRealTimeStatusString: realTime)
    }
    
    TKAPIToCoreDataConverter.updateVehicles(
      for: service,
      primaryVehicle: response["realtimeVehicle"] as? [String: Any],
      alternativeVehicles: response["realtimeVehicleAlternatives"] as? [[String: Any]]
    )
    
    TKAPIToCoreDataConverter.updateOrAddAlerts(
      from: response["alerts"] as? [[String: Any]],
      in: context
    )
    
    let modeInfo = TKModeInfo.modeInfo(for: response["modeInfo"] as? [String: Any])
    TKCoreDataParserHelper.insertNewShapes(
      shapes,
      for: service,
      with: modeInfo,
      clearRealTime: true // these are timetable times
    )
    
    return true
  }
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchRegionInformation(forRegion region: TKRegion, completion: @escaping (TKAPI.RegionInfo?) -> Void)
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
  public static func fetchParatransitInformation(forRegion region: TKRegion, completion: @escaping (TKAPI.Paratransit?) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      completion(info?.paratransit)
    }
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchPublicTransportModes(forRegion region: TKRegion, completion: @escaping ([TKModeInfo]) -> Void)
  {
    fetchRegionInformation(forRegion: region) { info in
      completion(info?.transitModes ?? [])
    }
  }
  

  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchLocationInformation(_ annotation: MKAnnotation, for region: TKRegion, completion: @escaping (TKAPI.LocationInfo?) -> Void) {
    
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
  public static func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, for region: TKRegion, completion: @escaping (TKAPI.LocationInfo?) -> Void) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    fetchLocationInformation(annotation, for: region, completion: completion)
  }
  
  // MARK: - Transit alerts
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchTransitAlerts(forRegion region: TKRegion, completion: @escaping ([TKAPI.Alert]) -> Void) {
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
  
  public static func fetchWheelchairSupportInformation(forRegion region: TKRegion, completiton: @escaping (Bool) -> Void)
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
          TKLog.debug("Empty response when fetching \(path), paras: \(parameters ?? [:])")
          completion(nil)
          return
        }

        do {
          let decoder = JSONDecoder()
          // This will need adjusting down the track (when using ISO8601)
          let result = try decoder.decode(type, from: data)
          completion(result)
        } catch {
          TKLog.debug("Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])")
          completion(nil)
        }
    },
      failure: { error in
        TKLog.debug("Encountered \(error), when fetching \(path), paras: \(parameters ?? [:])")
        completion(nil)
    })
  }
  
}
