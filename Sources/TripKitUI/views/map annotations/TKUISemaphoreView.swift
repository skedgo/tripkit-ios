//
//  TKUISemaphoreView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 11.12.17.
//

import Foundation
import MapKit
import UIKit

import RxSwift
import RxCocoa

import TripKit

/// An annotation that can be displayed using TripKitUI's `TKUISemaphoreView`
/// or just as a point on the map.
public protocol TKUISemaphoreDisplayable: TKUIImageAnnotation, TKUISelectableOnMap {
  var bearing: NSNumber? { get }
  var imageIsTemplate: Bool { get }
  var isTerminal: Bool { get }
  var semaphoreMode: TKUISemaphoreView.Mode { get }
}

extension TKUISemaphoreDisplayable {
  public var selectionIdentifier: String? { nil }
  
  public var isTerminal: Bool { false }
  
  public var selectionCondition: TKUISelectionCondition { .ifSelectedOrNoSelection }
}

public class TKUISemaphoreView: MKAnnotationView {
  public enum LabelSide {
    case onLeft
    case onRight
    
    public static var defaultDirection: LabelSide {
      switch Locale.current.language.lineLayoutDirection {
      case .rightToLeft: return .onLeft
      default: return .onRight
      }
    }
  }
  
  public enum Mode: Equatable {
    case headWithTime(Date, TimeZone, isRealTime: Bool)
    case headWithFrequency(minutes: Int)
    case headOnly
  }
  
  private let wrapper: UIView!
  private var headImageView: UIImageView?
  private var timeImageView: UIImageView?
  fileprivate var label: LabelSide? = nil
  
  private var disposeBag = DisposeBag()
  private var isFlipped = false
  
  private weak var modeImageView: UIImageView!
  
  public convenience override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    self.init(annotation: annotation, reuseIdentifier: reuseIdentifier, withHeading: 0)
  }
  
  public init(annotation: MKAnnotation?, reuseIdentifier: String?, withHeading heading: CLLocationDirection = 0) {
    let headSize = 48 // size of the head images
    let width = headSize
    let height = 58 // bottom of semaphore to top of head
    let baseHeadOverlap = 18
    
    let frame = CGRect(x: 0, y: 0, width: width, height: height)
    wrapper = UIView(frame: frame)
    wrapper.backgroundColor = .clear

    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

    self.frame = frame
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
    configure(.headOnly, side: .defaultDirection)
    disposeBag = .init()
    isFlipped = false
    modeImageView?.semanticContentAttribute = .unspecified
    modeImageView?.removeFromSuperview()
    modeImageView = nil
    headImageView?.removeFromSuperview()
    headImageView = nil
    timeImageView?.removeFromSuperview()
    timeImageView = nil
    label = nil

    super.prepareForReuse()
  }
  
  public override var annotation: MKAnnotation? {
    didSet {
      if let new = annotation, new !== oldValue {
        observe(new)
      }
    }
  }
  
  func configure(_ mode: Mode?, side: LabelSide) {
    guard let headImageView = self.headImageView else { return assertionFailure() }
    
    timeImageView?.removeFromSuperview()
    timeImageView = nil

    // disable the label and the side, if there's no time
    switch mode {
    case .headOnly, nil: label = nil
    case .headWithFrequency, .headWithTime: label = side
    }
    
    guard label != nil, let mode = mode else { return }
    
    let timeLabel = UILabel()
    timeLabel.backgroundColor = .clear
    timeLabel.font = TKStyleManager.systemFont(size: 14)
    timeLabel.textColor = .white
    
    let headSize: CGFloat = 48 // size of the head images
    let verticalPadding: CGFloat = 4
    let horizontalPadding: CGFloat = 10
    let baseHeadOverlap: CGFloat = 18

    let accessoryImageView: UIImageView?
    switch mode {
    case let .headWithFrequency(frequency):
      timeLabel.text = Date.durationString(forMinutes: frequency)
      accessoryImageView = UIImageView(image: TripKitUIBundle.imageNamed("repeat_icon"))
    case let .headWithTime(time, timeZone, isRealTime):
      timeLabel.text = TKStyleManager.timeString(time, for: timeZone)
      accessoryImageView = isRealTime ? UIImageView(asRealTimeAccessoryImageAnimated: true, tintColor: .white) : nil
    case .headOnly:
      timeLabel.text = ""
      return
    }
    
    let textSize = timeLabel.textRect(forBounds: .init(x: 0, y: 0, width: 80, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 1).size
    
    let timeImageView = UIImageView(image: TripKitUIBundle.imageNamed("map-pin-time"))
    self.timeImageView = timeImageView
    
    let timeViewHeight = textSize.height + verticalPadding * 2
    var timeViewWidth = textSize.width + baseHeadOverlap + horizontalPadding * 2
    var timeViewX = label == .onLeft ? -(textSize.width + horizontalPadding) : baseHeadOverlap
    var timeLabelX = horizontalPadding
    if label == .onRight {
      timeLabelX += baseHeadOverlap
    }
    
    if let imageView = accessoryImageView {
      var imageViewX = horizontalPadding
      if label == .onRight {
        imageViewX += baseHeadOverlap
      }
      let imageSize = CGSize(width: 14, height: 14)
      imageView.frame.size = imageSize
      imageView.frame.origin.x = imageViewX
      imageView.frame.origin.y = (timeViewHeight - imageSize.height) / 2
      
      // make space for the image
      let space = imageSize.width + horizontalPadding / 3
      timeViewWidth += space
      timeLabelX += space
      if label == .onLeft {
        timeViewX -= space
      }
      timeImageView.addSubview(imageView)
    }
    
    timeLabel.frame.origin.x = timeLabelX
    timeLabel.frame.origin.y = verticalPadding
    timeLabel.frame.size = textSize
    timeImageView.frame = .init(x: timeViewX, y: (headSize - timeViewHeight) / 2, width: timeViewWidth, height: timeViewHeight)
    timeImageView.addSubview(timeLabel)
    wrapper.insertSubview(timeImageView, belowSubview: headImageView)
  }
}

