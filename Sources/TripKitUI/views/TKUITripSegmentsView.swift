//
//  TKUITripSegmentsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import MapKit
import UIKit

import TripKit

public class TKUITripSegmentsView : UIView {
  
  /// Whether the trip should be shown as cancelled, i.e., with a line through it
  /// - default: `false`
  public var isCanceled: Bool = false
  
  @available(*, deprecated, message: "Accessibility icons are no longer shown")
  public var allowWheelchairIcon: Bool = false
  
  @available(*, deprecated, message: "Accessibility icons are no longer shown")
  public var allowBicycleAccessibilityIcon: Bool = false
  
  /// This property determines if the transit icon in the view should be color coded.
  public var colorCodingTransitIcon: Bool = false
  
  /// This color is used for darker texts. In addition, this is also the color which
  /// will be used to tint the transport mode icons if `colorCodingTransitIcon` is
  /// set to `false`.
  /// - default: `UIColor.tkLabelPrimary`
  public var darkTextColor: UIColor = .tkLabelPrimary
  
  /// This color is used on lighter texts. In addition, this is also the color which
  /// will be used to tint non-PT modes if `colorCodingTransitIcon` is set to `YES`.
  /// - default: `UIColor.tkLabelPrimary`
  public var lightTextColor: UIColor = .tkLabelPrimary
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  /// Shows the segments on one line, with chevrons between them. Transit
  /// segments get their route number and departure time as badges, other
  /// segments their title or distance. If that doesn't fit, it steps down to
  /// all route numbers with only the main segment's time, then only the main
  /// segment's route number and time, and finally only the mode icons. Non-
  /// transit segments of multi-modal trips always show their minutes.
  ///
  /// - Parameters:
  ///   - segments: Segments to display
  ///   - mainSegmentIndex: Index of the trip's main segment in `segments`. Defaults to the first segment with a fixed departure time.
  ///   - allowInfoIcons: Whether to show info icons, e.g., for alerts
  public func configure(_ segments: [TKUITripSegmentDisplayable], mainSegmentIndex: Int? = nil, allowInfoIcons: Bool = true) {
    self.mainSegmentIndex = mainSegmentIndex
    self.reconfigure = { [weak self] in
      self?.configure(segments, mainSegmentIndex: mainSegmentIndex, allowInfoIcons: allowInfoIcons)
    }
    configure(segments, details: .everything, allowInfoIcons: allowInfoIcons)
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
    let wasLaidOut = didLayoutSubviews
    didLayoutSubviews = true
    if let onLayout = self.onLayout {
      onLayout()
      self.onLayout = nil
    } else if wasLaidOut, frame.size != configuredSize, let reconfigure {
      // What fits depends on the size, which can change after configuring,
      // e.g., for table cells that were first laid out with their nib's size
      reconfigure()
    }
  }
  
  // MARK: - Constants
  
  private static let alphaSelected: CGFloat = 1
  private static let alphaDeselected: CGFloat = 0.25
  
  /// Space between the items of a segment, and around the chevrons
  private static let spacing: CGFloat = 4
  
  // MARK: - Internals
  
  private var desiredSize: CGSize = .zero
  private var didLayoutSubviews: Bool = false
  private var onLayout: (() -> Void)? = nil
  
  /// Re-applies the last call to the public `configure`, for when the size changed
  private var reconfigure: (() -> Void)? = nil
  
  /// The size for which the subviews were last laid out
  private var configuredSize: CGSize? = nil
  
  /// These are from the left, i.e., same for left-to-right and right-to-left
  private var segmentLeftyValues: [CGFloat] = []
  
  private var segmentIndexToSelect: Int? = nil
  
  /// See `configure(_:mainSegmentIndex:allowInfoIcons:)`
  private var mainSegmentIndex: Int? = nil
  
  /// Which details to show next to the mode icons, from the most to the least
  private enum Details: CaseIterable {
    /// Route number and time for every transit segment, title or distance for
    /// every other segment
    case everything
    
    /// Route number for every transit segment, but time, title or distance
    /// only for the main segment
    case allRoutesMainTime
    
    /// Route number and time, title or distance only for the main segment;
    /// other segments only show their mode icon
    case mainRouteAndTime
    
    /// Just the mode icons
    case icons
    
    var next: Details? {
      let all = Self.allCases
      guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
      return all[index + 1]
    }
  }
  
