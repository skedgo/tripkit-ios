//
//  StopVisits.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopVisits {
  
  @objc public func grouping(previous: StopVisits?, next: StopVisits?) -> TKGrouping {
    let sameAsBefore = previous?.searchString == searchString
    let sameAsAfter = next?.searchString == searchString
    
    switch (sameAsBefore, sameAsAfter) {
    case (true, true): return .middle
    case (true, _):    return .end
    case (_, true):    return .start
    default:           return .individual
    }
  }
  
}

// MARK: - MKAnnotation

extension StopVisits: MKAnnotation {
  
  public var title: String? {
    if let departure = departure {
      return TKStyleManager.timeString(departure, for: timeZone)
    } else if let arrival = arrival {
      return TKStyleManager.timeString(arrival, for: timeZone)
    } else {
      return stop.title
    }
  }
  
  public var subtitle: String? {
    if departure != nil || arrival != nil {
      return stop.title
    } else {
      return nil
    }
  }
  
  public var coordinate: CLLocationCoordinate2D {
    return stop.coordinate
  }
  
}


// MARK: - TKDisplayablePoint

extension StopVisits: TKDisplayablePoint {
  
  public var pointDisplaysImage: Bool {
    return true
  }
  
  public var isDraggable: Bool {
    return false
  }

  public var pointClusterIdentifier: String? {
    return service.modeInfo?.identifier ?? "StopVisits"
  }
  
  public var pointImage: TKImage? {
    return service.modeImage(for: .listMainMode)
  }
  
  public var pointImageURL: URL? {
    return service.modeImageURL(for: .listMainMode)
  }
  
  public var pointImageIsTemplate: Bool {
    return service.modeImageIsTemplate
  }
  
}

// MARK: - STKDisplayableTimePoint

extension StopVisits: TKDisplayableTimePoint {
  
  public var time: Date {
    get {
      return departure ?? arrival ?? Date()
    }
    set {
      departure = newValue
    }
  }
  
  public var timeZone: TimeZone {
    return stop.region?.timeZone ?? .current
  }
  
  public var timeIsRealTime: Bool {
    return service.isRealTime
  }
  
  public var canFlipImage: Bool {
    return true
  }
  
  public var isTerminal: Bool {
    return false
  }
  
  public var prefersSemaphore: Bool {
    return false
  }
}

// MARK: - TKRealTimeUpdatable

extension StopVisits: TKRealTimeUpdatable {
  public var wantsRealTimeUpdates: Bool {
    return service.wantsRealTimeUpdates
  }
  
  public var objectForRealTimeUpdates: Any {
    return self
  }
  
  public var regionForRealTimeUpdates: TKRegion {
    return stop.region ?? .international
  }
}


// MARK: - UIActivityItemSource

#if os(iOS)
  
  extension StopVisits: UIActivityItemSource {
    
    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
      return service.modeTitle ?? ""
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      
      let format = NSLocalizedString("I'll take a %@ at %@ from %@.", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Indication of an activity. (old key: ActivityIndication)")
      return String(format: format,
                    service.shortIdentifier() ?? "",
                    TKStyleManager.timeString(time, for: timeZone),
                    stop.name ?? stop.stopCode
      )
      
    }
    
  }
  
#endif
