//
//  TKBuzzInfoProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Fetcher methods

public enum TKBuzzInfoProvider {
  
  public static func downloadContent(of service: Service, embarkationDate: Date, region: TKRegion?, completion: @escaping (Service, Bool) -> Void) {
    assert(service.managedObjectContext?.parent != nil || Thread.isMainThread)
    guard !service.isRequestingServiceData else { return }
    
    service.isRequestingServiceData = true
    TKRegionManager.shared.requireRegions { result in
      if case .failure = result {
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
      
      TKServer.shared.hit(
        TKAPI.ServiceResponse.self,
        path: "service.json",
        parameters: paras,
        region: region
      ) { _, _, result in
        service.isRequestingServiceData = false
        let response = try? result.get()
        let success = response.map { Self.addContent(from: $0, to: service) }
        completion(service, success ?? false)
      }
    }
  }
  
  @discardableResult
  public static func addContent(from response: TKAPI.ServiceResponse, to service: Service) -> Bool {
    guard
      let context = service.managedObjectContext,
      response.error == nil,
      let shapes = response.shapes
    else {
      return false
    }
    assert(context.parent != nil || Thread.isMainThread)

    if let realTime = response.realTimeStatus {
      service.adjustRealTimeStatus(for: realTime)
    }
    
    service.addVehicles(primary: response.primaryVehicle, alternatives: response.alternativeVehicles)
    
    TKAPIToCoreDataConverter.updateOrAddAlerts(response.alerts, in: context)
    
    Shape.insertNewShapes(
      from: shapes,
      for: service,
      modeInfo: response.modeInfo,
      clearRealTime: false // these are timetable times, so don't clear real-time
    )
    
    return true
  }
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchRegionInformation(forRegion region: TKRegion) async -> TKAPI.RegionInfo?
  {
    try? await TKServer.shared.hit(
      RegionInfoResponse.self,
      .POST,
      path: "regionInfo.json",
      parameters: ["region": region.name],
      region: region
    ).result.get().regions.first
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchParatransitInformation(forRegion region: TKRegion) async -> TKAPI.Paratransit?
  {
    await fetchRegionInformation(forRegion: region)?.paratransit
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchPublicTransportModes(forRegion region: TKRegion) async -> [TKModeInfo]?
  {
    await fetchRegionInformation(forRegion: region)?.transitModes
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
    
    TKServer.shared.hit(TKAPI.LocationInfo.self,
                        path: "locationInfo.json",
                        parameters: paras,
                        region: region
    ) { _, _, result in
      completion(try? result.get())
    }
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

    TKServer.shared.hit(AlertsTransitResponse.self,
                        path: "alerts/transit.json",
                        parameters: paras,
                        region: region
    ) { _, _, result in
      let mappings = (try? result.get().alerts) ?? []
      completion(mappings.map(\.alert))
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
