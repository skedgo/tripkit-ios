//
//  TKUISegmentDirectionsViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxDataSources

extension TKUISegmentDirectionsViewModel {
  
  struct Section {
    var items: [Item]
  }
  
  struct Item: Equatable {
    fileprivate let index: Int
    
    let streetName: String?
    var distance: CLLocationDistance?
    
    /// Localised textual instruction for following this street for the
    /// relevant distance (i.e., using current street name).
    var streetInstruction: String {
      if let name = streetName {
        return "Along \(name)" // TODO :Localize
      } else {
        return "Along unnamed street" // TODO: Localize
      }
    }
  }
  
}

// MARK: - Building

extension TKUISegmentDirectionsViewModel {
  static func buildSections(for segment: TKSegment) -> Observable<[Section]> {
    let items = (segment.shortedShapes() ?? [])
      .enumerated()
      .map(Item.init(index:shape:))
      .reduce(into: [Item]()) { $0.smartAppend($1) }

    return .just([Section(items: items)])
  }
}

fileprivate extension TKUISegmentDirectionsViewModel.Item {
  init(index: Int, shape: Shape) {
    let streetName: String?
    if let name = shape.title, !name.isEmpty {
      streetName = name
    } else {
      streetName = nil
    }
    
    self.init(
      index: index,
      streetName: streetName,
      distance: shape.metres?.doubleValue
    )
  }
  
  mutating func append(_ other: TKUISegmentDirectionsViewModel.Item) -> Bool {
    // LATER: This will need fixing when we add other things, such as turn
    //        indicator or friendliness
    
    guard other.streetName == streetName else { return false }
    if let old = distance, let new = other.distance {
      distance = old + new
    } else {
      distance = self.distance ?? other.distance
    }
    return true
  }
}

fileprivate extension Array where Element == TKUISegmentDirectionsViewModel.Item {
  mutating func smartAppend(_ other: Element) {
    if var last = self.last, last.append(other) {
      removeLast()
      append(last)
    } else {
      append(other)
    }
  }
}
  
// MARK: - RxDataSource protocol conformance

extension TKUISegmentDirectionsViewModel.Item: IdentifiableType {
  typealias Identity = Int
  var identity: Identity {
    return index
  }
}

extension TKUISegmentDirectionsViewModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUISegmentDirectionsViewModel.Item
  
  init(original: TKUISegmentDirectionsViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity {
    return "single-section"
  }
}
