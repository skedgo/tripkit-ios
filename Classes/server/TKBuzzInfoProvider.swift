//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/**
 Informational class for paratransit information (i.e., transport for people with disabilities).
 Contains name of service, URL with more information and phone number.
 
 - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
 */
public class ParatransitInformation: NSObject {
  let name: String
  let URL: String
  let number: String
  
  init(name: String, URL: String, number: String) {
    self.name = name
    self.URL = URL
    self.number = number
  }
  
  private class func fromJSONResponse(response: AnyObject?) -> ParatransitInformation? {
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

extension ModeInfo {
  private class func fromJSONResponse(response: AnyObject?) -> [ModeInfo] {
    guard let JSON = response as? [String: AnyObject],
          let regions = JSON["regions"] as? [[String: AnyObject]],
          let region = regions.first,
          let array = region["transitModes"] as? [[String: AnyObject]] else {
      return []
    }
    
    return array.flatMap { ModeInfo(forDictionary: $0) }
  }
}

extension TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: ParatransitInformation? -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: ParatransitInformation.fromJSONResponse,
      completion: completion
    )
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   */
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: [ModeInfo] -> Void)
  {
    return fetchRegionInfo(
      region,
      transformer: ModeInfo.fromJSONResponse,
      completion: completion
    )
  }

  private class func fetchRegionInfo<E>(region: SVKRegion, transformer: AnyObject? -> E, completion: E -> Void)
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
        let result = transformer(response)
        completion(result)
      },
      failure: { _ in
        let result = transformer(nil)
        completion(result)
      })
  }
}