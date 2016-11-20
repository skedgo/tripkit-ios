//
//  TKRegionInformation.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public class TKRegionInfo: NSObject, Unmarshaling {
  
  public let streetBikePaths: Bool
  public let streetWheelchairAccessibility: Bool
  public let transitModes: [ModeInfo]
  public let transitBicycleAccessibility: Bool
  public let transitConcessionPricing: Bool
  public let transitWheelchairAccessibility: Bool
  public let paratransitInformation: TKParatransitInfo?
  
  public required init(object: MarshaledObject) throws {
    streetBikePaths = (try? object.value(for: "streetBicyclePaths")) ?? false
    streetWheelchairAccessibility = (try? object.value(for: "streetWheelchairAccessibility")) ?? false
    transitModes = (try? object.value(for: "transitModes")) ?? []
    transitBicycleAccessibility = (try? object.value(for: "transitBicycleAccessibility")) ?? false
    transitConcessionPricing = (try? object.value(for: "transitConcessionPricing")) ?? false
    transitWheelchairAccessibility = (try? object.value(for: "transitWheelchairAccessibility")) ?? false
    paratransitInformation = try? object.value(for: "paratransit")
  }
  
}

/**
 Informational class for paratransit information (i.e., transport for people with disabilities).
 Contains name of service, URL with more information and phone number.
 
 - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
 */
public class TKParatransitInfo: NSObject, Unmarshaling {
  public let name: String
  public let URL: String
  public let number: String
  
  public required init(object: MarshaledObject) throws {
    name   = try object.value(for: "name")
    URL    = try object.value(for: "URL")
    number = try object.value(for: "number")
  }
}
