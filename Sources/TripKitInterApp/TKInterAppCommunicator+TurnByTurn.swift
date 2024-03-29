//
//  TKInterAppCommunicator+TurnByTurn.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

import TripKit
import MapKit

extension TKInterAppCommunicator {
  
  @objc(canOpenInMapsApp:)
  public static func canOpenInMapsApp(_ segment: TKSegment) -> Bool {
    return segment.turnByTurnMode != nil
  }
  
}

extension TKInterAppCommunicator {
  
  // MARK: - Device Capability
  
  static func deviceHasGoogleMaps() -> Bool {
    let testURL = URL(string: "comgooglemaps-x-callback://")!
    return UIApplication.shared.canOpenURL(testURL)
  }
  
  static func deviceHasWaze() -> Bool {
    let testURL = URL(string: "waze://")!
    return UIApplication.shared.canOpenURL(testURL)
  }
  
  // MARK: - Open Maps Apps From Trip Segment
  
  /// Opens the segment in a maps app. Either directly in Apple Maps if nothing else is installed, or it will
  /// prompt for using Google Maps or Waze.
  ///
  /// - warning: Checking for Google Maps and Waze only works the appropriate URL schemes are
  ///            added to the `LSApplicationQueriesSchemes`of your app's `Info.plist`:
  ///
  /// ```
  /// <key>LSApplicationQueriesSchemes</key>
  /// <array>
  ///   <string>comgooglemaps-x-callback</string>
  ///   <string>waze</string>
  ///   ...
  /// </array>
  /// ```
  ///
  /// - Parameter segment: A segment for which `canOpenInMapsApp` returns `true`
  /// - Parameter controller: A controller to present the optional action sheet on
  /// - Parameter sender: A controller to present the optional action sheet on
  /// - Parameter currentLocationHandler: Will be called to check if turn-by-turn navigation
  ///               should start at the current location or at the segment's start location. If `nil` it will
  ///               start at the current location.
  @objc(openSegmentInMapsApp:forViewController:initiatedBy:currentLocationHandler:)
  public static func openSegmentInMapsApp(
      _ segment: TKSegment,
      forViewController controller: UIViewController,
      initiatedBy sender: Any,
      currentLocationHandler: ((TKSegment) -> Bool)?
    ) {
    
    let hasGoogleMaps = deviceHasGoogleMaps()
    let hasWaze = deviceHasWaze()
    
    if !hasGoogleMaps && !hasWaze {
      // Confirm to open Apple Maps
      let alert = UIAlertController(title: Loc.GetDirections, message: Loc.ConfirmOpen(appName: Loc.AppleMaps), preferredStyle: .alert)
      alert.addAction(.init(title: Loc.Cancel, style: .cancel))
      alert.addAction(.init(title: Loc.Open(appName: Loc.AppleMaps), style: .default) { _ in
        openSegmentInAppleMaps(segment, currentLocationHandler: currentLocationHandler)
      })
      controller.present(alert, animated: true)
      
    } else {
      let actions = UIAlertController(title: Loc.GetDirections, message: nil, preferredStyle: .actionSheet)
      
      actions.addAction(.init(title: Loc.AppleMaps, style: .default) { _ in
        openSegmentInAppleMaps(segment, currentLocationHandler: currentLocationHandler)
      })
      
      // Google Maps
      if (hasGoogleMaps) {
        actions.addAction(.init(title: Loc.GoogleMaps, style: .default) { _ in
          openSegmentInGoogleMaps(segment, currentLocationHandler: currentLocationHandler)
        })
      }
      
      // Waze
      if (hasWaze) {
        actions.addAction(.init(title: "Waze", style: .default) { _ in
          openSegmentInWaze(segment)
        })
      }
      
      actions.addAction(.init(title: Loc.Cancel, style: .cancel))
      controller.present(actions, animated: true)
    }
  }
  
  private static func openSegmentInAppleMaps(_ segment: TKSegment, currentLocationHandler: ((TKSegment) -> Bool)?) {
    guard
      let mode = segment.turnByTurnMode,
      let destination = segment.end
      else {
        assertionFailure("Turn by turn navigation does not apply to this segment OR segment does not have a destination")
        return
    }
    
    var origin: MKAnnotation?
    if currentLocationHandler?(segment) == false {
      origin = segment.start
    }
    
    openAppleMaps(in: mode, routeFrom: origin, to: destination)
  }
  
  private static func openSegmentInGoogleMaps(_ segment: TKSegment, currentLocationHandler: ((TKSegment) -> Bool)?) {
    guard
      let mode = segment.turnByTurnMode,
      let destination = segment.end
      else {
        assertionFailure("Turn by turn navigation does not apply to this segment OR segment does not have a destination")
        return
    }
    
    var origin: MKAnnotation?
    if currentLocationHandler?(segment) == false {
      origin = segment.start
    }
    
    openGoogleMaps(in: mode, routeFrom: origin, to: destination)
  }
  
