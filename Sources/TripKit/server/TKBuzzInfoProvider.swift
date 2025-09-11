//
//  TKBuzzInfoProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(MapKit)
import CoreLocation
import MapKit
#endif

// MARK: - Fetcher methods

public enum TKBuzzInfoProvider {
  
  @discardableResult
  public static func downloadContent(of service: Service, embarkationDate: Date, region: TKRegion?) async throws -> Bool {
    assert(service.managedObjectContext?.parent != nil || Thread.isMainThread)
    guard !service.isRequestingServiceData else { return false }
    
    service.isRequestingServiceData = true
    defer { service.isRequestingServiceData = false }
    
    try await TKRegionManager.shared.requireRegions()
      
    guard let region = region ?? service.region else {
      return false
    }
      
    let paras: [String: Any] = [
      "region": region.code,
      "serviceTripID": service.code,
      "operator": service.operatorName ?? "",
      "embarkationDate": Int(embarkationDate.timeIntervalSince1970),
      "encode": true
    ]

    let response = await TKServer.shared.hit(TKAPI.ServiceResponse.self, path: "service.json", parameters: paras, region: region)
    let serviceData = try response.result.get()
    return addContent(from: serviceData, to: service)
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
   */
  public static func fetchRegionInformation(for region: TKRegion) async -> TKAPI.RegionInfo? {
    try? await TKServer.shared.hit(
      RegionInfoResponse.self,
      .POST,
      path: "regionInfo.json",
      parameters: ["region": region.code],
      region: region
    ).result.get().regions.first
  }
  
  @available(*, deprecated, renamed: "fetchRegionInformation(for:)")
  public static func fetchRegionInformation(forRegion region: TKRegion) async -> TKAPI.RegionInfo? {
    await fetchRegionInformation(for: region)
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   */
  public static func fetchParatransitInformation(for region: TKRegion) async -> TKAPI.Paratransit? {
    await fetchRegionInformation(for: region)?.paratransit
  }

  @available(*, deprecated, renamed: "fetchParatransitInformation(for:)")
  public static func fetchParatransitInformation(forRegion region: TKRegion) async -> TKAPI.Paratransit? {
    await fetchParatransitInformation(for: region)
  }

  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   */
  public static func fetchPublicTransportModes(for region: TKRegion) async -> [TKModeInfo]? {
    await fetchRegionInformation(for: region)?.transitModes
  }
  
  @available(*, deprecated, renamed: "fetchPublicTransportModes(for:)")
  public static func fetchPublicTransportModes(forRegion region: TKRegion) async throws -> [TKModeInfo]? {
    await fetchPublicTransportModes(for: region)
  }

#if canImport(MapKit)
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   */
  public static func fetchLocationInformation(_ annotation: MKAnnotation, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    
    let paras: [String: Any]
    if let named = annotation as? TKNamedCoordinate, let identifier = named.locationID {
      paras = [ "identifier": identifier, "region": region.code ]
    } else {
      paras = [ "lat": annotation.coordinate.latitude, "lng": annotation.coordinate.longitude ]
    }
    return try await TKServer.shared.hit(
      TKAPI.LocationInfo.self,
      path: "locationInfo.json",
      parameters: paras,
      region: region
    ).result.get()
  }
#endif
  
  /**
   Asynchronously fetches additional location information for a location of specified ID
   */
  public static func fetchLocationInformation(locationID: String, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    
    return try await TKServer.shared.hit(
      TKAPI.LocationInfo.self,
      path: "locationInfo.json",
      parameters: [
        "identifier": locationID,
        "region": region.code
      ],
      region: region
    ).result.get()
  }
  
#if canImport(MapKit)
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   */
  public static func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    return try await fetchLocationInformation(annotation, for: region)
  }
#endif
  
  // MARK: - Transit alerts
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   */
  public static func fetchTransitAlerts(for region: TKRegion) async throws -> [TKAPI.AlertMapping] {
    let paras: [String: Any] = [
      "region": region.code,
      "v": TKAPIConfig.parserJsonVersion
    ]

    return try await TKServer.shared.hit(
      AlertsTransitResponse.self,
      path: "alerts/transit.json",
      parameters: paras,
      region: region
    ).result.get().alerts
  }
  
  @available(*, deprecated, renamed: "fetchTransitAlerts(for:)")
  public static func fetchTransitAlerts(forRegion region: TKRegion) async throws -> [TKAPI.AlertMapping] {
    try await fetchTransitAlerts(for: region)
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
