//
//  RegionsAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  struct RegionsResponse: Codable {
    let modes: [String: ModeDetails]?
    let regions: [TKRegion]?
    let hashCode: Int
  }

  struct ModeDetails: Codable {
    private enum CodingKeys: String, CodingKey {
      case title
      case subtitle
      case websiteURL = "URL"
      case rgbColor = "color"
      case required
      case implies
      case icon
      case isTemplate
      case isBranding
      case vehicleIcon
    }
    
    let title: String
    let subtitle: String?
    let websiteURL: URL?
    let rgbColor: TKAPI.RGBColor
    let required: Bool?
    let implies: [String]?
    let icon: String?
    let isTemplate: Bool?
    let isBranding: Bool?
    let vehicleIcon: String?
    
    var color: TKColor {
      return rgbColor.color
    }
  }
  
}
