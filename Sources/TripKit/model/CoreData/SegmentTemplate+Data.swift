//
//  SegmentTemplate+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SegmentTemplate: DataAttachable {}

extension SegmentTemplate {
  var localCost: TKLocalCost? {
    get { decode(TKLocalCost.self, key: "localCost") }
    set { encode(newValue, key: "localCost") }
  }
  
  /// The preferred map-tiles to use for this segment. `nil` if default.
  var mapTiles: TKMapTiles? {
    get { decode(TKMapTiles.self, key: "mapTiles") }
    set { encode(newValue, key: "mapTiles") }
  }
  
  var miniInstruction: TKMiniInstruction? {
    get { decode(TKMiniInstruction.self, key: "miniInstruction") }
    set { encode(newValue, key: "miniInstruction") }
  }
  
  @objc var modeInfo: TKModeInfo? {
    get { decode(TKModeInfo.self, key: "modeInfo") }
    set { encode(newValue, key: "modeInfo") }
  }
  
  var turnByTurnMode: TKTurnByTurnMode? {
    get { decodePrimitive(TKTurnByTurnMode.self, key: "turnByTurnMode") }
    set { encodePrimitive(newValue, key: "turnByTurnMode") }
  }
  
  var notifications: [TKAPI.TripNotification]? {
    get { decode([TKAPI.TripNotification].self, key: "notifications") }
    set { encode((newValue?.isEmpty == false) ? newValue : nil, key: "notifications") }
  }
}