  private static func openSegmentInWaze(_ segment: TKSegment) {
    guard
      let destination = segment.end,
      let mode = segment.turnByTurnMode,
      mode == .driving
      else {
        assertionFailure("Trying to open Waze without a destination OR the segment isn't a driving.")
        return
    }
    
    openWaze(routeTo: destination)
  }
  
  // MARK: - Open Maps Apps
  
  public static func openMapsApp(
      in mode: TKTurnByTurnMode,
      routeFrom origin: MKAnnotation?,
      to destination: MKAnnotation,
      viewController controller: UIViewController,
      initiatedBy sender: Any?
    ) {
    
    let hasGoogleMaps = deviceHasGoogleMaps()
    let hasWaze = deviceHasWaze()
    
    if !hasGoogleMaps && !hasWaze {
      // Confirm to open Apple Maps
      let alert = UIAlertController(title: Loc.GetDirections, message: Loc.ConfirmOpen(appName: Loc.AppleMaps), preferredStyle: .alert)
      alert.addAction(.init(title: Loc.Cancel, style: .cancel))
      alert.addAction(.init(title: Loc.Open(appName: Loc.AppleMaps), style: .default) { _ in
        openAppleMaps(in: mode, routeFrom: origin, to: destination)
      })
      controller.present(alert, animated: true)

    } else {
      let actions = UIAlertController(title: Loc.GetDirections, message: nil, preferredStyle: .actionSheet)
      
      actions.addAction(.init(title: Loc.AppleMaps, style: .default) { _ in
        openAppleMaps(in: mode, routeFrom: origin, to: destination)
      })
      
      // Google Maps
      if (hasGoogleMaps) {
        actions.addAction(.init(title: Loc.GoogleMaps, style: .default) { _ in
          openGoogleMaps(in: mode, routeFrom: origin, to: destination)
        })
      }
      
      // Waze
      if (hasWaze) {
        actions.addAction(.init(title: "Waze", style: .default) { _ in
          assert(mode == .driving, "Waze only supports driving turn by turn mode")
          openWaze(routeTo: destination)
        })
      }
      
      actions.addAction(.init(title: Loc.Cancel, style: .cancel))
      controller.present(actions, animated: true)
    }
  }
  
  private static func openAppleMaps(in mode: TKTurnByTurnMode, routeFrom origin: MKAnnotation?, to destination: MKAnnotation) {
    let originMapItem: MKMapItem
    if let unwrapped = origin {
      let originPlacemark = MKPlacemark(coordinate: unwrapped.coordinate, addressDictionary: nil)
      originMapItem = MKMapItem(placemark: originPlacemark)
      originMapItem.name = unwrapped.title ?? ""
    } else {
      originMapItem = MKMapItem.forCurrentLocation()
    }
    
    let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate, addressDictionary: nil)
    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
    destinationMapItem.name = destination.title ?? ""
    
    let directionMode: String
    switch mode {
    case .walking:
      directionMode = MKLaunchOptionsDirectionsModeWalking
    case .driving:
      directionMode = MKLaunchOptionsDirectionsModeDriving
    default:
      directionMode = MKLaunchOptionsDirectionsModeDefault
    }
    
    let options = [MKLaunchOptionsDirectionsModeKey: directionMode]
    MKMapItem.openMaps(with: [originMapItem, destinationMapItem], launchOptions: options )
  }
  
  private static func openGoogleMaps(in mode: TKTurnByTurnMode, routeFrom origin: MKAnnotation?, to destination: MKAnnotation) {
    // https://developers.google.com/maps/documentation/ios/urlscheme
    var request = "comgooglemaps-x-callback://?"
    
    // Origin is optional
    if let unwrapped = origin {
      request.append(String(format: "saddr=%.5f,%.5f&", unwrapped.coordinate.latitude, unwrapped.coordinate.longitude))
    }
    
    request.append(String(format: "daddr=%.5f,%.5f&", destination.coordinate.latitude, destination.coordinate.longitude))
    
    switch mode {
    case .walking:
      request.append("directionsmode=walking")
    case .driving:
      request.append("directionsmode=driving")
    case .cycling:
      request.append("directionsmode=bicycling")
    }
    
    if let callback = TKConfig.shared.googleMapsCallback {
      request.append(String(format: "x-success=%@", callback))
    }
    
    guard let requestURL = URL(string: request) else { assertionFailure(); return }
    UIApplication.shared.open(requestURL)
  }
  
  private static func openWaze(routeTo destination: MKAnnotation) {
    // https://www.waze.com/about/dev
    let request = String(format: "waze://?ll=%f,%f&navigate=yes", destination.coordinate.latitude, destination.coordinate.longitude)
    if let url = URL(string: request) {
      UIApplication.shared.open(url)
    }
  }
  
}
