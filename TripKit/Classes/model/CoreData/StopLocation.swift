//
//  StopLocation.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopLocation {
  @objc public var region: SVKRegion? {
    if let name = regionName {
      return TKRegionManager.shared.localRegion(named: name)
    } else {
      return location?.regions.first
    }
  }
  
  @objc public var modeTitle: String {
    return stopModeInfo.alt
  }
  
  public var isWheelchairAccessible: Bool? {
    return wheelchairAccessible?.boolValue
  }
  
  @objc(modeImageForIconType:)
  public func modeImage(for type: SGStyleModeIconType) -> SGKImage? {
    guard let localName = stopModeInfo?.localImageName else { return nil }
    return SGStyleManager.image(forModeImageName: localName, isRealTime: false, of: type)
  }
  
  @objc(modeImageURLForIconType:)
  public func modeImageURL(for type: SGStyleModeIconType) -> URL? {
    guard let remoteName = stopModeInfo?.remoteImageName else { return nil }
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
  
  public var pointClusterIdentifier: String? {
    return stopModeInfo?.identifier ?? "StopLocation"
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
  
  public var pointImageIsTemplate: Bool {
    return stopModeInfo?.remoteImageIsTemplate ?? false
  }
}

// MARK: - UIActivityItemSource

#if os(iOS)

  extension StopLocation: UIActivityItemSource {
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      // Note: We used to return 'nil' if we don't have `lastTopVisit`, but the protocol doesn't allow that
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
      guard let last = lastTopVisit else { return nil }
      
      var output: String = self.title ?? ""
      
      if let filter = filter, !filter.isEmpty {
        output.append(" (filter: \(filter)")
      }
      
      let predicate = departuresPredicate(from: last.departure)
      let visits = managedObjectContext?.fetchObjects(StopVisits.self, sortDescriptors: [NSSortDescriptor(key: "departure", ascending: true)], predicate: predicate, relationshipKeyPathsForPrefetching: nil, fetchLimit: 10) ?? []
      output.append("\n")
      output.append(visits.localizedShareString)
      return output
    }
    
  }
  
  extension Array where Element: StopVisits {
    public var localizedShareString: String {
      var output = ""
      for visit in self {
        output.append(visit.smsString())
        output.append("\n")
      }
      if output.contains("*") {
        output.append("* real-time")
      }
      return output
    }
  }

#endif
