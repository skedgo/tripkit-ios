//
//  TKResultsFetcher.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

/// Fetches trips for a request
///
/// Also takes care of localising the user, if the query involves
/// the user's current location, and handles being hit multiple
/// times with different requests by only returning results from the
/// last requested query.
public class TKResultsFetcher {
  
  public enum Progress {
    case locating
    case started(Int)
    case partial(Int, Int)
    case finished
  }
  
  
  fileprivate enum Constants {
    static let secondsToRefine: TimeInterval = 2.5
  }
  
  
  /// Kicks off fetching trips, providing process via an observable stream.
  ///
  /// - note: If the request is for "now", the request will get modified by locking
  ///     in the departure times.
  /// - note: If the request uses the current location, the location will also get
  ///     locked in.
  ///
  /// - Parameters:
  ///   - request: The request for which to fetch trips
  ///   - classifier: Optional classifier, see `TKTripClassifier` for more
  /// - Returns: Stream of fetching the results, multiple call backs as different
  ///     modes are fetched.
  public static func streamTrips(for request: TripRequest, classifier: TKTripClassifier? = nil) -> Observable<Progress> {
    
    // first we'll lock in this trips time if necessary
    if request.type == .leaveASAP {
      request.timeType = NSNumber(value: TKTimeType.leaveAfter.rawValue)
      request.departureTime = Date()
    }
    
    // 1. Fetch current location if necessary
    let prepared: Single<TripRequest>
    if request.usesCurrentLocation {
      prepared = TKLocationManager.shared.rx
        .fetchCurrentLocation(within: Constants.secondsToRefine)
        .map { location in
          request.override(currentLocation: location)
          return request
        }
      
    } else {
      prepared = .just(request)
    }
    
    // 2. Then we can kick off the requests
    return prepared
      .asObservable()
      .flatMapLatest { request -> Observable<Progress> in
        return TKBuzzRouter.rx.multiFetchRequest(for: request, classifier: classifier)
      }
      .startWith(.locating)
  }
  
  /// Create a new replacement location for the user's fetched current location
  /// that can then be saved to the current `TripRequest` object.
  ///
  /// The recommendation is to check against the user's favourites and use those
  /// if they are nearby, so that the user sees "From home" rather than "From some
  /// address near my home".
  public static var replacementHandler: (CLLocation) -> TKNamedCoordinate = { location in
    return TKNamedCoordinate(coordinate: location.coordinate)
  }
  
}


fileprivate extension TripRequest {
  
  var usesCurrentLocation: Bool {
    let placeholder = TKLocationManager.shared.currentLocation
    return fromLocation === placeholder || toLocation === placeholder
  }
  
  func override(currentLocation: CLLocation) {
    let placeholder = TKLocationManager.shared.currentLocation
    if fromLocation === placeholder {
      fromLocation = TKResultsFetcher.replacementHandler(currentLocation)
    }
    if toLocation === placeholder {
      toLocation = TKResultsFetcher.replacementHandler(currentLocation)
    }
  }
  
}


fileprivate class CountHolder {
  var count: Int = 0
}



fileprivate extension Reactive where Base : TKBuzzRouter {
  
  static func multiFetchRequest(for request: TripRequest, classifier: TKTripClassifier? = nil) -> Observable<TKResultsFetcher.Progress> {
    
    var router: TKBuzzRouter! = TKBuzzRouter()
    
    return Observable.create { observer in
      
      var holder: CountHolder! = CountHolder()
      let count = router.multiFetchTrips(
        for: request,
        classifier: classifier,
        progress: { progress in
          observer.onNext(.partial(Int(progress), holder.count))
          
      }, completion: { _, error in
        if let error = error {
          observer.onError(error)
        } else {
          observer.onNext(.finished)
          observer.onCompleted()
        }
        
      }
      )
      
      holder.count = Int(count)
      observer.onNext(.started(Int(count)))
      
      return Disposables.create() {
        holder = nil
        router = nil
      }
    }
  }
  
}

