//
//  TKUICustomization.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

/// This class let's you customise various aspects of TripKitUI that apply across multiple view controllers
/// or cards. You can do this by setting the various parts of `TKUICustomization.shared`, which should
/// be done before displaying any view controllers or cards.
public class TKUICustomization {
  
  /// The shared customisation singleton. Update its properties and the customisation will then be reflected
  /// in the different view controllers and cards.
  public static let shared = TKUICustomization()
  
  private init() { }
  
  /// The style to use for any of TGCardViewController-based controllers
  public var cardStyle: TGCardStyle = {
    var style = TGCardStyle.default
    style.backgroundColor = .tkBackground
    style.grabHandleColor = .tkLabelTertiary
    style.titleTextColor = .tkLabelPrimary
    style.subtitleTextColor = .tkLabelSecondary
    return style
  }()

  /// Called whenever a view controller or card is displaying a new object,
  /// which can be used to attaching debugging information to bug reports.
  public var feedbackActiveItemHandler: ((Any) -> Void)? = nil
  
  /// Called whenever a view controller or card encounteres an error that it
  /// cannot handle itself.
  public var alertHandler: ((Error, UIViewController) -> Void) = {
    print("\($1) encountered error: \($0)")
  }
  
}
