//
//  StopLocation.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopLocation {
  public var region: SVKRegion? {
    if let name = regionName {
      return SVKRegionManager.sharedInstance().localRegion(named: name)
    } else {
      return location?.regions.first
    }
  }
  
  public var modeTitle: String {
    return stopModeInfo.alt
  }
  
  @objc(modeImageForIconType:)
  public func modeImage(for type: SGStyleModeIconType) -> SGKImage? {
    return SGStyleManager.image(forModeImageName: stopModeInfo.localImageName, isRealTime: false, of: type)
  }
  
  @objc(modeImageURLForIconType:)
  public func modeImageURL(for type: SGStyleModeIconType) -> URL? {
    guard let remoteName = stopModeInfo.remoteImageName else { return nil }
    return SVKServer.imageURL(forIconFileNamePart: remoteName, of: type)
  }
}

// MARK: - STKStopAnnotation

extension StopLocation: STKStopAnnotation {
  public var title: String? {
    return name
  }
  
  public var subtitle: String? {
    return location?.subtitle
  }
  
  public var coordinate: CLLocationCoordinate2D {
    return location?.coordinate ?? kCLLocationCoordinate2DInvalid
  }
  
  public var isDraggable: Bool {
    return false
  }
  
  public var pointDisplaysImage: Bool {
    return pointImage != nil
  }
  
  public var pointImage: SGKImage? {
    return modeImage(for: .mapIcon)
  }
  
  public var pointImageURL: URL? {
    return modeImageURL(for: .mapIcon)
  }
}

// MARK: - UIActivityItemSource

extension StopLocation: UIActivityItemSource {
  public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    // Note: We used to return 'nil' if we don't have `lastTopVisit`, but the protocol doesn't allow that
    return ""
  }
  
  public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
    guard let last = lastTopVisit else { return nil }
    
    var output: String = self.title ?? ""
    
    if let filter = filter, filter.characters.count > 0 {
      output.append(" (filter: \(filter)")
    }
    
    let predicate = departuresPredicate(from: last.departure)
    let visits = managedObjectContext?.fetchObjects(StopVisits.self, sortDescriptors: [NSSortDescriptor(key: "departures", ascending: true)], predicate: predicate, relationshipKeyPathsForPrefetching: nil, fetchLimit: 10) ?? []
    for visit in visits {
      output.append("\n")
      output.append(visit.smsString())
    }
    if output.contains("*") {
      output.append("\n* real-time")
    }
    
    return output
  }
  
  
}
