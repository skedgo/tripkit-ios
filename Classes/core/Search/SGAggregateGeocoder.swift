//
//  SGAggregateGeocoder.swift
//  TripGo
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

public class SGAggregateGeocoder: SGBaseGeocoder {

  public let geocoders: [SGGeocoder]
  
  private let queue: OperationQueue
  
  public init(geocoders: [SGGeocoder]) {
    self.geocoders = geocoders
    
    queue = OperationQueue()
    queue.name = "com.buzzhives.TripKit.aggregategeocoder"
    queue.qualityOfService = .userInitiated
  }
  
  //MARK: - SGGeocoder
  
  private var geocoderResults = [String: [SGKNamedCoordinate]]()
  private var geocoderQuery = ""
  
  override public func geocodeString(_ inputString: String, nearRegion mapRect: MKMapRect, success: @escaping SGGeocoderSuccessBlock, failure: SGGeocoderFailureBlock?) {
    
    // prepare for query
    queue.cancelAllOperations()
    geocoderResults.removeAll()
    geocoderQuery = inputString
    
    // kick off each individually and collect result in our map
    for geocoder in geocoders {
      let identifier = "\(type(of: geocoder))"

      queue.addOperation {
        geocoder.geocodeString(inputString, nearRegion: mapRect,
          success: { query, results in
            
            self.queue.addOperation {
              if query == self.geocoderQuery {
                self.geocoderResults[identifier] = results
                self.considerCallback(inputString, success: success, failure: failure)
              }
            }
            
            
        },
          failure: { query, error in
            
            self.queue.addOperation {
              if query == self.geocoderQuery {
                self.geocoderResults[identifier] = []
                self.considerCallback(inputString, success: success, failure: failure)
              }
            }
            
        })
      }
    }
  }
  
  //MARK: - Private
  
  private func considerCallback(_ inputString: String, success: SGGeocoderSuccessBlock, failure: SGGeocoderFailureBlock?) {
    if geocoderResults.count != geocoders.count {
      return
    }
    
    // all geocoders returned, so we merge the results
    let all = geocoderResults.reduce([] as [SGKNamedCoordinate]) { previous, entry in
      return previous.mergeWithPreferences(entry.1)
    }
    
    success(inputString, all)
  }
}


