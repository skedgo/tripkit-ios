//
//  TKBookingTransitioner.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift



public enum TKBookingTransitioner {

  /// Performs the transition for `state` for the provided `mode`. This method
  /// should be called whenever the state maching is entering a new state, and the
  /// method will then do the work on any further transition until it gets into
  /// a new waiting state.
  ///
  /// It manages the following transitions:
  /// - `fetchingBookingForm`: Making URL calls and switching the appropriate
  ///    next state.
  /// - `authorizing`: Triggering OAuth.
  /// - `authCallbackRetrieved` and `authAppBecameActive`: Either transitioning
  ///    to making a follow-up server call, if both states were visited, or
  ///    back to waiting state after a timeout in case that the user cancelled.
  ///
  /// - parameter state: The current state
  /// - parameter segment: The mode identifier of the segment in said state.
  /// - returns: An observable of the next state, segment pair. This can be an
  ///    empty observable (i.e., one that never triggers) if no transition is
  ///    necessary.
  public static func transition(state: TKBookingStateMachine, forMode mode: String) -> Observable<TKBookingStateMachine> {
    
    switch state {
      
    // UI states, that we don't handle
    case .viewingQuickBooking,
         .authWaitingForCallback,
         .presentForm, .presentWeb,
         .completed:
      return Observable.empty()
      
    // Server state where we kick of requests
    case .fetchingBookingForm(let url, let data, _):
      let dict = data as? [AnyHashable: Any]
      return requestForm(url, data: dict, advancing: state)
      
    // Triggering authentication
    case .authorizing(let form):
      return OAuthClient.shared.rx_initiate(forMode: mode, form: form)
        .map { TKBookingTransitioner.handleOAuth($0, advancing: state) }
      
    case .authCallbackRetrieved(let url):
      return OAuthClient.shared.rx_handle(url)
        .map { TKBookingTransitioner.handleOAuth($0, advancing: state) }
      
    case .authAppBecameActive:
      return Observable.just(.viewingQuickBooking(nil))

    case .error:
      return Observable.just(.viewingQuickBooking(nil))
        .delay(0.2, scheduler: MainScheduler.asyncInstance) // Brief delay for consistent ordering
    
    }
    
  }
  
  
  private static func requestForm(_ url: URL, data: [AnyHashable: Any]? = nil, advancing state: TKBookingStateMachine) -> Observable<TKBookingStateMachine> {
    
    return BPKServerUtil.rx
      .requestForm(forBooking: url, postData: data)
      .map { response in

        let result: TKBookingFormType
        switch response {
        case .completed:                result = .emptyResponse
        case .followUpForm(let form):   result = TKBookingFormType.from(form)
        }

        var newState = state
        newState.serverDidLoad(form: result)
        return newState
        
      }
      .catchError { error in
        return Observable.just(.error(error))
      }
    
  }
  
  
  private static func handleOAuth(_ result: OAuthResult, advancing state: TKBookingStateMachine) -> TKBookingStateMachine {
    var newState = state
    newState.handleOAuth(result)
    return newState
  }
  
}

fileprivate enum TKBookingResponse {
  case followUpForm(BPKForm)
  case completed
}


extension Reactive where Base : BPKServerUtil {
  
  /// Send a form-response for a booking URL to the backend, retrieving either a
  /// follow-up form or, if no further action is required, just `nil`.
  fileprivate static func requestForm(forBooking url: URL, postData: [AnyHashable: Any]? = nil) -> Observable<TKBookingResponse> {
    
    return Observable.create { observer in
      
      BPKServerUtil.requestForm(forBooking: url, postData: postData) { status, _, response, _, error in
        if let response = response as? [NSObject: AnyObject] {
          // Further action required or a success-form was provided.
          // This is the case where OAuth was initiated as part of booking
          let form = BPKForm(json: response)
          observer.onNext(.followUpForm(form))
          observer.onCompleted()
          
        } else if let error = error {
          observer.onError(error)
          
        } else {
          // Empty response and empty error means that we are done, and no
          // further form is required.
          // This is the case where OAuth was initiated as part of linking
          // with an external provider and the linking was successful.
          observer.onNext(.completed)
          observer.onCompleted()
        }
      }
      
      return Disposables.create()
      
    }
  }
  
}


extension TKBookingFormType {

  /// Turns the booking form into the helper enum
  static func from(_ form: BPKForm) -> TKBookingFormType {
    
    if form.isClientSideOAuth {
      return .auth(form)
    
    } else if let agreementURL = form.surgePricingURL, let disregardURL = form.disregardURL, let next = form.actionURL() {
      return .web(agreementURL, disregardOn: disregardURL, next: next)
    
    } else if let url = form.tripUpdateURL, form.isLast {
      return .trip(url)
    
    } else {
      return .form(form)
      
    }
  }
  
}
