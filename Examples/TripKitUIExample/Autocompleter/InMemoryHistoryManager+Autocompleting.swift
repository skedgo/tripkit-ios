//
//  InMemoryHistoryManager+Autocompleting.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 2/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TripKit
import TripKitUI

extension InMemoryHistoryManager: TKAutocompleting {
  func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    let history = input.isEmpty ? fetchDefaultHistory() : fetchHistory(matching: input)
    let results = history.compactMap { InMemoryHistoryManager.autocompletionResult(for: $0, searchText: input)}
    completion(.success(results))
  }
  
  func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    guard let history = result.object as? History else {
      preconditionFailure()
    }
    completion(.success(history.annotation))
  }
  
}

extension InMemoryHistoryManager {
  
  private func fetchDefaultHistory() -> [History] {
    let items = (try? history.value()) ?? []
    if items.count > 5 {
      return items.sorted(by: { $0.date > $1.date} ).prefix(upTo: 5).map { $0 }
    } else {
      return items.sorted(by: { $0.date > $1.date} )
    }
  }
  
  private func fetchHistory(matching searchText: String) -> [History] {
    let items = (try? history.value()) ?? []
    let loweredCasedSearchText = searchText.lowercased()
    return items.filter { $0.annotation.title??.lowercased().contains(loweredCasedSearchText) ?? false }
  }
  
  static func autocompletionResult(for history: History, searchText: String) -> TKAutocompletionResult? {
    guard
      let optionalTitle = history.annotation.title,
      let title = optionalTitle
      else { return nil }
    
    var result = TKAutocompletionResult(
      object: history,
      title: title,
      subtitle: history.annotation.subtitle ?? nil,
      image: TKAutocompletionResult.image(for: .history)
    )
    
    if history.annotation is TKUIStopAnnotation {
      result.accessoryButtonImage = TKStyleManager.image(named: "icon-search-timetable")
      result.accessoryAccessibilityLabel = Loc.ShowTimetable
    }
    
    if searchText.isEmpty {
      result.score = 90
      
    } else {
      let titleScore = TKAutocompletionResult.nameScore(searchTerm: searchText, candidate: result.title).score
      let locationScore = TKAutocompletionResult.nameScore(searchTerm: searchText, candidate: result.subtitle ?? "").score
      let rawScore = min(100, (titleScore + locationScore)/2)
      result.score = Int(TKAutocompletionResult.rangedScore(for: rawScore, min: 50, max: 90))
    }
    
    return result
  }
  
}
