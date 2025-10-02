//
//  TKUITripOverviewViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

import RxSwift
import RxCocoa

import TripKit

@MainActor
class TKUITripOverviewViewModel {
  
  typealias TriggerResult = TKUIInteractionResult<Never, Next>
  
  struct UIInput {
    var selected: Signal<Item> = .empty()
    var alertsEnabled: Signal<Bool> = .empty()
    var droppedPin: Signal<CLLocationCoordinate2D> = .empty()
    var isVisible: Driver<Bool> = .just(true)
  }
  
  init(presentedTrip: Infallible<Trip>, inputs: UIInput = UIInput(), includeTimeToLeaveNotification: Bool) {
    
    //MARK: Content
    
    dataSources = presentedTrip
      .asDriver(onErrorDriveWith: .empty())
      .map { $0.tripGroup.sources }
    
    let tripChanged: Observable<Trip> = presentedTrip
      .asObservable()
      .distinctUntilChanged { $0.objectID == $1.objectID }
    
    let servicesFetched = presentedTrip
      .asObservable()
      .flatMapLatest { trip in
        Self.fetchContentOfServices(in: trip)
          .catchAndReturn(()) // Swallow fetch errors
          .map { trip }
      }

    refreshMap = Observable.merge(tripChanged, servicesFetched)
      .asAssertingSignal()
    
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

    //MARK: User interaction
    
    let errorPublisher = PublishSubject<Error>()
    let catcher = errorPublisher.onNext
    self.error = errorPublisher.asAssertingSignal()
    
    let nextFromAlertToggle = inputs.alertsEnabled
      .with(tripUpdated) { ($1, $0) }
      .safeMap(catchError: catcher) {
        try await Self.toggleNotifications(enabled: $1, trip: $0, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      }
    
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
    
    let nextFromSelection = inputs.selected.compactMap { item -> TriggerResult? in
        switch item {
        case .impossible(let segment, _):
          let request = segment.insertRequestStartingHere()
          return .navigation(.showAlternativeRoutes(request))
        
        case .alert(let item):
          return .navigation(.showAlerts(item.alerts))
          
        case .moving, .stationary, .terminal:
          guard let segment = item.segment else { return nil }
          return .navigation(.handleSelection(segment))
        }
      }
    
    let nextFromPinDrop = inputs.droppedPin
      .with(tripUpdated) { ($1, $0 )}
      .safeMap(catchError: catcher) { try await Self.calculateTripWithStopOver(at: $1, trip: $0) }
    
    let merged = Signal.merge([nextFromSelection, nextFromAlertToggle, nextFromPinDrop])
    next = merged.compactMap(\.next)
    
  }
    
  let sections: Driver<[Section]>
  
  let actions: Driver<([TKUITripOverviewCard.TripAction], Trip)>
  
  let dataSources: Driver<[TKAPI.DataAttribution]>
  
  let notificationKinds: Driver<Set<TKAPI.TripNotification.MessageKind>>
  
  let notificationsEnabled: Driver<Bool>
  
  let refreshMap: Signal<Trip>
  
  let error: Signal<Error>
  
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
    case showAlternative(Trip)
  }
}
