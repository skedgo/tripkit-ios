//
//  TKBuzzInfoProvider+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 30.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension Reactive where Base == TKBuzzInfoProvider {
  
  public static func downloadContent(of service: Service, forEmbarkationDate date: Date, in region: TKRegion) -> Single<Void> {
    return Single.create { subscriber in
      var provider: TKBuzzInfoProvider! = TKBuzzInfoProvider()
      
      provider.downloadContent(of: service, forEmbarkationDate: date, in: region) { service, success in
        if success {
          subscriber(.success(()))
        } else {
          subscriber(.failure(TKError(code: 87612, message: "Could not download service data.")))
        }
      }
      
      return Disposables.create {
        provider = nil
      }
    }
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region using Rx.
   */
  public static func fetchTransitAlerts(forRegion region: TKRegion) -> Single<[TKAPI.Alert]> {
    return fetchTransitAlertMappings(forRegion: region)
      .map { $0.map {$0.alert} }
  }
  
  public static func fetchTransitAlertMappings(forRegion region: TKRegion) -> Single<[TKAPI.AlertMapping]> {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.parserJsonVersion
    ]
    
    return TKServer.shared.rx
      .hit(.GET, path: "alerts/transit.json", parameters: paras, region: region)
      .map { (_, _, data) -> [TKAPI.AlertMapping] in
        guard let data = data else { return [] }
        let decoder = JSONDecoder()
        // This will need adjusting down the track (when using ISO8601)
        decoder.dateDecodingStrategy = .secondsSince1970
        let response = try decoder.decode(TKBuzzInfoProvider.AlertsTransitResponse.self, from: data)
        return response.alerts
      }
  }
  
}
