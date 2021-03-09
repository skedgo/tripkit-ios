//
//  TKUIServiceViewModel.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

/// View model for displaying and interacting with an individual
/// transport service.
class TKUIServiceViewModel {
  
  enum DataInput {
    case visits(embarkation: StopVisits, disembarkation: StopVisits? = nil)
    case segment(TKSegment)
  }
  
  /// - Parameters:
  ///   - dataInput: What to show
  ///   - itemSelected: UI input of selected item
  init(dataInput: DataInput, itemSelected: Signal<Item>) {
    
    let errorPublisher = PublishSubject<Error>()
    
    let withEmbarkation = Self.getEmbarkation(for: dataInput)
      .asObservable()
      .share(replay: 1, scope: .forever)
    
    let realTimeUpdate =
      withEmbarkation
      .flatMapLatest { TKUIServiceViewModel.fetchRealTimeUpdates(embarkation: $0.0) }
    self.realTimeUpdate = realTimeUpdate.asDriver(onErrorJustReturn: .idle)
    
    let withNewRealTime = realTimeUpdate
      .filter { if case .updated = $0 { return true } else { return false } }
      .startWith(.updated(()))
      .map { _ in }
    
    header = withNewRealTime
      .asObservable()
      .withLatestFrom(withEmbarkation)
      .compactMap(TKUIDepartureCellContent.build)
      .asDriver(onErrorDriveWith: .empty())

    sections = Observable.combineLatest(withNewRealTime, withEmbarkation) { $1 }
      .map(TKUIServiceViewModel.buildSections)
      .asDriver(onErrorJustReturn: [])
    
    // Map content doesn't change with real-time
    let mapContent = withEmbarkation.map(TKUIServiceViewModel.buildMapContent)
    self.mapContent = mapContent.asDriver(onErrorJustReturn: nil)
    
    selectAnnotation = itemSelected
      .asObservable()
      .withLatestFrom(mapContent) { ($0, $1) }
      .compactMap { $1?.findStop($0) }
      .asDriver(onErrorDriveWith: .empty())
    
    error = errorPublisher.asDriver(onErrorRecover: { Driver.just($0) })
  }
  
  /// Title view with details about the embarkation.
  /// Can change with real-time data.
  let header: Driver<TKUIDepartureCellContent>
  
  /// Sections with stops of the service, for display in a table view.
  /// Can change with real-time data.
  let sections: Driver<[Section]>
  
  /// Stops and route of the service, for display on a map.
  /// Can change with real-time data.
  let mapContent: Driver<MapContent?>
  
  /// Annotation matching the user's selection in the list.
  let selectAnnotation: Driver<MKAnnotation>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  /// User-relevant errors, e.g., if service content couldn't get downloaded
  let error: Driver<Error>
  
}

extension TKUIServiceViewModel {
  
  private static func getEmbarkation(for input: DataInput) -> Single<(StopVisits, StopVisits?)> {
    switch input {
    case .visits(let embarkation, let disembarkation):
      return .just((embarkation, disembarkation))
    case .segment(let segment):
      guard let service = segment.service else {
        assertionFailure("Used an incompatible segment")
        return .never()
      }
      
      if service.hasServiceData, let embarkation = segment.embarkation {
        return .just((embarkation, segment.disembarkation))
      
      } else {
        return TKBuzzInfoProvider.rx.downloadContent(of: service, forEmbarkationDate: segment.departureTime, in: segment.startRegion!)
          .map { (segment.embarkation!, segment.disembarkation) }
      }
    }
  }
  
}

// MARK: - Scrolling to embarkation

extension TKUIServiceViewModel {
  
  static func embarkationIndexPath(in sections: [Section]) -> IndexPath? {
    for (s, section) in sections.enumerated() {
      for (i, item) in section.items.enumerated() {
        if item.isVisited {
          return IndexPath(item: i, section: s)
        }
      }
    }
    return nil
  }
  
}
