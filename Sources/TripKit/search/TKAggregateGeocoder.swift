//
//  TKAggregateGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(MapKit)

import Foundation
import MapKit

@available(*, unavailable, renamed: "TKAggregateGeocoder")
public typealias SGAggregateGeocoder = TKAggregateGeocoder

public class TKAggregateGeocoder: NSObject {

  public let geocoders: [TKGeocoding]
  
  private let queue: OperationQueue
  private var geocoderResults = [String: [TKNamedCoordinate]]()
  private var geocoderQuery = ""

  public init(geocoders: [TKGeocoding]) {
    self.geocoders = geocoders
    
    queue = OperationQueue()
    queue.name = "com.skedgo.TripKit.aggregategeocoder"
    queue.qualityOfService = .userInitiated
  }
}

extension TKAggregateGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    
    // prepare for query
    queue.cancelAllOperations()
    geocoderResults.removeAll()
    geocoderQuery = input

    // kick off each individually and collect result in our map
    for geocoder in geocoders {
      let identifier = "\(type(of: geocoder))"

      queue.addOperation {
        geocoder.geocode(input, near: mapRect) { geocoderResult in
          switch geocoderResult {
          case .failure:
            self.queue.addOperation {
              if input == self.geocoderQuery {
                self.geocoderResults[identifier] = []
                self.considerCallback(input, completion: completion)
              }
            }

          case .success(let results):
            self.queue.addOperation {
              if input == self.geocoderQuery {
                self.geocoderResults[identifier] = results
                self.considerCallback(input, completion: completion)
              }
            }
          }
        }
      }
    }

//    let queries = geocoders.map {
//      $0.geocode(input, near: mapRect)
//        .asObservable()
//        .catchErrorJustReturn([]) // Individual failures shouldn't terminate the sequence
//    }
//    return Observable
//      .combineLatest(queries) {
//        $0.reduce([]) { $0.mergeWithPreferences($1) }
//      }
//      .take(1)
//      .asSingle()
  }
  
  //MARK: - Private
  
  private func considerCallback(_ inputString: String, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    if geocoderResults.count != geocoders.count {
      return
    }
    
    // all geocoders returned, so we merge the results
    let all = geocoderResults.reduce([] as [TKNamedCoordinate]) { previous, entry in
      return previous.mergeWithPreferences(entry.1)
    }
    
    completion(.success(all))
  }

}

#endif