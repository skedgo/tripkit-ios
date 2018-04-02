//
//  TKPathFriendliness.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public enum TKPathFriendliness {
  case friendly
  case unfriendly
  case dismount
  case unknown
  
  public var color: SGKColor {
    switch self {
    case .friendly:   return #colorLiteral(red: 0.2862745098, green: 0.862745098, blue: 0.3882352941, alpha: 1)
    case .unfriendly: return #colorLiteral(red: 1, green: 0.9058823529, blue: 0.2862745098, alpha: 1)
    case .dismount:   return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    case .unknown:    return #colorLiteral(red: 0.5607843137, green: 0.5450980392, blue: 0.5411764706, alpha: 1)
    }
  }
  
  public var title: String {
    switch self {
    case .friendly:   return Loc.FriendlyPath
    case .unfriendly: return Loc.UnfriendlyPath
    case .dismount:   return Loc.Dismount
    case .unknown:    return Loc.UnknownPathFriendliness
    }
  }
}

