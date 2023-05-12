//
//  TKUICustomization.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import TGCardViewController

import TripKit

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
  
  /// How card actions of style `.normal` should be displayed
  ///
  /// Defaults to `.outline`
  public var cardActionNormalStyle: TKUICardActionNormalStyle = .outline

  /// Called whenever a view controller or card is displaying a new object,
  /// which can be used to attaching debugging information to bug reports.
  public var feedbackActiveItemHandler: ((Any) -> Void)? = nil
  
  /// Called whenever a view controller or card encounteres an error that it
  /// cannot handle itself.
  public var alertHandler: ((Error, UIViewController) -> Void) = {
    print("\($1) encountered error: \($0)")
  }
  
  /// You can use this to force a compact layout for card actions
  ///
  /// By default, if there are fewer than two actions provided through
  /// a card's action factory, an extended layout (i.e., icon andd label
  /// are stacked horizontally) is used. If there are more than two actions
  /// then a compact layout (i.e., icon and labels are stacked vertically) is
  /// used.
  public var forceCompactActionsLayout: Bool = false
  
  /// Set this to `true` to show both image and title for card actions.
  ///
  /// The default value is `false`, which means an action is showing
  /// only the image.
  ///
  /// - note: If setting this to `true`, it's best to ensure the title is
  /// is short, otherise, text may get truncated.
  public var showCardActionTitle: Bool = false
  
  /// Set this to true if the services' transit icons should get the colour
  /// of the respective line.
  ///
  /// Default to `false`.
  public var colorCodeTransitIcons: Bool = false
  
  
  /// Provide a tap handler here to add an (i) accessory button next to
  /// autocompletion results, that otherwise don't get an accessory button.
  ///
  /// This handler is called when that button is tapped.
  public var locationInfoTapHandler: ((TKUILocationInfo) -> TKUILocationHandlerAction)? = nil
  
}

public struct TKUILocationInfo {
  public enum RouteButton {
    /// If this is present, then the location info should include a route button, which the provided
    /// title and tap handler. If there's already a route button in the location info screen, then
    /// this should replace it.
    case replace(title: String, onTap: () -> Void)

    case allowed

    case notAllowed
  }
  
  public let annotation: MKAnnotation
  
  public let routeButton: RouteButton
}

public enum TKUILocationHandlerAction {
  case push(TGCard)
}
