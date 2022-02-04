//
//  TKServer+Regions.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKRegionManager {
  
  enum RegionError: Error {
    case invalidDevelopmentServer
  }
  
  /// Fetched the list of regions and updates `TKRegionManager`'s cache
  ///
  /// Recommended to call from the application delegate.
  /// - Parameter forced: Set true to force overwriting the internal cache
  public func updateRegions(forced: Bool = false) {
    fetchRegions(forced: forced, completion: { _ in })
  }
  
  public func requireRegions(completion: @escaping (Result<Void, Error>) -> Void) {
    guard !hasRegions else {
      return completion(.success(()))
    }
    fetchRegions(forced: false, completion: completion)
  }
  
  func fetchRegions(forced: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    let regionsURL: URL
    if let developmentServer = TKServer.developmentServer {
      guard let url = URL(string: developmentServer) else {
        return completion(.failure(RegionError.invalidDevelopmentServer))
      }
      regionsURL = url.appendingPathComponent("regions.json")
    } else {
      regionsURL = URL(string: "https://api.tripgo.com/v1/regions.json")!
    }
    
    var paras: [String: Any] = ["v": 2]
    if !forced {
      paras["hashCode"] = regionsHash
    }
    
    TKServer.shared.hit(TKAPI.RegionsResponse.self, .POST, url: regionsURL, parameters: paras) { [weak self] _, _, result in
      guard let self = self else { return }
      
      switch result {
      case .success(let response):
        self.updateRegions(from: response)
        if self.hasRegions {
          completion(.success(()))
        } else {
          let message = NSLocalizedString("Could not download supported regions from TripGo's server. Please try again later.", tableName: "Shared", bundle: .tripKit, comment: "Could not download supported regions warning.")
          let userError = NSError(code: Int(kTKServerErrorTypeUser), message: message)
          completion(.failure(userError))
        }
        
      case .failure(TKServer.ServerError.noData) where !forced:
        completion(.success(())) // still up-to-date
      case .failure(let error):
        TKLog.warn("TKServer+Regions", text: "Error fetching regions.json: \(error)")
        completion(.failure(error))
      }
    }
  }

  
}
