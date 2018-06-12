//
//  TKAlertInfoView.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 23/9/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

#if TK_NO_MODULE
#else
  import TripKit
#endif

@objc
public class TKAlertInfoView: UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var instructionLabel: UILabel!
  
  
  /// Indicating whether the alert info view is currently showing the full
  /// content or only the title.
  private(set) var isShowingFullContent = true
  
  
  /// The alert used to configure the alert info view. Specifically, the
  /// `title` and `text` properties will be used by the titleLabel and
  /// instructionLabel respectively.
  ///
  @objc public var alert: TKAlert? {
    didSet {
      guard let alert = alert else { return }
      titleLabel.text = alert.title
      instructionLabel.text = alert.text
    }
  }
  
  
  /// Create a new instance of TKAlertInfoView, with title & instruction labels
  /// set to default texts.
  ///
  /// - Returns: An instance of TKAlertInfoView.
  @objc public class func newInstance() -> TKAlertInfoView {
    return Bundle.tripKitUI.loadNibNamed("TKAlertInfoView", owner: self, options: nil)!.first as! TKAlertInfoView
  }
  
  
  /// Create a new instance of TKAlertInfoView based on an alert. That is, the
  /// title and instruction labels set their `text` property to the alert's 
  /// title and text properties respectively.
  ///
  /// - Parameter alert: An alert instance used to configure title and instruction labels.
  /// - Returns: An instance of TKAlertInfoView
  @objc public class func newInstance(with alert: TKAlert) -> TKAlertInfoView {
    let view = newInstance()
    view.alert = alert
    return view
  }
  
  
  /// Asks the alert info view to show only its title, i.e., hide the instruction
  /// portion of the view.
  @objc public func showTitleOnly() {
    guard let superview = self.superview, isShowingFullContent else { return }
    let topPadding: CGFloat = 20
    let bottomPadding: CGFloat
    if #available(iOSApplicationExtension 11.0, *) {
      bottomPadding = safeAreaInsets.bottom
    } else {
      bottomPadding = 0
    }
    frame.origin.y = superview.frame.height - topPadding - bottomPadding - instructionLabel.frame.minY
    isShowingFullContent = false
  }
  
  
  /// Ask the alert info view to show its entire content, including both title
  /// and instruction.
  @objc public func showFullContent() {
    guard let superview = self.superview, !isShowingFullContent else { return }
    let topPadding: CGFloat = 20
    let bottomPadding: CGFloat
    if #available(iOSApplicationExtension 11.0, *) {
      bottomPadding = safeAreaInsets.bottom
    } else {
      bottomPadding = 0
    }
    frame.origin.y = superview.frame.height - topPadding - bottomPadding - instructionLabel.frame.maxY
    isShowingFullContent = true
  }
  
  
  /// Toggles the alert info view betwen showing title only or full content.
  @objc public func toggle() {
    isShowingFullContent ? showTitleOnly() : showFullContent()
  }
  
  
  /// Asks the alert info view to size itself so that it just fits the
  /// containing view. Note that, this method is usually called before
  /// the alert view is inserted into the containing view, especially 
  /// so when the containing view isn't implemented using auto layout.
  ///
  /// - Parameter containingView: The view in which the alert info view will appear.
  @objc public func sizeToFitContent(within containingView: UIView) {
    guard containingView.frame.width > 0 else {
      // If the containing view has zero width, a sign that layout is still in
      // progess, continuing on will produce a bunch of auto layout warnings.
      return
    }
    
    frame.size.width = containingView.frame.width
    
    // Perform a layout pass so that all subviews have the correct frames.
    setNeedsLayout()
    layoutIfNeeded()
    
    // This is the height that can just fit everything in the view.
    let fittingSize = systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    
    // Update the frame to assume fitting height.
    frame.size.height = fittingSize.height
  }
  
}

