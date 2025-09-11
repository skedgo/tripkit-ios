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
  init(dataInput: DataInput, itemSelected: Signal<Item>) {
    self.dataInput = dataInput
    self.next = Empty().eraseToAnyPublisher()
    self.selectAnnotation = .never()
    self.realTimeUpdate = .never()
  }
  
  private let dataInput: DataInput
  
  /// Title view with details about the embarkation.
  /// Can change with real-time data.
  @Published var header: TKUIDepartureCellContent?
  
  var headerPublisher: some Publisher<TKUIDepartureCellContent?, Never> { _header.projectedValue }
  
  /// Sections with stops of the service, for display in a table view.
  /// Can change with real-time data.
  @Published var sections: [Section] = []
  
  var sectionsPublisher: some Publisher<[Section], Never> { _sections.projectedValue }
  
  /// Stops and route of the service, for display on a map.
  /// Can change with real-time data.
  @Published var mapContent: MapContent?

  var mapContentPublisher: some Publisher<MapContent?, Never> { _mapContent.projectedValue }

  /// Annotation matching the user's selection in the list.
  let selectAnnotation: Driver<TKUIIdentifiableAnnotation>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  /// User-relevant errors, e.g., if service content couldn't get downloaded
  @Published var errorToShow: Error?
  
  let next: AnyPublisher<Next, Error>
  
  func populate() async throws {
    let (embarkation, disembarkation) = try await Self.getEmbarkation(for: dataInput)
    
    // Map content doesn't change with real-time
    self.mapContent = Self.buildMapContent(for: embarkation, disembarkation: disembarkation)
    
//    let realTimeUpdate = withEmbarkation
//      .flatMapLatest { TKUIServiceViewModel.fetchRealTimeUpdates(embarkation: $0.0) }
//    self.realTimeUpdate = realTimeUpdate.asDriver(onErrorJustReturn: .idle)
//    
//    let withNewRealTime = realTimeUpdate
//      .filter { if case .updated = $0 { return true } else { return false } }
//      .startWith(.updated(()))
//      .map { _ in }
    
//    withNewRealTime
//      .asObservable()
//      .withLatestFrom(withEmbarkation)
//      .compactMap(TKUIDepartureCellContent.build)
//      .subscribe { [weak self] in self?.header = $0 }
//      .disposed(by: disposeBag)
    header = TKUIDepartureCellContent.build(embarkation: embarkation, disembarkation: disembarkation)
    
//    Observable.combineLatest(withNewRealTime, withEmbarkation) { $1 }
//      .map(TKUIServiceViewModel.buildSections)
//      .subscribe { [weak self] in self?.sections = $0 }
//      .disposed(by: disposeBag)
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
