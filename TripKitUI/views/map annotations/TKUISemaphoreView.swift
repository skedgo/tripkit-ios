//
//  TKUISemaphoreView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 11.12.17.
//

import Foundation

import RxSwift
import RxCocoa

/// An annotation that can be displayed using TripKitUI's `TKUISemaphoreView`
/// or just as a point on the map.
public protocol TKUISemaphoreDisplayable: TKUIImageAnnotation {
  var semaphoreMode: TKUISemaphoreView.Mode { get }
  var bearing: NSNumber? { get }
  var canFlipImage: Bool { get }
  var imageIsTemplate: Bool { get }
  var isTerminal: Bool { get }
  var selectionIdentifier: String? { get }
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
  
  @objc(canDisplayAnnotation:)
  public static func canDisplay(_ annotation: MKAnnotation) -> Bool {
    return annotation is TKUISemaphoreDisplayable
  }
  
  @objc
  public func observe(_ annotation: MKAnnotation) {
    self.objcDisposeBag = TKUIObjCDisposeBag()
    
    guard annotation is NSObject, annotation is TKUISemaphoreDisplayable else { return }

    NotificationCenter.default.rx.notification(.TKUIUpdatedRealTimeData, object: annotation)
      .filter { $0.object is TKUISemaphoreDisplayable }
      .map { ($0.object as? TKUISemaphoreDisplayable)?.semaphoreMode }
      .bind(to: rx.mode)
      .disposed(by: objcDisposeBag.disposeBag)
  }

  @objc
  static func isRealTime(_ annotation: MKAnnotation) -> Bool {
    if let displayable = annotation as? TKUISemaphoreDisplayable, case .headWithTime(_, _, let isRealTime) = displayable.semaphoreMode {
      return isRealTime
    } else {
      return false
    }
  }
  
  /// :nodoc:
  @objc(accessibilityImageViewForDisplayable:)
  public static func accessibilityImageView(for displayable: TKTripSegmentDisplayable) -> UIImageView? {
    let accessibility = displayable.tripSegmentWheelchairAccessibility
    
    // Not using `accessibility.showInUI()` as it's a bit much to show the
    // not accessible icons for all users here.
    guard accessibility != .unknown, accessibility.showInUI() else { return nil }

    guard let image = accessibility.miniIcon else { return nil }
    let imageView = UIImageView(image: image)
    imageView.tintColor = .tkLabelPrimary
    imageView.accessibilityLabel = accessibility.title
    return imageView
  }

  @objc(updateForAnnotation:)
  public func update(for annotation: MKAnnotation) {
    self.update(for: annotation, heading: 0)
  }
  
  @objc(updateForAnnotation:withHeading:)
  public func update(for annotation: MKAnnotation, heading: CLLocationDirection) {
    self.annotation = annotation
    
    guard let semaphorable = annotation as? TKUISemaphoreDisplayable else { return }
    
    let image = semaphorable.image
    let imageURL = semaphorable.imageURL
    let asTemplate = semaphorable.imageIsTemplate
    let bearing = semaphorable.bearing
    let terminal = semaphorable.isTerminal
    let canFlip = imageURL == nil && semaphorable.canFlipImage == true
    
    setHeadWith(image, imageURL: imageURL, imageIsTemplate: asTemplate, forBearing: bearing, andHeading: heading, inRed: terminal, canFlipImage: canFlip)
  }
  
  public func updateSelection(for identifier: String?) {
    guard let displayable = annotation as? TKUISemaphoreDisplayable else { return }
    guard let target = identifier else { alpha = 1; return }
    
    let selected = displayable.selectionIdentifier == target
    alpha = selected ? 1 : 0.3
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
    if displayable.canFlipImage && displayable.imageURL == nil {
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
    // This doesn't adjust to dark-mode on purpose as the head-image isn't ready for that yet
    return customHeadTintColor ?? .black
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

extension Reactive where Base == TKUISemaphoreView {
  
  var mode: Binder<TKUISemaphoreView.Mode?> {
    return Binder(self.base) { semaphore, mode in
      if case .headWithTime(let time, let timeZone, let realTime)? = mode {
        semaphore.setTime(time, isRealTime: realTime, in: timeZone, onSide: semaphore.label)
      } else {
        semaphore.setTime(nil, isRealTime: false, in: .current, onSide: semaphore.label)
      }
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
