//
//  TKDeparturesProvider+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

import RxSwift

import TripKit

// MARK: - Departures.json for stops

extension TKDeparturesProvider {

  public class func fetchDepartures(forStopCodes stopCodes: [String], fromDate: Date, filters: [Filter] = [], limit: Int = 10, in region: TKRegion) -> Single<TKAPI.Departures> {
    return Single.create {
      try await Self.fetchDepartures(stopCodes: stopCodes, fromDate: fromDate, filters: filters, limit: limit, in: region)
    }
  }
    
  public class func downloadDepartures(for stops: [StopLocation], fromDate: Date, filters: [Filter] = [], limit: Int = 10) -> Single<Bool> {
    return Single.create {
      try await Self.downloadDepartures(for: stops, fromDate: fromDate, filters: filters, limit: limit)
    }
  }
  
  public class func streamDepartures(forStopCodes stopCodes: [String], limit: Int = 10, in region: TKRegion, repeatHandler: ((Int?, TKAPI.Departures) -> TimeInterval?)? = nil) -> Observable<TKAPI.Departures> {
    
    guard !stopCodes.isEmpty else {
      return Observable.error(InputError.missingField("stopCodes"))
    }
    
    var paras: [String: Any] = [
      "region": region.code,
      "embarkationStops": stopCodes,
      "limit": limit,
      "config": TKSettings.Config.userSettings().paras
    ]
    
    return TKServer.shared.rx
      .stream(TKAPI.Departures.self, .POST, path: "departures.json", parameters: paras, region: region) { status, model in
        
        if case 400..<500 = status ?? 0 {
          return nil // Client-side errors; hitting again won't help
        }

        guard
          let repeatHandler = repeatHandler,
          let model = model,
          let timeInterval = repeatHandler(status, model)
          else { return nil }

        return .repeatIn(timeInterval)
      }
      .map { _, _, model in
        guard let model = model else { throw TKServer.ServerError.noData }
        return model
      }
  }

}

// MARK: - Departures.json for stop-to-stop

extension TKDeparturesProvider {
  
  public class func fetchDepartures(for table: TKDLSTable, fromDate: Date = Date(), limit: Int = 10) -> Single<TKAPI.Departures> {
    return Single.create {
      try await Self.fetchDepartures(for: table, fromDate: fromDate, limit: limit)
    }
  }
  
  public class func downloadDepartures(for table: TKDLSTable, fromDate: Date, limit: Int = 10) -> Single<Set<String>> {
    return Single.create {
      try await Self.downloadDepartures(for: table, fromDate: fromDate, limit: limit)
    }
  }
  
}
