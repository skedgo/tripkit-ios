//
//  InMemoryFavoriteManager+Autocompleting.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 3/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

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
    
    let result = TKAutocompletionResult()
    result.object = favorite
    result.title = title
    result.subtitle = favorite.annotation.subtitle ?? nil
    result.image = TKAutocompletionResult.image(forType: .favourite)
    
    if favorite.annotation is TKUIStopAnnotation {
      result.accessoryButtonImage = TKStyleManager.imageNamed("icon-search-timetable")
    }
    
    if searchText.isEmpty {
      result.score = 90
      
    } else {
      let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchText, candidate: result.title)
      let locationScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchText, candidate: result.subtitle ?? "")
      let rawScore = min(100, (titleScore + locationScore)/2)
      result.score = Int(TKAutocompletionResult.rangedScore(forScore: UInt(rawScore), betweenMinimum: 50, andMaximum: 90))
    }
    
    return result
  }
  
}
