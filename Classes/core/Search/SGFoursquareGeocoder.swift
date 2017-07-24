//
//  SGFoursquareGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//
//

import Foundation

extension SGFoursquareGeocoder {
  
  public func hit(_ endpoint: String, paras: [String: Any], completion: @escaping ([String: Any]?, Error?) -> Void) {
    
    let session = URLSession.shared
    
    let urlString = "https://api.foursquare.com/v2/venues/" + endpoint
    
    var components = URLComponents(string: urlString)!

    components.queryItems = paras.map { key, value -> URLQueryItem in
      if let string = value as? String {
        return URLQueryItem(name: key, value: string)
      } else {
        return URLQueryItem(name: key, value: String(describing: value))
      }
    }
    
    let task = session.dataTask(with: components.url!) { (data, response, error) in
      
      if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        completion(json, nil)
      } else {
        completion(nil, error)
      }
    }
    
    task.resume()
  }
  
}
