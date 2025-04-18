//
//  TKUIResultsFetcher.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

import RxSwift

import TripKit

/// Fetches trips for a request
///
/// Also takes care of localising the user, if the query involves
/// the user's current location, and handles being hit multiple
/// times with different requests by only returning results from the
/// last requested query.
public class TKUIResultsFetcher {
  
  /// The progress of a single routing fetch request
  public enum Progress: Equatable {
    
    /// Optional step at the beginning to locate the user, if the request starts or ends
    /// at the user's current location.
    case locating
    
    /// Results are being fetched, indiciating the total number of requests.
    case started(total: Int)
    
    /// The provided number of the provided total have been fetched.
    case partial(completed: Int, total: Int)
    
    /// All results have been fetched.
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
  ///   - modes: The modes to enable. If set to `nil` then it'll use the modes as set in the user defaults (see `TKUserProfileHelper` for more)
  ///   - classifier: Optional classifier, see `TKTripClassifier` for more
  /// - Returns: Stream of fetching the results, multiple call backs as different
  ///     modes are fetched.
  public static func streamTrips(for request: TripRequest, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, baseURL: URL? = nil) -> Observable<Progress> {
    
    // first we'll lock in this trips time if necessary
    if request.type == .leaveASAP {
      request.setTime(Date(), for: .leaveAfter)
    }
    
    // 1. Fetch current location if necessary
    var prepared: Single<(TripRequest, Set<String>?)>
    if request.usesCurrentLocation {
      prepared = TKLocationManager.shared.rx
        .fetchCurrentLocation(within: Constants.secondsToRefine)
        .map { location in
          request.override(currentLocation: location)
          return (request, nil)
        }
      
    } else {
      prepared = .just((request, nil))
    }
    
    if let modeAdjuster = Self.modeReplacementHandler {
      prepared = prepared.flatMap { (request: TripRequest, _) in
        let modesToAdjust: Set<String> = modes ?? request.modes
        let region = request.startRegion ?? request.spanningRegion
        return modeAdjuster(region, modesToAdjust, request)
          .map { (request, $0) }
      }
    }
    
    // 2. Then we can kick off the requests
    return prepared
      .asObservable()
      .flatMapLatest { (request, modes) -> Observable<Progress> in
        return TKRouter.rx.multiFetchRequest(
          for: request, modes: modes,
          classifier: classifier,
          baseURL: baseURL
        )
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
  
  /// Replace the set of provided modes with the modes returned by the `Single`, called before
  /// by `streamTrips` at the very start and information is not cached.
  public static var modeReplacementHandler: ((TKRegion, Set<String>, TripRequest) -> Single<Set<String>>)? = nil
  
}


fileprivate extension TripRequest {
  
  var usesCurrentLocation: Bool {
    !fromLocation.coordinate.isValid || !toLocation.coordinate.isValid
  }
  
  func override(currentLocation: CLLocation) {
    if !fromLocation.coordinate.isValid {
      fromLocation = TKUIResultsFetcher.replacementHandler(currentLocation)
    }
    if !toLocation.coordinate.isValid {
      toLocation = TKUIResultsFetcher.replacementHandler(currentLocation)
    }
  }
  
}


fileprivate class CountHolder {
  var count: Int = 0
}


fileprivate extension Reactive where Base : TKRouter {
  
  static func multiFetchRequest(for request: TripRequest, modes: Set<String>?, classifier: TKTripClassifier? = nil, baseURL: URL? = nil, apiKey: String? = nil) -> Observable<TKUIResultsFetcher.Progress> {
    
    return Observable.create { observer in
      var router: TKRouter! = TKRouter(config: .userSettings())
      if baseURL != nil || apiKey != nil {
        router.server = TKRoutingServer(baseURL: baseURL, apiKey: apiKey)
      }
      var holder: CountHolder! = CountHolder()
      let count = router.multiFetchTrips(
        for: request,
        modes: modes,
        classifier: classifier,
        progress: { [weak holder] progress in
          guard let holder = holder else { return }
          observer.onNext(.partial(completed: Int(progress), total: holder.count))
        }, completion: { result in
          switch result {
          case .failure(let error):
            observer.onError(error)
          case .success:
            observer.onNext(.finished)
            observer.onCompleted()
          }
        }
      )
      
      holder.count = Int(count)
      observer.onNext(.started(total: Int(count)))
      
      return Disposables.create() {
        holder = nil
        router = nil
      }
    }
  }
  
}