  private func configure(_ segments: [TKUITripSegmentDisplayable], details: Details, allowInfoIcons: Bool) {
    if !didLayoutSubviews {
      // When calling `configure` before `layoutSubviews` was called the frame
      // information of this view is most likely not yet what it'll be before
      // this view will be visible, so we'll delay configuring this view until
      // after `layoutSubviews` was called.
      self.onLayout = { [weak self] in
        self?.configure(segments, details: details, allowInfoIcons: allowInfoIcons)
      }
      return
    }

    subviews.forEach { $0.removeFromSuperview() }
    configuredSize = frame.size

    var accessibileElements: [UIAccessibilityElement] = []

    let limitSize = frame.size != .zero
    let maxHeight = limitSize ? frame.height : 44

    var newSegmentXValues: [CGFloat] = []
    let segmentIndexToSelect = self.segmentIndexToSelect.flatMap { $0 < segments.count ? $0 : nil }

    let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
    contentMode = isRightToLeft ? .right : .left
    autoresizingMask = isRightToLeft ? [.flexibleLeftMargin, .flexibleBottomMargin] : [.flexibleRightMargin, .flexibleBottomMargin]
    let mask = autoresizingMask

    let textFont = TKStyleManager.customFont(forTextStyle: .subheadline)
    let badgeFont = TKStyleManager.semiboldCustomFont(forTextStyle: .subheadline)

    let mainIndex = mainSegmentIndex ?? segments.firstIndex { $0.tripSegmentFixedDepartureTime != nil }
    
    var nextX: CGFloat = 0
    var maxX: CGFloat = 0
    var count = 0
    for (index, segment) in segments.enumerated() {
      let isSelected = (segmentIndexToSelect ?? count) == count
      let alpha = isSelected ? Self.alphaSelected : Self.alphaDeselected

      guard let modeImage = segment.tripSegmentModeImage else {
        continue // this can happen if a trip was visible while TripKit got cleared
      }

      var x = nextX

      /// Adds the view after the previous one, vertically centred
      func add(_ view: UIView, spacing: CGFloat = Self.spacing) {
        view.autoresizingMask = mask
        view.alpha = alpha
        view.frame.origin = .init(x: x + spacing, y: ((maxHeight - view.frame.height) / 2).rounded())
        addSubview(view)
        x = view.frame.maxX
      }

      func sized(_ imageView: UIImageView, height: CGFloat) -> UIImageView {
        guard let image = imageView.image, image.size.height > 0 else { return imageView }
        let viewHeight = min(image.size.height, height)
        imageView.frame.size = .init(width: viewHeight * image.size.width / image.size.height, height: viewHeight)
        return imageView
      }

      // 1. Chevron from the previous segment, which counts as part of this
      //    segment, e.g., for `selectSegment(atIndex:)`

      newSegmentXValues.append(x)
      if count > 0 {
        x = addChevron(x: x, maxHeight: maxHeight, alpha: alpha) + Self.spacing
      }
      let segmentMinX = x

      // 2. The mode and brand images, maybe with circled behind them, and info icon

      let (_, iconFrame) = addModeImages(for: segment, modeImage: modeImage, x: x, maxHeight: maxHeight, alpha: alpha, allowInfoIcons: allowInfoIcons)
      x = iconFrame.maxX
      
      let color = segment.tripSegmentModeColor
      let fixedTime = segment.tripSegmentFixedDepartureTime
      let isTransit = color != nil || fixedTime != nil
      
      // Minutes for walking, driving, etc., at the icon's bottom right, if
      // there are other segments, too, at every level of details
      if !isTransit, segments.count > 1, let duration = segment.tripSegmentDuration {
        let minutes = max(1, Int((duration / 60).rounded()))
        let label = TKUIStyledLabel()
        label.font = Self.minutesFont
        label.text = minutes.formatted()
        label.textColor = darkTextColor
        label.sizeToFit()
        label.autoresizingMask = mask
        label.alpha = alpha
        // Tucked into the walking icon's corner, as that image has some space
        // on its sides, but next to wider icons such as bicycles and cars
        let offset: CGFloat = segment.tripSegmentIsWalking ? -3 : 1
        label.frame.origin = .init(x: iconFrame.maxX + offset, y: (iconFrame.maxY - label.frame.height + 2).rounded())
        addSubview(label)
        // A bit more space, so that the minutes don't run into a distance
        x = label.frame.maxX + 2
      }

      // 3. Details: Route number and departure time for transit, otherwise
      //    the title or the distance

      let isMain = index == mainIndex
      let showRoute: Bool
      let showDetails: Bool
      switch details {
      case .everything:        (showRoute, showDetails) = (true, true)
      case .allRoutesMainTime: (showRoute, showDetails) = (true, isMain)
      case .mainRouteAndTime:  (showRoute, showDetails) = (isMain, isMain)
      case .icons:             (showRoute, showDetails) = (false, false)
      }

      let title = segment.tripSegmentModeTitle.flatMap { $0.isEmpty ? nil : $0 }
      let lineHeight = textFont.lineHeight

      if isTransit {
        if showRoute {
          if let title {
            let background = color ?? .tkLabelPrimary
            add(PillView(text: title, font: badgeFont, textColor: background.isDark ? .tkLabelOnDark : .tkLabelOnLight, backgroundColor: background))
          } else if let color {
            let dot = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
            dot.backgroundColor = color
            dot.layer.cornerRadius = 5
            add(dot)
          }

        }

        if showDetails, let fixedTime {
          let time = TKStyleManager.timeString(fixedTime, for: segment.tripSegmentTimeZone ?? .current)
          let realTime = segment.tripSegmentTimesAreRealTime ? UIImageView(asRealTimeAccessoryImageAnimated: true, tintColor: lightTextColor) : nil
          add(PillView(text: time, font: textFont, textColor: darkTextColor, borderColor: .tkSeparator, accessory: realTime))
        }

      } else if showDetails, let text = title ?? segment.tripSegmentDistanceInMetres.map(Self.distanceString) {
        let label = TKUIStyledLabel()
        label.font = textFont
        label.text = text
        label.textColor = darkTextColor
        label.sizeToFit()
        add(label)

        if segment.tripSegmentTimesAreRealTime {
          add(sized(UIImageView(asRealTimeAccessoryImageAnimated: true, tintColor: lightTextColor), height: lineHeight), spacing: 2)
        }
      }

      if showDetails, allowInfoIcons, let subtitleIcon = TKInfoIcon.image(for: segment.tripSegmentSubtitleIconType, usage: .overlay) {
        add(sized(UIImageView(image: subtitleIcon), height: lineHeight), spacing: 2)
      }

      let accessibleElement = UIAccessibilityElement(accessibilityContainer: self)
      accessibleElement.accessibilityLabel = segment.tripSegmentAccessibilityLabel
      accessibleElement.accessibilityFrameInContainerSpace = .init(x: segmentMinX, y: 0, width: x - segmentMinX, height: maxHeight)
      if segmentIndexToSelect != nil {
        accessibleElement.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
      }
      accessibileElements.append(accessibleElement)

      maxX = x
      nextX = x + Self.spacing
      count += 1
      if details == .everything {
        // Ask for the space for everything, even if we then show less
        desiredSize = .init(width: maxX, height: maxHeight)
      }

      if limitSize, maxX > frame.width, let fewer = details.next {
        configure(segments, details: fewer, allowInfoIcons: allowInfoIcons)
        return
      }
    }

    finishConfiguring(width: maxX, maxHeight: maxHeight, segmentXValues: newSegmentXValues, accessibilityElements: accessibileElements, segmentIndexToSelect: segmentIndexToSelect)
  }

