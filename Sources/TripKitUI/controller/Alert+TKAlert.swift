//
//  Alert+TKAlert.swift
//  TripKit
//
//  Created by Adrian Schönig on 12.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension Alert: TKAlert {
  public var infoURL: URL? { url.flatMap(URL.init) }
  public var icon: TKImage? { TKInfoIcon.image(for: infoIconType, usage: .normal) }
  public var iconURL: URL? { imageURL }
  public var lastUpdated: Date? { nil }
  public func isCritical() -> Bool { alertSeverity == .alert }
}
