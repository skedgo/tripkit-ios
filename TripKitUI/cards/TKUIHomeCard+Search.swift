//
//  TKUIHomeCard+Search.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// This protocol defines the method you can use to receive message related to
/// the search functionality provided in a `TKUIHomeCard`
public protocol TKUIHomeCardSearchResultsDelegate: AnyObject {
  
  /// This tells the delegate that a search result is selected
  /// - Parameters:
  ///   - card: The `TKUIHomeCard` from which the search took place.
  ///   - searchResult: The search result selected.
  func homeCard(_ card: TKUIHomeCard, selected searchResult: MKAnnotation)
  
}
