//
//  TKUISegmentDirectionsViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension TKUISegmentDirectionsViewModel {
  
  struct Section {
    var items: [Item]
  }
  
  struct Item: Equatable {
    fileprivate let index: Int
    
    let streetName: String?
    let image: UIImage?
    var distance: CLLocationDistance?
    
    /// Localised textual instruction for following this street for the
    /// relevant distance (i.e., using current street name).
    var streetInstruction: String { return Loc.AlongStreet(named: streetName) }
  }
  
}

// MARK: - Building

extension TKUISegmentDirectionsViewModel {
  static func buildSections(for segment: TKSegment) -> Observable<[Section]> {
    let items = segment.shapes
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
      image: shape.instruction?.image,
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

fileprivate extension Shape.Instruction {
  var image: UIImage? {
    let part: String
    var flip = false

    switch self {
    case .headTowards:        part = "start"
    case .continueStraight:   part = "go-straight"
    case .turnLeft:           flip = true; fallthrough
    case .turnRight:          part = "quite-right"
    case .turnSlightyLeft:    flip = true; fallthrough
    case .turnSlightlyRight:  part = "light-right"
    case .turnSharplyLeft:    flip = true; fallthrough
    case .turnSharplyRight:   part = "heavy-right"
    }
    
    let image = TripKitUIBundle.imageNamed("maneuver-\(part)")
    if flip, let original = image.cgImage {
      return UIImage(cgImage: original, scale: image.scale, orientation: .upMirrored).withRenderingMode(.alwaysTemplate)
    } else {
      return image
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
