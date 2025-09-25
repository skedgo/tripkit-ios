//
//  TKUIServiceViewModel.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit
import Combine

import RxSwift
import RxCocoa

import TripKit

/// View model for displaying and interacting with an individual
/// transport service.
@MainActor
class TKUIServiceViewModel: ObservableObject {
  
  enum DataInput {
    case visits(embarkation: StopVisits, disembarkation: StopVisits? = nil)
    case segment(TKSegment)
  }
  
  enum Next {
    case showAlerts([Alert])
  }
  
  /// - Parameters:
  ///   - dataInput: What to show
  ///   - itemSelected: UI input of selected item
  init(dataInput: DataInput) {
    self.dataInput = dataInput
    self.next = Empty().eraseToAnyPublisher()
    self.selectAnnotation = .never()
    self.realTimeUpdate = .idle
    
#warning("TODO: Set `selectAnnotation` and `next` properly")
  }
  
  private let dataInput: DataInput
  
  /// Title view with details about the embarkation.
  /// Can change with real-time data.
  @Published var header: TKUIDepartureCellContent?
  
  /// Sections with stops of the service, for display in a table view.
  /// Can change with real-time data.
  @Published var sections: [Section] = []
  
  /// Stops and route of the service, for display on a map.
  /// Can change with real-time data.
  @Published var mapContent: MapContent?

  /// Annotation matching the user's selection in the list.
  let selectAnnotation: Driver<TKUIIdentifiableAnnotation>
  
  /// Status of real-time update
  @Published var realTimeUpdate: TKRealTimeUpdateProgress<Void>
  
  private var realTimeUpdateTask: Task<Void, Never>?
  
  /// User-relevant errors, e.g., if service content couldn't get downloaded
  @Published var errorToShow: Error?
  
  let next: AnyPublisher<Next, Error>
  
  func populate() async throws {
    let (embarkation, disembarkation) = try await Self.getEmbarkation(for: dataInput)
    
    // Map content doesn't change with real-time
    self.mapContent = Self.buildMapContent(for: embarkation, disembarkation: disembarkation)
    
    self.rebuild(embarkation: embarkation, disembarkation: disembarkation)
    
    self.realTimeUpdateTask?.cancel()
    self.realTimeUpdateTask = Task { @MainActor [weak self, weak embarkation, weak disembarkation] in
      while !Task.isCancelled {
        guard let self, let embarkation, let region = embarkation.stop?.region else { return }
        self.realTimeUpdate = .updating
        let _ = try? await TKRealTimeFetcher.update([embarkation.service], in: region)
        
        self.rebuild(embarkation: embarkation, disembarkation: disembarkation)
        
        self.realTimeUpdate = .idle
        try? await Task.sleep(for: .seconds(10))
      }
    }
  }
  
  private func rebuild(embarkation: StopVisits, disembarkation: StopVisits?) {
    header = TKUIDepartureCellContent.build(embarkation: embarkation, disembarkation: disembarkation)
    sections = Self.buildSections(for: embarkation, disembarkation: disembarkation)
  }
  
  func selected(_ item: Item) -> Next? {
//    selectAnnotation = itemSelected
//      .asObservable()
//      .withLatestFrom(mapContent) { ($0, $1) }
//      .compactMap { $1?.findStop($0) }
//      .asDriver(onErrorDriveWith: .empty())

//    next = itemSelected
//      .asObservable()
//      .withLatestFrom(withEmbarkation) { (item: $0, embarkation: $1.0) }
//      .compactMap { (item, embarkation) -> Next? in
//        switch item {
//        case .info(let content) where !content.alerts.isEmpty:
//          return .showAlerts(embarkation.service.allAlerts())
//        default:
//          return nil
//        }
//      }
//      .asPublisher()

    return nil
  }
  
}

extension TKUIServiceViewModel {
  
  private static func getEmbarkation(for input: DataInput) async throws -> (StopVisits, StopVisits?) {
    switch input {
    case .visits(let embarkation, let disembarkation):
      if embarkation.service.hasServiceData {
        return (embarkation, disembarkation)
        
      } else if let region = embarkation.service.region {
        let success = try await TKBuzzInfoProvider.downloadContent(of: embarkation.service, embarkationDate: embarkation.departure ?? Date(), region: region)
        if !success {
          throw TKError(code: 87612, message: "Could not download service data.")
        }
        return (embarkation, disembarkation)

      } else {
        throw NSError(code: 57123, message: "Could not find region for service '\(embarkation.service.code)'.")
      }
      
    case .segment(let segment):
      guard let service = segment.service else {
        assertionFailure("Used an incompatible segment")
        throw NSError(code: 57123, message: "Could not find service for segment '\(segment.templateHashCode)'.")
      }
      
      if service.hasServiceData, let embarkation = segment.embarkation {
        return (embarkation, segment.finalSegmentIncludingContinuation().disembarkation)
      
      } else if let region = segment.startRegion {
        let success = try await TKBuzzInfoProvider.downloadContent(of: service, embarkationDate: segment.departureTime, region: region)
        if !success {
          throw TKError(code: 87612, message: "Could not download service data.")
        }
        guard let embarkation = segment.embarkation else {
          throw NSError(code: 57124, message: "Could not download details for '\(segment.description)'.")
        }
        return (embarkation, segment.finalSegmentIncludingContinuation().disembarkation)

      } else {
        throw NSError(code: 57123, message: "Could not find region for segment '\(segment.description)'.")
      }
    }
  }
  
}

// MARK: - Scrolling to embarkation

extension TKUIServiceViewModel {
  
  static func embarkationIndexPath(in sections: [Section]) -> IndexPath? {
    for (s, section) in sections.enumerated() {
      switch section.group {
      case .main, .info:
        return IndexPath(item: 0, section: s)
      case .incoming:
        continue
      }
    }
    return nil
  }
  
  static func beforeEmbarkationIndexPath(in sections: [Section]) -> IndexPath? {
    for (s, section) in sections.enumerated() {
      switch section.group {
      case .main, .info:
        continue
      case .incoming:
        return IndexPath(item: section.items.count - 1, section: s)
      }
    }
    return nil
  }
  
}
