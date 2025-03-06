//
//  TKSegment+Images.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

// MARK: - Image helpers

extension TKSegment {
  
  func image() -> TKImage? {
    var localImageName = modeInfo?.localImageName
    
    if trip.showNoVehicleUUIDAsLift && privateVehicleType == .car && reference?.vehicleUUID == nil {
      localImageName = "car-pool"
    }
    guard let imageName = localImageName else { return nil }
    
    if let specificImage = TKStyleManager.image(forModeImageName: imageName) {
      return specificImage
    
    } else if let modeIdentifier = modeIdentifier {
      let genericImageName = TKTransportMode.modeImageName(forModeIdentifier: modeIdentifier)
      return TKStyleManager.image(forModeImageName: genericImageName)

    } else {
      return nil
    }
  }

  func imageURL(for iconType: TKStyleModeIconType) -> URL? {
    if iconType == .vehicle, let icon = realTimeVehicle?.icon {
      return TKServer.imageURL(iconFileNamePart: icon, iconType: iconType)
    } else {
      return modeInfo?.imageURL(type: iconType)
    }
  }
}

#endif
