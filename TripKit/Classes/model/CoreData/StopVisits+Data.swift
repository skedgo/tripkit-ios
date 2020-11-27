//
//  StopVisits+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 27.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension StopVisits: DataAttachable {}

extension StopVisits {
  public var startPlatform: String? {
    get { decodePrimitive(String.self, key: "startPlatform") }
    set { encodePrimitive(newValue, key: "startPlatform") }
  }

  public var endPlatform: String? {
    get { decodePrimitive(String.self, key: "endPlatform") }
    set { encodePrimitive(newValue, key: "endPlatform") }
  }
  
  public var timetableStartPlatform: String? {
    get { decodePrimitive(String.self, key: "timetableStartPlatform") }
    set { encodePrimitive(newValue, key: "timetableStartPlatform") }
  }

  public var timetableEndPlatform: String? {
    get { decodePrimitive(String.self, key: "timetableEndPlatform") }
    set { encodePrimitive(newValue, key: "timetableEndPlatform") }
  }
}
