//
//  TKUIServiceViewModel.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

/// View model for displaying and interacting with an individual
/// public transport service.
public class TKUIServiceViewModel {
  
  public typealias DataInput = (
    embarkation: StopVisits,
    disembarkation: StopVisits?
  )
  
  /// - Parameters:
  ///   - dataInput: What to show
  ///   - itemSelected: UI input of selected item
  public init(dataInput: DataInput, itemSelected: Driver<Item>) {
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
      .compactMap { TKUIDepartureCellContent.build(for: dataInput.embarkation) }
      .asDriver(onErrorDriveWith: .empty())

    sections = Driver.combineLatest(withNewRealTime, withContent) { $1 }
      .map(TKUIServiceViewModel.buildSections)
    
    // Map content doesn't change with real-time
    let mapContent = withContent.map(TKUIServiceViewModel.buildMapContent)
    self.mapContent = mapContent
    
    selectAnnotation = itemSelected
      .withLatestFrom(mapContent) { ($0, $1) }
      .asObservable()
      .compactMap { $1?.findStop($0) }
      .asDriver(onErrorDriveWith: .empty())
    
    error = errorPublisher.asDriver(onErrorRecover: { Driver.just($0) })
  }
  
  /// Title view with details about the embarkation.
  /// Can change with real-time data.
  public let header: Driver<TKUIDepartureCellContent>
  
  /// Sections with stops of the service, for display in a table view.
  /// Can change with real-time data.
  public let sections: Driver<[Section]>
  
  /// Stops and route of the service, for display on a map.
  /// Can change with real-time data.
  public let mapContent: Driver<MapContent?>
  
  /// Annotation matching the user's selection in the list.
  public let selectAnnotation: Driver<MKAnnotation>
  
  /// Status of real-time update
  ///
  /// - note: Real-updates are only enabled while you're connected
  ///         to this driver.
  public let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Void>>
  
  /// User-relevant errors, e.g., if service content couldn't get downloaded
  public let error: Driver<Error>
}

// MARK: - Scrolling to embarkation

extension TKUIServiceViewModel {
  
  public static func embarkationIndexPath(in sections: [Section]) -> IndexPath? {
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
