//
//  TKUIAlertInfoView.swift
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

@available(*, unavailable, renamed: "TKUIAlertInfoView")
public typealias TKAlertInfoView = TKUIAlertInfoView


public class TKUIAlertInfoView: UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var instructionLabel: UILabel!
  
  
  /// Indicating whether the alert info view is currently showing the full
  /// content or only the title.
  private(set) var isShowingFullContent = true
  
  
  /// The alert used to configure the alert info view. Specifically, the
  /// `title` and `text` properties will be used by the titleLabel and
  /// instructionLabel respectively.
  ///
  public var alert: TKAlert? {
    didSet {
      guard let alert = alert else { return }
      titleLabel.text = alert.title
      instructionLabel.text = alert.text
    }
  }
  
  
  /// Create a new instance of TKUIAlertInfoView, with title & instruction labels
  /// set to default texts.
  ///
  /// - Returns: An instance of TKUIAlertInfoView.
  public class func newInstance() -> TKUIAlertInfoView {
    return Bundle.tripKitUI.loadNibNamed("TKUIAlertInfoView", owner: self, options: nil)!.first as! TKUIAlertInfoView
  }
  
  
  /// Create a new instance of TKUIAlertInfoView based on an alert. That is, the
  /// title and instruction labels set their `text` property to the alert's 
  /// title and text properties respectively.
  ///
  /// - Parameter alert: An alert instance used to configure title and instruction labels.
  /// - Returns: An instance of TKUIAlertInfoView
  public class func newInstance(with alert: TKAlert) -> TKUIAlertInfoView {
    let view = newInstance()
    view.alert = alert
    return view
  }
  
  
  /// Asks the alert info view to show only its title, i.e., hide the instruction
  /// portion of the view.
  public func showTitleOnly(maxY: CGFloat) {
    guard superview != nil, isShowingFullContent else { return }
    let bottomPadding: CGFloat
    if #available(iOSApplicationExtension 11.0, *) {
      bottomPadding = safeAreaInsets.bottom
    } else {
      bottomPadding = 0
    }
    frame.origin.y = maxY - bottomPadding - instructionLabel.frame.minY
    isShowingFullContent = false
  }
  
  
  /// Ask the alert info view to show its entire content, including both title
  /// and instruction.
  public func showFullContent(maxY: CGFloat) {
    guard superview != nil, !isShowingFullContent else { return }

    let bottomPadding: CGFloat
    if #available(iOSApplicationExtension 11.0, *) {
      bottomPadding = safeAreaInsets.bottom
    } else {
      bottomPadding = 0
    }
    frame.origin.y = maxY - bottomPadding - frame.height
    isShowingFullContent = true
  }
  
  
  /// Toggles the alert info view betwen showing title only or full content.
  public func toggle(maxY: CGFloat) {
    isShowingFullContent ? showTitleOnly(maxY: maxY) : showFullContent(maxY: maxY)
  }
  
  
  /// Asks the alert info view to size itself so that it just fits the
  /// containing view. Note that, this method is usually called before
  /// the alert view is inserted into the containing view, especially 
  /// so when the containing view isn't implemented using auto layout.
  ///
  /// - Parameter containingView: The view in which the alert info view will appear.
  public func sizeToFitContent(within containingView: UIView) {
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

