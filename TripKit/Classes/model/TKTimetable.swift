//
//  TKTimetable.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// Small helper that summarises the input required to build a timetable. See `TKUITimetableCard`.
public struct TKTimetable {
  public enum TimetableType {
    case departures(stopCode: String)
    case multipleDepartures(stopCodes: [String])
    case stopToStop(startStopCode: String, endStopCode: String, endRegion: TKRegion)
  }

  public let title: String
  public let type: TimetableType
  public let region: TKRegion

  public init(title: String, type: TKTimetable.TimetableType, region: TKRegion) {
    self.title = title
    self.type = type
    self.region = region
  }
  
}
