//
//  StopLocation.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import MapKit

extension StopLocation {
  @objc public var timeZone: TimeZone? {
    location?.timeZone ?? region?.timeZone
  }
  
  @objc public var region: TKRegion? {
    if let code = regionName {
      return TKRegionManager.shared.localRegion(code: code)
    } else {
      let region = location?.regions.first
      regionName = region?.code
      return region
    }
  }
  
  @objc public var modeTitle: String {
    return stopModeInfo?.alt ?? ""
  }
}

// MARK: - MKAnnotation

extension StopLocation: MKAnnotation {
  public var title: String? {
    return name
  }
  
  public var subtitle: String? {
    return location?.subtitle
  }
  
  public var coordinate: CLLocationCoordinate2D {
    return location?.coordinate ?? kCLLocationCoordinate2DInvalid
  }

}

// MARK: - UIActivityItemSource

#if canImport(UIKit)

  extension StopLocation: UIActivityItemSource {
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      // Note: We used to return 'nil' if we don't have `lastStopVisit`, but the protocol doesn't allow that
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      guard let last = lastStopVisit else { return nil }
      
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
      
      let _ = self.reduce(output) { (current, next) -> String in
        guard let smsString = next.smsString else { return current }
        output.append(smsString)
        output.append("\n")
        return output
      }
      
      if output.contains("*") {
        output.append("* real-time")
      }
      
      return output
    }
  }

#endif
