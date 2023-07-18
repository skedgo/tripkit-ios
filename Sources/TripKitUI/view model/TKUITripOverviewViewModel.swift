//
//  TKUITripOverviewViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import TripKit

@MainActor
class TKUITripOverviewViewModel {
  
  struct UIInput {
    var selected: Signal<Item> = .empty()
    var alertsEnabled: Signal<Bool> = .empty()
    var isVisible: Driver<Bool> = .just(true)
  }
  
  init(presentedTrip: Infallible<Trip>, inputs: UIInput = UIInput(), includeTimeToLeaveNotification: Bool) {
    
    dataSources = presentedTrip
      .asDriver(onErrorDriveWith: .empty())
      .map { $0.tripGroup.sources }
    
    let tripChanged: Observable<Trip> = presentedTrip
      .asObservable()
      .distinctUntilChanged { $0.persistentId() == $1.persistentId() }
    
    let servicesFetched = presentedTrip
      .asObservable()
      .flatMapLatest { trip in
        Self.fetchContentOfServices(in: trip).map { trip }
      }

    refreshMap = Observable.merge(tripChanged, servicesFetched)
      .asSignal(onErrorSignalWith: .empty())
    
    let tripUpdated: Infallible<Trip> = presentedTrip
      .asObservable()
      .flatMapLatest {
        return TKRealTimeFetcher.rx.streamUpdates($0, active: inputs.isVisible.asObservable())
          .startWith($0)
          .catchAndReturn($0)
      }
      .share(replay: 1, scope: .forever)
      .asObservable()
      .observe(on: MainScheduler.instance)
      .asInfallible { _ in .empty() }
        
    sections = tripUpdated
      .map(Self.buildSections)
      .asDriver { assertionFailure("Unexpected error: \($0)"); return .never() }
    
    actions = tripUpdated
      .map { updated -> ([TKUITripOverviewCard.TripAction], Trip) in
        (TKUITripOverviewCard.config.tripActionsFactory?(updated) ?? [], updated)
      }
      .asDriver(onErrorDriveWith: .never())
    
    let nextFromAlertToggle: Signal<Next>
    if #available(iOS 14.0, *) {
      nextFromAlertToggle = inputs.alertsEnabled.asObservable()
        .withLatestFrom(tripUpdated) { ($1, $0) }
        .asyncMap { trip, enabled in
          if enabled {
            await TKUITripMonitorManager.shared.monitorRegions(from: trip, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
          } else {
            TKUITripMonitorManager.shared.stopMonitoring()
          }
        }
        .compactMap { nil } // No `Next
        .asSignal { _ in .empty() }
      
      notificationsEnabled = TKUITripMonitorManager.shared.rx.monitoredTrip
        .withLatestFrom(tripUpdated) { $0?.tripID == $1.tripId }
        .asDriver(onErrorJustReturn: false)
      
      notificationKinds = presentedTrip
        .asDriver(onErrorDriveWith: .empty())
        .map {
          Set($0
            .notifications(includeTimeToLeaveNotification: includeTimeToLeaveNotification)
            .map(\.messageKind)
          )
        }

    } else {
      nextFromAlertToggle = .empty()
      
      notificationsEnabled = .just(false)
      notificationKinds = .just([])
    }
    
    let nextFromSelection = inputs.selected.compactMap { item -> Next? in
        switch item {
        case .impossible(let segment, _):
          let request = segment.insertRequestStartingHere()
          return .showAlternativeRoutes(request)
        
        case .alert(let item):
          return .showAlerts(item.alerts)
          
        case .moving, .stationary, .terminal:
          guard let segment = item.segment else { return nil }
          return .handleSelection(segment)
        }
      }
    
    self.next = Signal.merge([nextFromSelection, nextFromAlertToggle])
    
  }
    
  let sections: Driver<[Section]>
  
  let actions: Driver<([TKUITripOverviewCard.TripAction], Trip)>
  
  let dataSources: Driver<[TKAPI.DataAttribution]>
  
  let notificationKinds: Driver<Set<TKAPI.TripNotification.MessageKind>>
  
  let notificationsEnabled: Driver<Bool>
  
  let refreshMap: Signal<Trip>
  
  let next: Signal<Next>
  
}

extension TKUITripOverviewViewModel {
  convenience init(initialTrip: Trip, includeTimeToLeaveNotification: Bool = true) {
    self.init(presentedTrip: .just(initialTrip), includeTimeToLeaveNotification: includeTimeToLeaveNotification)
  }
}

// MARK: - Navigation

extension TKUITripOverviewViewModel {
  
  
  enum Next {
    case handleSelection(TKSegment)
    case showAlerts([TKAlert])
    case showAlternativeRoutes(TripRequest)
  }
}
