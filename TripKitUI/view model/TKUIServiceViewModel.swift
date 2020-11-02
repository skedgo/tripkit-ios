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
  
  typealias DataInput = (
    embarkation: StopVisits,
    disembarkation: StopVisits?
  )
  
  /// - Parameters:
  ///   - dataInput: What to show
  ///   - itemSelected: UI input of selected item
  init(dataInput: DataInput, itemSelected: Signal<Item>) {
    
    embarkationPair = (dataInput.embarkation, dataInput.disembarkation)
    
    let errorPublisher = PublishSubject<Error>()
    
    let realTimeUpdate = TKUIServiceViewModel.fetchRealTimeUpdates(embarkation: dataInput.embarkation)
      .asDriver(onErrorJustReturn: .idle)
    self.realTimeUpdate = realTimeUpdate
    
    let withNewRealTime = realTimeUpdate
      .filter { if case .updated = $0 { return true } else { return false } }
      .startWith(.updated(()))
      .map { _ in }
    
    let withContent = TKUIServiceViewModel
      .fetchServiceContent(embarkation: dataInput.embarkation)
      .map { (dataInput.embarkation, dataInput.disembarkation) } // match input to `build*` methods
      .asDriver(onErrorRecover: { error in
        errorPublisher.onNext(error)
        return .empty()
      })

    header = withNewRealTime
      .asObservable()
      .compactMap { TKUIDepartureCellContent.build(embarkation: dataInput.embarkation, disembarkation: dataInput.disembarkation) }
      .asDriver(onErrorDriveWith: .empty())

    sections = Driver.combineLatest(withNewRealTime, withContent) { $1 }
      .map(TKUIServiceViewModel.buildSections)
    
    // Map content doesn't change with real-time
    let mapContent = withContent.map(TKUIServiceViewModel.buildMapContent)
    self.mapContent = mapContent
    
    selectAnnotation = itemSelected
      .asObservable()
      .withLatestFrom(mapContent) { ($0, $1) }
      .compactMap { $1?.findStop($0) }
      .asDriver(onErrorDriveWith: .empty())
    
    error = errorPublisher.asDriver(onErrorRecover: { Driver.just($0) })
  }
  
  let embarkationPair: TKUIServiceCard.EmbarkationPair
  
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