  /// Adds the mode image, and maybe a brand image and an info icon on top
  ///
  /// - Returns: The mode image view and the frame covered by the images
  private func addModeImages(for segment: TKUITripSegmentDisplayable, modeImage: UIImage, x: CGFloat, maxHeight: CGFloat, alpha: CGFloat, allowInfoIcons: Bool) -> (UIImageView, CGRect) {
    let mask: UIView.AutoresizingMask = autoresizingMask

    let color = segment.tripSegmentModeColor
    let modeImageView = UIImageView(image: modeImage)
    modeImageView.autoresizingMask = mask
    modeImageView.alpha = alpha

    // remember that color will be nil for non-PT modes. In these cases, since the
    // PT mode will be colored, we use the lighter grey to reduce the contrast.
    modeImageView.tintColor = colorCodingTransitIcon ? (color ?? lightTextColor) : darkTextColor

    modeImageView.frame.origin.x = x
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
        // Remote images that aren't templates (e.g. the black "R"/"S" region
        // icons) are drawn as-is and can be invisible on the card's own
        // background, so keep a white backing circle behind them. Only remove
        // it if the image fails to load — the placeholder is shown then.
        let modeCircleBackground = asTemplate ? nil : addCircle(frame: newFrame)
        modeImageView.setImage(with: modeImageURL, asTemplate: asTemplate, placeholder: modeImage) { succeeded in
          if !succeeded { modeCircleBackground?.removeFromSuperview() }
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

    // Optional info icon
    if allowInfoIcons, let image = TKInfoIcon.image(for: segment.tripSegmentModeInfoIconType, usage: .overlay) {
      let infoIconImageView = UIImageView(image: image)
      infoIconImageView.autoresizingMask = mask
      infoIconImageView.frame.origin.x = newFrame.minX
      infoIconImageView.frame.origin.y = newFrame.maxY - image.size.height
      infoIconImageView.alpha = modeImageView.alpha
      addSubview(infoIconImageView)
    }

    return (modeImageView, newFrame)
  }

  /// Adds a chevron pointing to the next segment
  ///
  /// - Returns: The chevron's maximum x value
  private func addChevron(x: CGFloat, maxHeight: CGFloat, alpha: CGFloat) -> CGFloat {
    let chevron = UIImageView(image: Self.chevronImage)
    chevron.tintColor = .tkLabelTertiary
    chevron.sizeToFit()
    chevron.autoresizingMask = autoresizingMask
    chevron.alpha = alpha
    chevron.frame.origin = .init(x: x, y: ((maxHeight - chevron.frame.height) / 2).rounded())
    addSubview(chevron)
    return chevron.frame.maxX
  }
  
  private func finishConfiguring(width: CGFloat, maxHeight: CGFloat, segmentXValues: [CGFloat], accessibilityElements: [UIAccessibilityElement], segmentIndexToSelect: Int?) {
    if isCanceled {
      let lineHeight: CGFloat = 1
      let strikethrough = UIView(frame: .init(x: 0, y: (maxHeight - lineHeight) / 2, width: width, height: lineHeight))
      strikethrough.backgroundColor = darkTextColor
      addSubview(strikethrough)
    }

    if effectiveUserInterfaceLayoutDirection == .rightToLeft {
      for view in subviews {
        view.frame.origin.x = frame.width - view.frame.maxX
      }
    }

    self.segmentLeftyValues = segmentXValues

    if segmentIndexToSelect != nil {
      self.accessibilityElements = accessibilityElements
      self.isAccessibilityElement = false
    }
  }

  private static let minutesFont = TKStyleManager.semiboldCustomFont(forTextStyle: .caption2)
  
  private static let chevronImage: UIImage? = UIImage(
    systemName: "chevron.right",
    withConfiguration: UIImage.SymbolConfiguration(font: TKStyleManager.semiboldCustomFont(forTextStyle: .caption2))
  )?.imageFlippedForRightToLeftLayoutDirection()

  private static func distanceString(_ metres: Double) -> String {
    let formatter = MKDistanceFormatter()
    formatter.unitStyle = .abbreviated
    return formatter.string(fromDistance: metres)
  }

}

extension TKUITripSegmentsView {

