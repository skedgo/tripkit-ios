//
//  TKBuzzInfoProvider+Routes.swift
//  TripKit
//
//  Created by Adrian Schönig on 27/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKBuzzInfoProvider {
  
  /// Fetches a list of routes in for the provided region, optionally filtered
  ///
  /// - warning: Calling this method without any of the filter parameters can result both in a
  ///   slow, big response due to the large number of routes in certain regions.
  ///
  /// - Parameters:
  ///   - region: The region for which to fetch a list of routes
  ///   - query: Optional search string to filter routes by their short name (complete matches only)
  ///           or by their name (partial matches)
  ///   - modes: If provided, only routes using any of these mode identifiers will be returned, e.g., `pt_pub_bus`
  ///   - operatorID: If provided, only routes for this operator will be returned
  /// - Returns: List of routes
  public static func fetchRoutes(forRegion region: TKRegion, query: String? = nil, modes: [String] = [], operatorID: String? = nil) async throws -> [TKAPI.Route] {
    var paras: [String: Any] = [
      "region": region.name
    ]
    
    paras["query"] = query
    paras["modes"] = modes.isEmpty ? nil : modes
    paras["operatorID"] = operatorID

    return try await TKServer.shared.hit(
      [TKAPI.Route].self,
      .POST,
      path: "info/routes.json",
      parameters: paras,
      region: region
    ).result.get()
  }
  
}
