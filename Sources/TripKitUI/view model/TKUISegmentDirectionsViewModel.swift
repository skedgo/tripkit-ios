//
//  TKUISegmentDirectionsViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

import TripKit

@MainActor
class TKUISegmentDirectionsViewModel: ObservableObject {
  
  static func canShowInstructions(for segment: TKSegment) -> Bool {
    guard segment.isSelfNavigating else { return false }
    return !segment.shapes.isEmpty
  }
  
  struct Item: Identifiable {
    var id: Int { index }
    
    let index: Int
    
    let streetName: String?
    let image: UIImage?
    var distance: CLLocationDistance?
    let bubbles: [(String, UIColor)]
    
    /// Localised textual instruction for following this street for the
    /// relevant distance (i.e., using current street name).
    var streetInstruction: String { return Loc.AlongStreet(named: streetName) }
  }
  
  init(segment: TKSegment) {
    self.segment = segment
    self.items = TKUISegmentDirectionsViewModel.buildItems(for: segment)
  }
  
  let segment: TKSegment
  let items: [Item]
}

// MARK: - Building

extension TKUISegmentDirectionsViewModel {
  static func buildItems(for segment: TKSegment) -> [Item] {
    return segment.shapes
      .enumerated()
      .map(Item.init(index:shape:))
      .reduce(into: [Item]()) { $0.smartAppend($1) }
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
      distance: shape.metres?.doubleValue,
      bubbles: shape.roadTags?.map { ($0.localized, $0.safety.color) } ?? []
    )
  }
  
  mutating func append(_ other: TKUISegmentDirectionsViewModel.Item) -> Bool {
    // LATER: This will need fixing when we add other things, such as turn
    //        indicator or friendliness
    
    guard
      other.streetName == streetName,
      Set(other.bubbles.map(\.0)) == Set(bubbles.map(\.0))
    else { return false }
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

extension Shape.Instruction {
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
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return nil
    }
    
    let image = TripKitUIBundle.imageNamed("maneuver-\(part)")
    if flip, let original = image.cgImage {
      return UIImage(cgImage: original, scale: image.scale, orientation: .upMirrored).withRenderingMode(.alwaysTemplate)
    } else {
      return image
    }
  }
}
  
extension TKUISegmentDirectionsViewModel.Item: Equatable {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.index == rhs.index
      && lhs.streetName == rhs.streetName
      && lhs.image == rhs.image
      && lhs.distance == rhs.distance
      && lhs.bubbles.count == rhs.bubbles.count
  }
}
