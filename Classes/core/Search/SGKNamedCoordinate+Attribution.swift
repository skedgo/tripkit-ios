//
//  SGKNamedCoordinate+Attribution.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

public extension SGKNamedCoordinate {
  
  @objc func setAttribution(actionTitle: String, website: String, appActionTitle: String, appLink: String, isVerified: NSNumber?) {
    data["websiteAction"] = actionTitle
    data["websiteLink"] = website
    data["appAction"] = appActionTitle
    data["appLink"] = appLink
    data["isVerified"] = isVerified
  }
  
  @objc var attributionWebsiteActionTitle: String? {
    return data["websiteAction"] as? String
  }
  
  @objc var attributionWebsiteLink: String? {
    return data["websiteLink"] as? String
  }

  @objc var attributionAppActionTitle: String? {
    return data["appAction"] as? String
  }

  @objc var attributionAppLink: String? {
    return data["appLink"] as? String
  }

  @objc var attributionIsVerified: NSNumber? {
    return data["isVerified"] as? NSNumber
  }
}
