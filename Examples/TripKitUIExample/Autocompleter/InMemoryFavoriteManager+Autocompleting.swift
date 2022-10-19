//
//  InMemoryFavoriteManager+Autocompleting.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 3/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TripKit
import TripKitUI

extension InMemoryFavoriteManager: TKAutocompleting {
  func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    let favorites = input.isEmpty ? fetchDefaultFavorites() : fetchFavorite(matching: input)
    let results = favorites.compactMap { InMemoryFavoriteManager.autocompletionResult(for: $0, searchText: input) }
    completion(.success(results))
  }
  
  func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    guard let favorite = result.object as? Favorite else {
      preconditionFailure()
    }
    completion(.success(favorite.annotation))
  }
  
}

extension InMemoryFavoriteManager {
  
  private func fetchDefaultFavorites() -> [Favorite] {
    return favorites
  }
  
  private func fetchFavorite(matching searchText: String) -> [Favorite] {
    let lowercasedSearchText = searchText.lowercased()
    return favorites.filter { $0.annotation.title??.lowercased().contains(lowercasedSearchText) ?? false }
  }
  
  static func autocompletionResult(for favorite: Favorite, searchText: String) -> TKAutocompletionResult? {
    guard
      let optionalTitle = favorite.annotation.title,
      let title = optionalTitle
      else { return nil }
    
    var result = TKAutocompletionResult(
      object: (favorite as? AnyHashable) ?? favorite.annotation.description as AnyHashable,
      title: title,
      subtitle: favorite.annotation.subtitle ?? nil,
      image: TKAutocompletionResult.image(for: .favorite)
    )
    
    if favorite.annotation is TKUIStopAnnotation {
      result.accessoryButtonImage = TKStyleManager.image(named: "icon-search-timetable")
      result.accessoryAccessibilityLabel = Loc.ShowTimetable
    }
    
    if searchText.isEmpty {
      result.score = 90
      
    } else {
      let titleScore = TKAutocompletionResult.nameScore(searchTerm: searchText, candidate: result.title)
      let locationScore = TKAutocompletionResult.nameScore(searchTerm: searchText, candidate: result.subtitle ?? "")
      let rawScore = min(100, (titleScore + locationScore)/2)
      result.score = Int(TKAutocompletionResult.rangedScore(for: rawScore, min: 50, max: 90))
    }
    
    return result
  }
  
}
