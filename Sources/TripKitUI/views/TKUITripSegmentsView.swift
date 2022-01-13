//
//  TKUITripSegmentsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

public class TKUITripSegmentsView : UIView {
  
  /// Whether the trip should be shown as cancelled, i.e., with a line through it
  /// - default: `false`
  public var isCanceled: Bool = false
  
  /// Whether to show wheelchair accessibility and inaccessibility icons
  /// - default: `false`
  public var allowWheelchairIcon: Bool = false
  
  /// This property determines if the transit icon in the view should be color coded.
  public var colorCodingTransitIcon: Bool = false
  
  /// This color is used for darker texts. In addition, this is also the color which
  /// will be used to tint the transport mode icons if `colorCodingTransitIcon` is
  /// set to `false`.
  /// - default: `UIColor.tkLabelPrimary`
  public var darkTextColor: UIColor = .tkLabelPrimary
  
  /// This color is used on lighter texts. In addition, this is also the color which
  /// will be used to tint non-PT modes if `colorCodingTransitIcon` is set to `YES`.
  /// - default: `UIColor.tkLabelSecondary`
  public var lightTextColor: UIColor = .tkLabelSecondary
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public func configure(_ segments: [TKUITripSegmentDisplayable], allowSubtitles: Bool = true, allowInfoIcons: Bool = true) {
    configure(segments, allowTitles: allowSubtitles, allowSubtitles: allowSubtitles, allowInfoIcons: allowInfoIcons)
  }
  
  public func selectSegment(atIndex index: Int) {
    segmentIndexToSelect = index
    guard index >= 0, index < segmentLeftyValues.count else { return }
    
    let minX = segmentLeftyValues[index]
    let maxX = index + 1 < segmentLeftyValues.count ? segmentLeftyValues[index + 1] : .greatestFiniteMagnitude
    let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
    for view in subviews {
      let midX = isRightToLeft ? bounds.width - view.frame.midX : view.frame.midX
      view.alpha = midX >= minX && midX < maxX ? Self.alphaSelected : Self.alphaDeselected
    }
  }
  
  public func segmentIndex(atX x: CGFloat) -> Int {
    let target = effectiveUserInterfaceLayoutDirection == .leftToRight ? x : bounds.width - x
    return segmentLeftyValues.lastIndex { $0 <= target } ?? 0
  }
  
  public override var intrinsicContentSize: CGSize {
    if desiredSize == .zero, let onLayout = self.onLayout {
      didLayoutSubviews = true
      onLayout()
      self.onLayout = nil
    }
    return desiredSize
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    didLayoutSubviews = true
    if let onLayout = self.onLayout {
      onLayout()
      self.onLayout = nil
    }
  }
  
  // MARK: - Constants
  
  private static let alphaSelected: CGFloat = 1
  private static let alphaDeselected: CGFloat = 0.25
  private static let padding: CGFloat = 12
  
  // MARK: - Internals
  
  private var desiredSize: CGSize = .zero
  private var didLayoutSubviews: Bool = false
  private var onLayout: (() -> Void)? = nil
  
  /// These are from the left, i.e., same for left-to-right and right-to-left
  private var segmentLeftyValues: [CGFloat] = []
  
  private var segmentIndexToSelect: Int? = nil
  
