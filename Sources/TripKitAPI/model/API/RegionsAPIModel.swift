//
//  RegionsAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct RegionsResponse: Codable, Sendable {
    public let modes: [String: ModeDetails]?
    public let regions: [TKRegion]?
    public let hashCode: Int
  }

  public struct ModeDetails: Codable, Sendable {
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
    
    public let title: String
    public let subtitle: String?
    public let websiteURL: URL?
    public let rgbColor: TKAPI.RGBColor
    public let required: Bool?
    public let implies: [String]?
    public let icon: String?
    public let isTemplate: Bool?
    public let isBranding: Bool?
    public let vehicleIcon: String?
  }
  
}
