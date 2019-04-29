//
//  TKUICustomization.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public class TKUICustomization {
  
  public static let shared = TKUICustomization()
  
  private init() { }
  
  /// The style to use for any of TGCardViewController-based controllers
  public var cardStyle: TGCardStyle = .default

  /// Called whenever a view controller or card is displaying a new object,
  /// which can be used to attaching debugging information to bug reports.
  public var feedbackActiveItemHandler: ((Any) -> Void)? = nil
  
  /// Called whenever a view controller or card encounteres an error that it
  /// cannot handle itself.
  public var alertHandler: ((Error, UIViewController) -> Void) = {
    print("\($1) encountered error: \($0)")
  }
  
}