  private func configure(_ segments: [TKUITripSegmentDisplayable], allowTitles: Bool, allowSubtitles: Bool, allowInfoIcons: Bool) {
    if !didLayoutSubviews {
      // When calling `configureForSegments` before `layoutSubviews` was called
      // the frame information of this view is most likely not yet what it'll
      // be before this view will be visible, so we'll delay configuring this view
      // until after `layoutSubviews` was called.
      self.onLayout = { [weak self] in
        self?.configure(segments, allowTitles: allowTitles, allowSubtitles: allowSubtitles, allowInfoIcons: allowInfoIcons)
      }
      return
    }
    
    subviews.forEach { $0.removeFromSuperview() }

    var accessibileElements: [UIAccessibilityElement] = []
    
    var nextX = Self.padding / 2
    
    // We might not yet have a frame, if the Auto Layout engine wants to get the
    // intrinsic size of this view, before it's been added. In that case, we
    // let it grow as big as it wants to be.
    let limitSize = frame.size != .zero
    let maxHeight = limitSize ? frame.height : 44
    
    var newSegmentXValues: [CGFloat] = []
    let segmentIndexToSelect = self.segmentIndexToSelect.flatMap { $0 < segments.count ? $0 : nil }
    
    let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
    contentMode = isRightToLeft ? .right : .left
    autoresizingMask = isRightToLeft ? [.flexibleLeftMargin, .flexibleBottomMargin] : [.flexibleRightMargin, .flexibleBottomMargin]
    
    var count = 0
    for segment in segments {
      let mask: UIView.AutoresizingMask = autoresizingMask
      let isSelected = (segmentIndexToSelect ?? count) == count
      let alpha = isSelected ? Self.alphaSelected : Self.alphaDeselected
      
      guard let modeImage = segment.tripSegmentModeImage else {
        continue // this can happen if a trip was visible while TripKit got cleared
      }
      
      // 1. The mode and brand images, maybe with circled behind them
      
      let color = segment.tripSegmentModeColor
      let modeImageView = UIImageView(image: modeImage)
      modeImageView.autoresizingMask = mask
      modeImageView.alpha = alpha
      
      // remember that color will be nil for non-PT modes. In these cases, since the
      // PT mode will be colored, we use the lighter grey to reduce the contrast.
      modeImageView.tintColor = colorCodingTransitIcon ? (color ?? lightTextColor) : darkTextColor
      
      newSegmentXValues.append(nextX)
      modeImageView.frame.origin.x = nextX
      modeImageView.frame.origin.y = (maxHeight - modeImage.size.height) / 2
      
      var newFrame = modeImageView.frame
      
      var brandImageView: UIImageView? = nil
      if let modeImageURL = segment.tripSegmentModeImageURL {
        let asTemplate = segment.tripSegmentModeImageIsTemplate
        
        @discardableResult
        func addCircle(frame: CGRect) -> UIView {
          let circleFrame = frame.insetBy(dx: -1, dy: -1)
          let modeCircleBackground = UIView(frame: circleFrame)
          modeCircleBackground.autoresizingMask = mask
          modeCircleBackground.backgroundColor = .white
          modeCircleBackground.layer.cornerRadius = circleFrame.width / 2
          modeCircleBackground.alpha = alpha
          addSubview(modeCircleBackground)
          return modeCircleBackground
        }
        
        if segment.tripSegmentModeImageIsBranding {
          var brandFrame = newFrame
          brandFrame.origin.x += brandFrame.width + 4
          
          // Always add a circle first as these look weird on background color
          addCircle(frame: brandFrame)
          
          // brand images are not overlaid over the mode icon, but appear next
          // to them
          let brandImage = UIImageView(frame: brandFrame)
          brandImage.autoresizingMask = mask
          brandImage.alpha = alpha
          brandImage.setImage(with: modeImageURL, asTemplate: false)
          brandImageView = brandImage
          newFrame = brandFrame

        } else {
          // remote images that aren't templates look weird on the background colour
          let modeCircleBackground = asTemplate ? nil : addCircle(frame: newFrame)
          modeImageView.setImage(with: modeImageURL, asTemplate: asTemplate, placeholder: modeImage) { succeeded in
            guard succeeded else { return }
            modeCircleBackground?.removeFromSuperview()
          }
        }
        if !asTemplate {
          // add a little bit more spacing next to the circle background
          newFrame.origin.x += 2
        }
      }
      
      addSubview(modeImageView)
      if let brandImageView = brandImageView {
        addSubview(brandImageView)
      }
      
      // 2. Optional info icon
      if allowInfoIcons, let image = TKInfoIcon.image(for: segment.tripSegmentModeInfoIconType, usage: .overlay) {
        let infoIconImageView = UIImageView(image: image)
        infoIconImageView.autoresizingMask = mask
        infoIconImageView.frame.origin.x = newFrame.minX
        infoIconImageView.frame.origin.y = newFrame.maxY - image.size.height
        infoIconImageView.alpha = modeImageView.alpha
        addSubview(infoIconImageView)
      }
      
      // we put mode codes, colours and subtitles to the side
      // subtitle, we are allowed to
      var modeSideWith: CGFloat = 0
      let x = newFrame.maxX
      var modeSubtitleSize = CGSize.zero
      let modeTitleFont = TKStyleManager.customFont(forTextStyle: .caption1)
      let modeSubtitleFont = TKStyleManager.customFont(forTextStyle: .caption2)
      
      let modeTitle = allowTitles ? segment.tripSegmentModeTitle.flatMap { $0.isEmpty ? nil : $0 } : nil
      let modeTitleSize = modeTitle?.size(font: modeTitleFont)
        ?? color.map { _ in .init(width: 10, height: 10) }
        ?? .zero
      
      let modeTitleAccessoryImageView = allowTitles && allowWheelchairIcon ? TKUISemaphoreView.accessibilityImageView(for: segment) : nil
 
      var modeSubtitle: String? = nil
      var modeSubtitleAccessoryImageViews: [UIImageView] = []
      if allowSubtitles {
        // We prefer the time + real-time indicator as the subtitle, and fall back
        // to the subtitle
        if let fixedTime = segment.tripSegmentFixedDepartureTime {
          modeSubtitle = TKStyleManager.timeString(fixedTime, for: segment.tripSegmentTimeZone)
        }
        if segment.tripSegmentTimesAreRealTime {
          modeSubtitleAccessoryImageViews.append(UIImageView(asRealTimeAccessoryImageAnimated: true, tintColor: lightTextColor))
        }
        if modeSubtitle == nil, let subtitle = segment.tripSegmentModeSubtitle, !subtitle.isEmpty {
          modeSubtitle = subtitle
        }
        if let subtitle = modeSubtitle {
          modeSubtitleSize = subtitle.size(font: modeSubtitleFont)
        }
        if allowInfoIcons, let subtitleIcon = TKInfoIcon.image(for: segment.tripSegmentSubtitleIconType, usage: .overlay) {
          modeSubtitleAccessoryImageViews.append(UIImageView(image: subtitleIcon))
        }
      }
      
      if let modeTitle = modeTitle {
        var y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2
        if modeSubtitleSize.height > 0 || !modeSubtitleAccessoryImageViews.isEmpty {
          y += 2
        }
        let label = TKUIStyledLabel(frame: .init(origin: .init(x: x + 2, y: y), size: modeTitleSize))
        label.autoresizingMask = mask
        label.font = modeTitleFont
        label.text = modeTitle
        label.textColor = colorCodingTransitIcon ? lightTextColor : darkTextColor
        label.alpha = modeImageView.alpha
        addSubview(label)
        modeSideWith = max(modeSideWith, modeTitleSize.width)
      
      } else if allowSubtitles, let color = color {
        let y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2
        let stripe = UIView(frame: .init(origin: .init(x: x, y: y), size: modeTitleSize))
        stripe.autoresizingMask = mask
        stripe.layer.borderColor = color.cgColor
        stripe.layer.borderWidth = modeTitleSize.width / 4
        stripe.layer.cornerRadius = modeTitleSize.width / 2
        stripe.alpha = modeImageView.alpha
        addSubview(stripe)
        modeSideWith = max(modeSideWith, modeTitleSize.width)
      }
      
      if let accessoryImageView = modeTitleAccessoryImageView, let accessoryImage = accessoryImageView.image {
        let viewHeight = modeTitleSize.height > 0
          ? min(accessoryImage.size.height, modeTitleSize.height)
          : min(accessoryImage.size.height, 20)
        let viewWidth = viewHeight * accessoryImage.size.width / accessoryImage.size.height
        
        var y = (maxHeight - modeSubtitleSize.height - viewHeight) / 2
        if modeSubtitleSize.height > 0 || !modeSubtitleAccessoryImageViews.isEmpty {
          y += 2
        }
        accessoryImageView.frame = .init(x: x + modeTitleSize.width + 2, y: y, width: viewWidth, height: viewHeight)
        accessoryImageView.alpha = modeImageView.alpha
        addSubview(accessoryImageView)
        modeSideWith = max(modeSideWith, modeTitleSize.width + 2 + viewWidth)
      }
      
      if let subtitle = modeSubtitle, !subtitle.isEmpty {
        // label goes under the mode code (if we have one)
        let y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2 + modeTitleSize.height
        let label = TKUIStyledLabel(frame: .init(origin: .init(x: x + 2, y: y), size: modeSubtitleSize))
        label.autoresizingMask = mask
        label.font = modeSubtitleFont
        label.text = subtitle
        label.textColor = lightTextColor
        label.alpha = modeImageView.alpha
        addSubview(label)
        modeSideWith = max(modeSideWith, modeSubtitleSize.width)
      }
      
      var subtitleWidth = modeSubtitleSize.width
      for imageView in modeSubtitleAccessoryImageViews {
        guard let image = imageView.image else { assertionFailure(); continue }
        imageView.autoresizingMask = mask
        let viewHeight = modeSubtitleSize.height > 0
          ? min(image.size.height, modeSubtitleSize.height)
          : min(image.size.height, 20)
        let viewWidth = viewHeight * image.size.width / image.size.height
        let y = (maxHeight - viewHeight - modeTitleSize.height) / 2 + modeTitleSize.height
        imageView.frame = .init(x: x + subtitleWidth + 2, y: y, width: viewWidth, height: viewHeight)
        imageView.alpha = modeImageView.alpha
        addSubview(imageView)
        modeSideWith = max(modeSideWith, subtitleWidth + 2 + viewWidth)
        subtitleWidth += 2 + viewWidth
      }
      
      newFrame.size.width += modeSideWith
      
      let accessibleElement = UIAccessibilityElement(accessibilityContainer: self)
      accessibleElement.accessibilityLabel = segment.tripSegmentAccessibilityLabel
      accessibleElement.accessibilityFrameInContainerSpace = newFrame
      if segmentIndexToSelect != nil {
        accessibleElement.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
      }
      accessibileElements.append(accessibleElement)
      
      nextX = newFrame.maxX + Self.padding
      count += 1
      if allowSubtitles {
        desiredSize = .init(width: nextX, height: maxHeight)
      }
      if limitSize, nextX > frame.width {
        // try to shrink
        if allowSubtitles {
          configure(segments, allowTitles: allowTitles, allowSubtitles: false, allowInfoIcons: allowInfoIcons)
          return
        } else if allowTitles {
          configure(segments, allowTitles: false, allowSubtitles: false, allowInfoIcons: allowInfoIcons)
          return
        }
      }
      
    }
    
    if isCanceled {
      let lineHeight: CGFloat = 1
      let strikethrough = UIView(frame: .init(x: 0, y: (maxHeight - lineHeight) / 2, width: nextX, height: lineHeight))
      strikethrough.backgroundColor = darkTextColor
      addSubview(strikethrough)
    }
        
    if isRightToLeft {
      for view in subviews {
        view.frame.origin.x = frame.width - view.frame.maxX
      }
    }

    self.segmentLeftyValues = newSegmentXValues
    
    if segmentIndexToSelect != nil {
      self.accessibilityElements = accessibileElements
      self.isAccessibilityElement = false
    }
  }
  
}

extension String {
  fileprivate func size(font: UIFont, maximumWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
    let context = NSStringDrawingContext()
    context.minimumScaleFactor = 1
    let box = (self as NSString).boundingRect(
      with: .init(width: maximumWidth, height: 0),
      options: .usesLineFragmentOrigin,
      attributes: [.font: font],
      context: context
    )
    return .init(
      width: box.width.rounded(.up),
      height: box.height.rounded(.up)
    )
  }
}
