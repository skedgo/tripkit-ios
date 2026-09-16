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
    self.realTimeUpdate = .idle
  }
  
  private let dataInput: DataInput
  
  /// Title view with details about the embarkation.
  /// Can change with real-time data.
  @Published var header: TKUIDepartureCellContent?
  
  /// Sections with stops of the service, for display in a table view.
  /// Can change with real-time data.
  @Published var sections: [Section]? = nil
  
  /// Stops and route of the service, for display on a map.
  /// Can change with real-time data.
  @Published var mapContent: MapContent?

  /// Annotation matching the user's selection in the list.
  @Published var selectAnnotation: TKUIIdentifiableAnnotation?
  
  /// Status of real-time update
  @Published var realTimeUpdate: TKRealTimeUpdateProgress<Void> = .idle
  
  @Published var next: Next? = nil
  
  /// User-relevant error, e.g., if the service content couldn't get downloaded.
  /// Call `populate()` again to retry.
  @Published private(set) var error: Error?
  
  private var realTimeUpdateTask: Task<Void, Never>?
  
  func populate() async {
    error = nil
    do {
      try await loadContent()
    } catch {
      self.error = error
    }
  }
  
  private func loadContent() async throws {
    // Immediately populate header
    let (embarkation, disembarkation) = try Self.getEmbarkation(for: dataInput)
    header = TKUIDepartureCellContent.build(embarkation: embarkation, disembarkation: disembarkation)

    // Then make API requests...
    try await Self.populateService(for: dataInput)
    
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
  
  func selected(_ item: Item) throws {
    switch item {
    case .timing:
      self.selectAnnotation = mapContent?.findStop(item)
      self.next = nil
      
    case .info(let content) where !content.alerts.isEmpty:
      let (embarkation, _) = try Self.getEmbarkation(for: dataInput)
      self.next = .showAlerts(embarkation.service.allAlerts())
      
    case .info:
      self.next = nil
    }
  }
  
}

extension TKUIServiceViewModel {
  
  private static func getEmbarkation(for input: DataInput) throws -> (StopVisits, StopVisits?) {
    switch input {
    case .visits(let embarkation, let disembarkation):
      return (embarkation, disembarkation)
    case .segment(let segment):
      guard let embarkation = segment.embarkation else {
        assertionFailure("Used an incompatible segment")
        throw NSError(code: 57123, message: "Could not find service for segment '\(segment.templateHashCode)'.")
      }
      return (embarkation, segment.finalSegmentIncludingContinuation().disembarkation)
    }
  }
  
  private static func populateService(for input: DataInput) async throws {
    switch input {
    case .visits(let embarkation, _):
      if embarkation.service.hasServiceData {
        return
      } else if let region = embarkation.service.region {
        guard try await TKBuzzInfoProvider.downloadContent(of: embarkation.service, embarkationDate: embarkation.departure ?? Date(), region: region) else {
          throw NSError(code: 57125, message: "Could not download details for service '\(embarkation.service.code)'.")
        }
      } else {
        throw NSError(code: 57123, message: "Could not find region for service '\(embarkation.service.code)'.")
      }
      
    case .segment(let segment):
      guard let service = segment.service else {
        assertionFailure("Used an incompatible segment")
        throw NSError(code: 57124, message: "Could not find service for segment '\(segment.templateHashCode)'.")
      }
      
      if service.hasServiceData {
        return
      } else if let region = segment.startRegion {
        guard try await TKBuzzInfoProvider.downloadContent(of: service, embarkationDate: segment.departureTime, region: region) else {
          throw NSError(code: 57125, message: "Could not download details for service '\(service.code)'.")
        }
      } else {
        throw NSError(code: 57123, message: "Could not find region for service '\(service.code)'.")
      }
    }
  }
  
}
