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
    
    let mainInstruction: String
    let supplementalInfo: String?
    let directionImage: UIImage?
  }
  
}

// MARK: - Building

extension TKUISegmentDirectionsViewModel {
  static func buildSections(for segment: TKSegment) -> Observable<[Section]> {
    let items = (segment.shortedShapes() ?? [])
      .enumerated()
      .map(Item.init(index:shape:))

    return .just([Section(items: items)])
  }
}

extension TKUISegmentDirectionsViewModel.Item {
  fileprivate init(index: Int, shape: Shape) {
    let instruction = "\(shape.title ?? "") - \(shape.metres ?? 0)m"
    self.init(index: index, mainInstruction: instruction, supplementalInfo: nil, directionImage: nil)
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
