//
//  TKDeparturesProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

import RxSwift

import TripKit

extension TKDeparturesProvider {
  
  enum InputError: Error {
    case missingField(String)
    case emptyField(String)
  }
  
  enum OutputError: Error {
    case noDataReturn
    case couldNotFetchRegions
    case stopSinceDeleted
  }
  
}

// MARK: - Departures.json for stops

extension TKDeparturesProvider {

  public class func fetchDepartures(forStopCodes stopCodes: [String], fromDate: Date, limit: Int = 10, in region: TKRegion) -> Single<TKAPI.Departures> {
    return streamDepartures(forStopCodes: stopCodes, fromDate: fromDate, limit: limit, in: region, repeatHandler: nil)
      .asSingle()
  }
    
  public class func streamDepartures(forStopCodes stopCodes: [String], limit: Int = 10, in region: TKRegion, repeatHandler: ((Int, TKAPI.Departures) -> TimeInterval?)? = nil) -> Observable<TKAPI.Departures> {
    return streamDepartures(forStopCodes: stopCodes, fromDate: nil, limit: limit, in: region, repeatHandler: repeatHandler)
  }
  
  private class func streamDepartures(forStopCodes stopCodes: [String], fromDate: Date?, limit: Int = 10, in region: TKRegion, repeatHandler: ((Int, TKAPI.Departures) -> TimeInterval?)?) -> Observable<TKAPI.Departures> {
    
    assert(repeatHandler == nil || fromDate == nil, "Don't set both `fromDate` and the `repeatHandler`. It doesn't make sense to repeat, if you fix the departure time.")
    
    guard !stopCodes.isEmpty else {
      return Observable.error(InputError.missingField("stopCodes"))
    }
    
    var paras: [String: Any] = [
      "region": region.name,
      "embarkationStops": stopCodes,
      "limit": limit,
      "config": TKSettings.config
    ]
    if let date = fromDate {
      paras["timeStamp"] = date.timeIntervalSince1970
    }
    
    return TKServer.shared.rx
      .stream(.POST, path: "departures.json", parameters: paras, region: region) { status, data in
        guard fromDate == nil else {
          return nil // No result change, no need to repeat
        }
        
        if case 400..<500 = status {
          return nil // Client-side errors; hitting again won't help
        }

        guard
          let repeatHandler = repeatHandler,
          let data = data,
          let departures = try? JSONDecoder().decode(TKAPI.Departures.self, from: data),
          let timeInterval = repeatHandler(status, departures)
          else { return nil }

        return .repeatIn(timeInterval)
      }
      .map { _, _, data in
        guard let data = data else { throw OutputError.noDataReturn }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(TKAPI.Departures.self, from: data)
    }
  }
  
  public class func downloadDepartures(for stops: [StopLocation], fromDate: Date, limit: Int = 10) -> Single<Bool> {
    
    let stopCodes = stops.map { $0.stopCode }
    
    return TKServer.shared.rx
      .requireRegions()
      .flatMap { Void -> Single<TKAPI.Departures> in
        guard let region = stops.first?.region else {
          throw OutputError.couldNotFetchRegions
        }
        return TKDeparturesProvider.fetchDepartures(forStopCodes: stopCodes, fromDate: fromDate, limit: limit, in: region)
      }
      .map { departures -> Bool in
        guard let context = stops.first?.managedObjectContext else {
          throw OutputError.stopSinceDeleted
        }
        var result = false
        context.performAndWait {
          result = TKDeparturesProvider.addDepartures(departures, to: stops)
        }
        return result
    }
  }
}

// MARK: - Departures.json for stop-to-stop

extension TKDeparturesProvider {
  
  @objc(queryParametersForDLSTable:fromDate:limit:)
  public class func queryParameters(for table: TKDLSTable, fromDate: Date, limit: Int) -> [String: Any] {
    return [
      "region": table.startRegion.name,
      "disembarkationRegion": table.endRegion.name,
      "timeStamp": fromDate.timeIntervalSince1970,
      "embarkationStops": [table.startStopCode],
      "disembarkationStops": [table.endStopCode],
      "limit": limit,
      "config": TKSettings.config
    ]
  }
  
  public class func fetchDepartures(for table: TKDLSTable, fromDate: Date = Date(), limit: Int = 10) -> Single<TKAPI.Departures> {
    
    let paras: [String: Any] = TKDeparturesProvider.queryParameters(for: table, fromDate: fromDate, limit: limit)
    
    return TKServer.shared.rx
      .hit(.POST, path: "departures.json", parameters: paras, region: table.startRegion)
      .map { _, _, data in
        guard let data = data else { throw OutputError.noDataReturn }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(TKAPI.Departures.self, from: data)
    }
  }
  
  public class func downloadDepartures(for table: TKDLSTable, fromDate: Date, limit: Int = 10) -> Single<Set<String>> {
    
    return TKServer.shared.rx
      .requireRegions()
      .flatMap { Void -> Single<TKAPI.Departures> in
        return TKDeparturesProvider.fetchDepartures(for: table, fromDate: fromDate, limit: limit)
      }
      .map { departures -> Set<String> in
        var result = Set<String>()
        let context = table.tripKitContext
        context.performAndWait {
          result = TKDeparturesProvider.addDepartures(departures, into: context)
        }
        return result
    }
  }
  
}
