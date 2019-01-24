//
//  TKUISemaphoreView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 11.12.17.
//

import Foundation

/// An annotation that can be displayed using TripKitUI's `TKUISemaphoreView`
/// or just as a point on the map.
public protocol TKUISemaphoreDisplayable: TKUIImageAnnotationDisplayable {
  var semaphoreMode: TKUISemaphoreView.Mode { get }
  var bearing: NSNumber? { get }
  var canFlipImage: Bool { get }
  var isTerminal: Bool { get }
}

extension TKUISemaphoreView {
  public enum Mode: Equatable {
    case headWithTime(Date, TimeZone, isRealTime: Bool)
    case headWithFrequency(minutes: Int)
    case headOnly

    /// Whether this point should ideally be displayed using the style of
    /// `TKUISemaphoreView` rather than just a flat image.
    case none
  }
}

// MARK:

extension TKUISemaphoreView {
  
  @objc
  static func shouldObserve(_ annotation: MKAnnotation) -> Bool {
    return annotation is NSObject && annotation is TKUISemaphoreDisplayable
  }

  @objc
  static func isRealTime(_ annotation: MKAnnotation) -> Bool {
    if let displayable = annotation as? TKUISemaphoreDisplayable, case .headWithTime(_, _, let isRealTime) = displayable.semaphoreMode {
      return isRealTime
    } else {
      return false
    }
  }

  @objc(updateForAnnotation:)
  public func update(for annotation: MKAnnotation) {
    self.update(for: annotation, heading: 0)
  }
  
  @objc(updateForAnnotation:withHeading:)
  public func update(for annotation: MKAnnotation, heading: CLLocationDirection) {
    self.annotation = annotation
    
    let image = (annotation as? TKUIImageAnnotationDisplayable)?.pointImage
    let imageURL = (annotation as? TKUIImageAnnotationDisplayable)?.pointImageURL
    let asTemplate = (annotation as? TKUIImageAnnotationDisplayable)?.pointImageIsTemplate ?? false
    let bearing = (annotation as? TKUISemaphoreDisplayable)?.bearing
    let terminal = (annotation as? TKUISemaphoreDisplayable)?.isTerminal ?? false
    let canFlip = imageURL == nil && (annotation as? TKUISemaphoreDisplayable)?.canFlipImage == true
    
    setHeadWith(image, imageURL: imageURL, imageIsTemplate: asTemplate, forBearing: bearing, andHeading: heading, inRed: terminal, canFlipImage: canFlip)
  }
  
  @objc(rotateHeadForMagneticHeading:)
  public func rotateHead(magneticHeading: CLLocationDirection) {
    guard let bearing = (annotation as? TKUISemaphoreDisplayable)?.bearing?.floatValue else { return }
    updateHead(magneticHeading: magneticHeading, bearing: CLLocationDirection(bearing))
  }
  

  @objc(updateHeadForMagneticHeading:andBearing:)
  public func updateHead(magneticHeading: CLLocationDirection, bearing: CLLocationDirection) {
    headImageView.update(magneticHeading: CGFloat(magneticHeading), bearing: CGFloat(bearing))
    
    guard let displayable = (annotation as? TKUISemaphoreDisplayable) else { return }
    if displayable.canFlipImage && displayable.pointImageURL == nil {
      let totalBearing = bearing - magneticHeading
      let flip = totalBearing > 180 || totalBearing < 0
      self.flipHead(flip)
    } else {
      self.flipHead(false)
    }
  }
  
}

// MARK: Customisation

extension TKUISemaphoreView {
  
  @objc public static var customHeadTintColor: UIColor? = nil
  @objc public static var customHeadImage: UIImage? = nil
  @objc public static var customPointerImage: UIImage? = nil

  @objc
  public static var headTintColor: UIColor {
    if let custom = customHeadTintColor {
      return custom
    } else {
      return TKStyleManager.darkTextColor()
    }
  }

  
  @objc
  public static var headImage: UIImage {
    if let custom = customHeadImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-head")
    }
  }

  @objc
  public static var pointerImage: UIImage {
    if let custom = customPointerImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-pointer")
    }
  }

  
}

// MARK: Fix-Its

@available(*, unavailable, renamed: "TKUISemaphoreView")
public typealias SGSemaphoreView = TKUISemaphoreView

@available(*, unavailable, renamed: "TKUISemaphoreDisplayable")
public typealias STKUISemaphoreDisplayable = TKUISemaphoreDisplayable

@available(*, unavailable, renamed: "TKUISemaphoreDisplayable")
public typealias TKDisplayableTimePoint = TKUISemaphoreDisplayable
