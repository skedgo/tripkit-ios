//
//  TKUIHomeViewModel+Next.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public enum TKUIHomeCardNextAction {
  
  case push(TGCard)
  
  case present(UIViewController)
  
  case selectOnMap(MKAnnotation)
  
}
