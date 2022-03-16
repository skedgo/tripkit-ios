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

  public static func downloadContent(of service: Service, embarkationDate: Date) async throws -> (Service, Bool)? {
    let region = await service.access { service.region }
    guard let region = region else {
      return (service, false)
    }
    return try await downloadContent(of: service, embarkationDate: embarkationDate, region: region)
  }
  
  public static func downloadContent(of service: Service, embarkationDate: Date, region: TKRegion) async throws -> (Service, Bool)? {
    guard !service.isRequestingServiceData else { return nil }
    
    service.isRequestingServiceData = true
    defer {
      service.isRequestingServiceData = false
    }

    do {
      try await TKRegionManager.shared.requireRegions()
      let paras = await service.access {
        [
          "region": region.name,
          "serviceTripID": service.code,
          "operator": service.operatorName ?? "",
          "embarkationDate": embarkationDate.timeIntervalSince1970,
          "encode": true
        ]
      }
      let response = try await TKServer.shared.hit(
        TKAPI.ServiceResponse.self,
        path: "service.json",
        parameters: paras,
        region: region
      ).result.get()
      let success = Self.addContent(from: response, to: service)
      return (service, success)

    } catch {
      return (service, false)
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
   */
  public static func fetchLocationInformation(_ annotation: MKAnnotation, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    
    let paras: [String: Any]
    if let named = annotation as? TKNamedCoordinate, let identifier = named.locationID {
      paras = [ "identifier": identifier, "region": region.name ]
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
  
  /**
   Asynchronously fetches additional location information for a location of specified ID
   */
  public static func fetchLocationInformation(locationID: String, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    
    return try await TKServer.shared.hit(
      TKAPI.LocationInfo.self,
      path: "locationInfo.json",
      parameters: [
        "identifier": locationID,
        "region": region.name
      ],
      region: region
    ).result.get()
  }
  
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, for region: TKRegion) async throws -> TKAPI.LocationInfo {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    return try await fetchLocationInformation(annotation, for: region)
  }
  
  // MARK: - Transit alerts
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public static func fetchTransitAlerts(forRegion region: TKRegion) async throws -> [TKAPI.AlertMapping] {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.parserJsonVersion
    ]

    return try await TKServer.shared.hit(
      AlertsTransitResponse.self,
      path: "alerts/transit.json",
      parameters: paras,
      region: region
    ).result.get().alerts
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
