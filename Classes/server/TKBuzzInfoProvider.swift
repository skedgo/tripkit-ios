//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class ParatransitInformation: NSObject {
  let name: String
  let URL: String
  let number: String
  
  init(name: String, URL: String, number: String) {
    self.name = name
    self.URL = URL
    self.number = number
  }
  
  class func fromJSONResponse(response: AnyObject) -> ParatransitInformation? {
    guard let JSON = response as? [String: AnyObject],
          let regions = JSON["regions"] as? [[String: AnyObject]],
          let region = regions.first,
          let dict = region["paratransit"] as? [String: String],
          let name = dict["name"],
          let URL = dict["URL"],
          let number = dict["number"] else {
      return nil
    }
    
    return ParatransitInformation(name: name, URL: URL, number: number)
  }
}

extension TKBuzzInfoProvider {

  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: (ParatransitInformation?) -> Void)
  {
    let paras = [
      "region": region.name
    ]
    SVKServer.sharedInstance().initiateDataTaskWithMethod(
      "POST",
      path: "regionInfo.json",
      parameters: paras,
      region: region,
      success: { response in
        let paratransit = ParatransitInformation.fromJSONResponse(response)
        completion(paratransit)
      },
      failure: { _ in
        completion(nil)
      })
  }
}