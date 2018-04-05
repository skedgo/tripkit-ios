//
//  TKInterAppCommunicator.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension TKInterAppCommunicator {
  
  @objc(canOpenInMapsApp:)
  public static func canOpenInMapsApp(_ segment: TKSegment) -> Bool {
    return turnByTurnMode(segment) != nil
  }
  
  public static func turnByTurnMode(_ segment: TKSegment) -> TKTurnByTurnMode? {
    return segment.template?.turnByTurnMode
  }
  
}
