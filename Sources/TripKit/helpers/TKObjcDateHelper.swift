//
//  TKObjcDateHelper.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 15/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

/// :nodoc:
@objc(TKObjcDateHelper)
public class _TKObjcDateHelper: NSObject {
  
  @objc
  public static func durationStringLong(forMinutes minutes: Int) -> String {
    return Date.durationStringLong(forMinutes: minutes)
  }
  
}
