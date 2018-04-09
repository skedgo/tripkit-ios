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

extension TKInterAppCommunicator {
  
  // MARK: - Device Capability
  
  @objc
  public static func deviceHasGoogleMaps() -> Bool {
    let testURL = URL(string: "comgooglemaps-x-callback://")!
    return UIApplication.shared.canOpenURL(testURL)
  }
  
  @objc
  public static func deviceHasWaze() -> Bool {
    let testURL = URL(string: "waze://")!
    return UIApplication.shared.canOpenURL(testURL)
  }
  
  // MARK: - Open Maps Apps
  
  @objc(openMapsAppInMode:routeFrom:to:viewController:initiatedBy:)
  public static func openMapsApp(
      in mode: TKInterAppCommunicatorMapDirectionMode,
      routeFrom origin: MKAnnotation?,
      to destination: MKAnnotation,
      viewController controller: UIViewController,
      initiatedBy sender: Any
    ) {
    
    let hasGoogleMaps = deviceHasGoogleMaps()
    let hasWaze = deviceHasWaze()
    
    if !hasGoogleMaps && !hasWaze {
      // just open Apple Maps
      openAppMaps(in: mode, routeFrom: origin, to: destination)
    } else {
      let actions = SGActions(title: Loc.GetDirections)
      
      // Apple Maps
      actions.addAction(Loc.AppleMaps) {
        openAppMaps(in: mode, routeFrom: origin, to: destination)
      }
      
      // Google Maps
      if (hasGoogleMaps) {
        actions.addAction(Loc.GoogleMaps) {
          openGoogleMaps(in: mode, routeFrom: origin, to: destination)
        }
      }
      
      // Waze
      if (hasWaze) {
        actions.addAction("Waze") {
          openWaze(routeTo: destination)
        }
      }
      
      actions.hasCancel = true
      actions.showForSender(sender, in: controller)
    }
  }
  
  @objc(openAppMapsInMode:routeFrom:to:)
  public static func openAppMaps(in mode: TKInterAppCommunicatorMapDirectionMode, routeFrom origin: MKAnnotation?, to destination: MKAnnotation) {
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
      if #available(iOS 10, *) {
        directionMode = MKLaunchOptionsDirectionsModeDefault
      } else {
        directionMode = MKLaunchOptionsDirectionsModeDriving
      }
    }
    
    let options = [MKLaunchOptionsDirectionsModeKey: directionMode]
    MKMapItem.openMaps(with: [originMapItem, destinationMapItem], launchOptions: options )
  }
  
  @objc(openGoogleMapsInMode:routeFrom:to:)
  public static func openGoogleMaps(in mode: TKInterAppCommunicatorMapDirectionMode, routeFrom origin: MKAnnotation?, to destination: MKAnnotation) {
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
    case .default:
      // nothing to do.
      break
    }
    
    if let callback = SGKConfig.shared.googleMapsCallback() {
      request.append(String(format: "x-success=%@", callback))
    }
    
    if let requestURL = URL(string: request) {
      UIApplication.shared.openURL(requestURL)
    }
  }
  
  @objc(openWazeRouteTo:)
  public static func openWaze(routeTo destination: MKAnnotation) {
    // https://www.waze.com/about/dev
    let request = String(format: "waze://?ll=%f,%f&navigate=yes", destination.coordinate.latitude, destination.coordinate.longitude)
    if let url = URL(string: request) {
      UIApplication.shared.openURL(url)
    }
  }
  
}