  /// A rounded badge with a text and an optional accessory image
  fileprivate class PillView: UIView {

    private static let insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)

    private let borderColor: UIColor?

    init(text: String, font: UIFont, textColor: UIColor, backgroundColor: UIColor? = nil, borderColor: UIColor? = nil, accessory: UIImageView? = nil) {
      self.borderColor = borderColor
      super.init(frame: .zero)

      let insets = Self.insets
      let textSize = text.size(font: font)

      let label = TKUIStyledLabel(frame: .init(origin: .init(x: insets.left, y: insets.top), size: textSize))
      label.font = font
      label.text = text
      label.textColor = textColor
      addSubview(label)

      var width = insets.left + textSize.width + insets.right
      if let accessory, let image = accessory.image, image.size.height > 0 {
        let viewHeight = min(image.size.height, textSize.height)
        let viewWidth = viewHeight * image.size.width / image.size.height
        accessory.frame = .init(x: label.frame.maxX + 2, y: insets.top + (textSize.height - viewHeight) / 2, width: viewWidth, height: viewHeight)
        addSubview(accessory)
        width += 2 + viewWidth
      }

      frame.size = .init(width: width, height: insets.top + textSize.height + insets.bottom)
      self.backgroundColor = backgroundColor
      layer.cornerRadius = 6
      layer.cornerCurve = .continuous
      if borderColor != nil {
        layer.borderWidth = 1
        updateBorderColor()
      }
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      updateBorderColor()
    }

    private func updateBorderColor() {
      layer.borderColor = borderColor?.resolvedColor(with: traitCollection).cgColor
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
