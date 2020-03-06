//
//  InMemoryFavoriteManager.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 3/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit
import TripKitUI

class InMemoryFavoriteManager {
  
  struct Favorite {
    let annotation: MKAnnotation
  }
  
  static let shared = InMemoryFavoriteManager()
  
  var favorites: [Favorite] = []
  
  func hasFavorite(for annotation: MKAnnotation) -> Bool {
    return favorite(for: annotation) != nil
  }
  
  func toggleFavorite(for annotation: MKAnnotation) {
    if let favorite = favorite(for: annotation) {
      remove(favorite)
    } else {
      add(annotation)
    }
  }
  
  private func add(_ annotation: MKAnnotation) {
    guard !hasFavorite(for: annotation) else {
      print("The favorite already exists, skipping")
      return
    }
    
    print("Adding a favorite")
    favorites.append(Favorite(annotation: annotation))
  }
  
  private func remove(_ favorite: Favorite) {
    guard let index = favorites.firstIndex(of: favorite) else {
      print("Trying to remove a non-existent favorite")
      return
    }
    
    print("Removing a favorite: \(favorite)")
    favorites.remove(at: index)
  }
  
  private func favorite(for annotation: MKAnnotation) -> Favorite? {
    if let aStop = annotation as? TKUIStopAnnotation {
      return favorites.first { ($0.annotation as? TKUIStopAnnotation)?.stopCode == aStop.stopCode }
    } else {
      return nil
    }
  }
  
}

extension InMemoryFavoriteManager.Favorite: Equatable {
  
  static func == (lhs: InMemoryFavoriteManager.Favorite, rhs: InMemoryFavoriteManager.Favorite) -> Bool {
    return lhs.annotation.coordinate.latitude == rhs.annotation.coordinate.latitude && lhs.annotation.coordinate.longitude == rhs.annotation.coordinate.longitude
  }
  
}
