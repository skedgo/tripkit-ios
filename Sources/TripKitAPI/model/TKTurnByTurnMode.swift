//
//  TKTurnByTurnMode.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public enum TKTurnByTurnMode: String, Codable, Sendable {
  case cycling = "CYCLING"
  case driving = "DRIVING"
  case walking = "WALKING"
}
