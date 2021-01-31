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

public class TKUISemaphoreView: _TKUISemaphoreView {
  public enum Mode: Equatable {
    case headWithTime(Date, TimeZone, isRealTime: Bool)
    case headWithFrequency(minutes: Int)
    case headOnly

    /// Whether this point should ideally be displayed using the style of
    /// `TKUISemaphoreView` rather than just a flat image.
    case none
  }
  
  private var disposeBag = DisposeBag()
  private var isFlipped = false
  
  private weak var modeImageView: UIImageView!
  
  public init(annotation: MKAnnotation, reuseIdentifier: String?, withHeading heading: CLLocationDirection = 0) {
    
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    
    let headSize = 48 // size of the head images
    let width = headSize
    let height = 58 // bottom of semaphore to top of head
    let baseHeadOverlap = 18
    
    frame = .init(x: 0, y: 0, width: width, height: height)
    
    wrapper = UIView(frame: frame)
    wrapper.backgroundColor = .clear
    addSubview(wrapper)
    
    let base = UIImageView(image: TripKitUIBundle.imageNamed("map-pin-base"))
    base.center.x += 16
    base.center.y += CGFloat(headSize - baseHeadOverlap)
    wrapper.addSubview(base)
    
    update(for: annotation, heading: heading)
    
    layer.anchorPoint = .init(x: 0.5, y: 1)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = .init()
    isFlipped = false
    modeImageView?.removeFromSuperview()
    modeImageView = nil
  }
  
  public override var annotation: MKAnnotation? {
    didSet {
      if let new = annotation, new !== oldValue {
        observe(new)
      }
    }
  }
  
  public override var timeBackgroundImage: UIImage? {
    TripKitUIBundle.imageNamed("map-pin-time")
  }
  
  public override func accessoryImageView(forRealTime isRealTime: Bool, showFrequency: Bool) -> UIImageView? {
    if isRealTime {
      return UIImageView(asRealTimeAccessoryImageAnimated: true, tintColor: .white)
    } else if showFrequency {
      return UIImageView(image: TripKitUIBundle.imageNamed("repeat_icon"))
    } else {
      return nil
    }
  }
}

// MARK:

extension TKUISemaphoreView {
  
  private func observe(_ annotation: MKAnnotation) {
    self.disposeBag = .init()
    
    guard annotation is NSObject, annotation is TKUISemaphoreDisplayable else { return }

    NotificationCenter.default.rx.notification(.TKUIUpdatedRealTimeData, object: annotation)
      .filter { $0.object is TKUISemaphoreDisplayable }
      .map { ($0.object as? TKUISemaphoreDisplayable)?.semaphoreMode }
      .bind(to: rx.mode)
      .disposed(by: disposeBag)
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

  public func update(for annotation: MKAnnotation?) {
    self.update(for: annotation, heading: 0)
  }
  
  func update(for annotation: MKAnnotation?, heading: CLLocationDirection) {
    self.annotation = annotation
    
    guard let semaphorable = annotation as? TKUISemaphoreDisplayable else { return }
    
    let image = semaphorable.image
    let imageURL = semaphorable.imageURL
    let asTemplate = semaphorable.imageIsTemplate
    let bearing = semaphorable.bearing
    let terminal = semaphorable.isTerminal
    let canFlip = imageURL == nil && semaphorable.canFlipImage == true
    
    let headImage: UIImage
    let headTintColor: UIColor
    if bearing != nil {
      headImage = Self.pointerImage
      headTintColor = Self.headTintColor
    } else if terminal {
      headImage = TripKitUIBundle.imageNamed("map-pin-head-red")
      headTintColor = .white
    } else {
      headImage = Self.headImage
      headTintColor = Self.headTintColor
    }
    
    let totalBearing: CLLocationDirection = (bearing?.doubleValue ?? 0) - heading
    let headImageView = UIImageView(image: headImage)
    headImageView.frame = .init(
      x: (frame.width - headImage.size.width) / 2,
      y: 0,
      width: headImage.size.width,
      height: headImage.size.height
    )
    
    if bearing != nil {
      headImageView.rotate(bearing: CGFloat(totalBearing))
    }
    
    wrapper.addSubview(headImageView)
    self.headImageView = headImageView
    
    // Add the mode image
    if let image = image {
      let modeImageView = UIImageView(image: image)
      modeImageView.frame = .init(
        x: (frame.width - image.size.width) / 2,
        y: (headImage.size.height - image.size.height) / 2,
        width: image.size.width,
        height: image.size.height
      )
      modeImageView.tintColor = headTintColor

      modeImageView.setImage(with: imageURL, asTemplate: asTemplate, placeholder: image)
      
      if canFlip, totalBearing > 180 || totalBearing < 0 {
        modeImageView.transform = modeImageView.transform.scaledBy(x: -1, y: 1)
        isFlipped = true
      } else {
        isFlipped = false
      }
      
      wrapper.addSubview(modeImageView)
      self.modeImageView = modeImageView
    }
  }
  
  public func updateSelection(for identifier: String?) {
    guard let displayable = annotation as? TKUISemaphoreDisplayable else { return }
    guard let target = identifier else { alpha = 1; return }
    
    let selected = displayable.selectionIdentifier == target
    alpha = selected ? 1 : 0.3
  }
  
  func rotateHead(magneticHeading: CLLocationDirection) {
    guard let bearing = (annotation as? TKUISemaphoreDisplayable)?.bearing?.floatValue else { return }
    updateHead(magneticHeading: magneticHeading, bearing: CLLocationDirection(bearing))
  }
  

  func updateHead(magneticHeading: CLLocationDirection, bearing: CLLocationDirection) {
    headImageView?.update(magneticHeading: CGFloat(magneticHeading), bearing: CGFloat(bearing))
    
    guard let displayable = (annotation as? TKUISemaphoreDisplayable) else { return }
    if displayable.canFlipImage && displayable.imageURL == nil {
      let totalBearing = bearing - magneticHeading
      let flip = totalBearing > 180 || totalBearing < 0
      self.flipHead(flip)
    } else {
      self.flipHead(false)
    }
  }
  
  private func flipHead(_ flip: Bool) {
    if flip, !isFlipped {
      modeImageView.transform = modeImageView.transform.scaledBy(x: -1, y: 1)
      isFlipped = true
    } else if !flip, isFlipped {
      modeImageView.transform = .identity
      isFlipped = false
    }
  }
  
}

// MARK: Customisation

extension TKUISemaphoreView {
  
  @objc public static var customHeadTintColor: UIColor? = nil
  @objc public static var customHeadImage: UIImage? = nil
  @objc public static var customPointerImage: UIImage? = nil

  static var headTintColor: UIColor {
    // This doesn't adjust to dark-mode on purpose as the head-image isn't ready for that yet
    return customHeadTintColor ?? .black
  }
  
  static var headImage: UIImage {
    if let custom = customHeadImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-head")
    }
  }

  static var pointerImage: UIImage {
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
