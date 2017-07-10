//
//  SGKNamedCoordinate+Attribution.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

public extension SGKNamedCoordinate {
  
  func setAttribution(actionTitle: String, website: String, appActionTitle: String, appLink: String, isVerified: NSNumber?) {
    data["websiteAction"] = actionTitle
    data["websiteLink"] = website
    data["appAction"] = appActionTitle
    data["appLink"] = appLink
    data["isVerified"] = isVerified
  }
  
  var attributionWebsiteActionTitle: String? {
    return data["websiteAction"] as? String
  }
  
  var attributionWebsiteLink: String? {
    return data["websiteLink"] as? String
  }

  var attributionAppActionTitle: String? {
    return data["appAction"] as? String
  }

  var attributionAppLink: String? {
    return data["appLink"] as? String
  }

  var attributionIsVerified: NSNumber? {
    return data["isVerified"] as? NSNumber
  }
}