// MARK:

extension TKUISemaphoreView {
  
  private func observe(_ annotation: MKAnnotation) {
    self.disposeBag = .init()
    
    guard annotation is NSObject, annotation is TKUISemaphoreDisplayable else { return }

    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: annotation)
      .observe(on: MainScheduler.instance)
      .filter { $0.object is TKUISemaphoreDisplayable }
      .map { ($0.object as? TKUISemaphoreDisplayable)?.semaphoreMode }
      .bind(to: rx.mode)
      .disposed(by: disposeBag)
  }

  static func accessibilityImageView(for displayable: TKUITripSegmentDisplayable) -> UIImageView? {
    let wheelchair = displayable.tripSegmentWheelchairAccessibility
    
    // Not using `accessibility.showInUI()` as it's a bit much to show the
    // not accessible icons for all users here.
    if wheelchair != .unknown, wheelchair.showInUI(), let image = wheelchair.miniIcon {
      let imageView = UIImageView(image: image)
      imageView.tintColor = .tkLabelPrimary
      imageView.accessibilityLabel = wheelchair.title
      return imageView
    }
    
    if let bicycle = displayable.tripSegmentBicycleAccessibility, bicycle.showInUI(), let image = bicycle.miniIcon {
      let imageView = UIImageView(image: image)
      imageView.tintColor = .tkLabelPrimary
      imageView.accessibilityLabel = bicycle.title
      return imageView
    }
    
    return nil
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
    let canFlip = imageURL == nil
    
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
        modeImageView.semanticContentAttribute = .forceRightToLeft
        isFlipped = true
      } else {
        modeImageView.semanticContentAttribute = .forceLeftToRight
        isFlipped = false
      }
      
      wrapper.addSubview(modeImageView)
      self.modeImageView = modeImageView
    }
  }

  
  func rotateHead(magneticHeading: CLLocationDirection) {
    guard let bearing = (annotation as? TKUISemaphoreDisplayable)?.bearing?.floatValue else { return }
    updateHead(magneticHeading: magneticHeading, bearing: CLLocationDirection(bearing))
  }
  

  func updateHead(magneticHeading: CLLocationDirection, bearing: CLLocationDirection) {
    headImageView?.update(magneticHeading: CGFloat(magneticHeading), bearing: CGFloat(bearing))
    
    guard let displayable = (annotation as? TKUISemaphoreDisplayable) else { return }
    if displayable.imageURL == nil {
      let totalBearing = bearing - magneticHeading
      let flip = totalBearing > 180 || totalBearing < 0
      self.flipHead(flip)
    } else {
      self.flipHead(false)
    }
  }
  
  private func flipHead(_ flip: Bool) {
    guard let modeImageView = modeImageView else { return }
    
    if flip, !isFlipped {
      modeImageView.semanticContentAttribute = .forceRightToLeft
      isFlipped = true
    } else if !flip, isFlipped {
      modeImageView.semanticContentAttribute = .forceLeftToRight
      isFlipped = false
    }
  }
  
}

// MARK: Customisation

extension TKUISemaphoreView {
  
  public static var customHeadTintColor: UIColor? = nil
  public static var customHeadImage: UIImage? = nil
  public static var customPointerImage: UIImage? = nil

  private static var headTintColor: UIColor {
    // This doesn't adjust to dark-mode on purpose as the head-image isn't ready for that yet
    return customHeadTintColor ?? .black
  }
  
  private static var headImage: UIImage {
    if let custom = customHeadImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-head")
    }
  }

  private static var pointerImage: UIImage {
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
      semaphore.configure(mode, side: semaphore.label ?? .defaultDirection)
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
