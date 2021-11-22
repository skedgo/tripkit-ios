//
//  TKUISheet.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

open class TKUISheet: UIView {

  public var overlayColor: UIColor = .tkNeutral4
  
  private var overlay: UIView? = nil

  public var isBeingOverlaid: Bool { overlay != nil }
  
  private var originalAccessibilityElements: [Any]? = nil
  
  private var dismissHandler: (() -> Void)?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public func showWithOverlay(in view: UIView, below: UIView? = nil, hiding: [UIView] = [], onDismiss handler: (() -> Void)? = nil) {
    if let existing = view.subviews.compactMap({ $0 as? TKUISheet }).first {
      existing.removeOverlay(animated: false)
    }
    
    overlay?.removeFromSuperview()
    
    self.dismissHandler = handler
    
    // add a background
    let overlay = makeOverlay(view.bounds)
    self.overlay = overlay
    
    // determine start and end positions for sheet
    frame.size.width = view.frame.width
    frame.origin.y = view.frame.maxY - view.frame.minY
    
    var endFrame = self.frame
    endFrame.origin.y -= endFrame.height
    
    autoresizingMask = .flexibleTopMargin
    view.addSubview(self)
    view.insertSubview(overlay, belowSubview: self)
    
    originalAccessibilityElements = view.accessibilityElements
    view.accessibilityElements = [self]
    
    // animate it in
    UIView.animate(withDuration: 0.25) {
      overlay.alpha = 1
      self.frame = endFrame
    } completion: { _ in
      UIAccessibility.post(notification: .screenChanged, argument: self)
    }
  }
  
  private func makeOverlay(_ frame: CGRect) -> UIView {
    let overlay = UIView(frame: frame)
    overlay.autoresizingMask = .flexibleHeight
    overlay.backgroundColor = self.overlayColor
    overlay.alpha = 0
    let tapper = UITapGestureRecognizer(target: self, action: #selector(tappedOverlay(_:)))
    overlay.addGestureRecognizer(tapper)
    
    // don't interact with overlay (or what's below)
    overlay.isAccessibilityElement = false

    return overlay
  }
  
  @objc
  func tappedOverlay(_ sender: Any) {
    removeOverlay(animated: true)
  }
  
  public func removeOverlay(animated: Bool) {
    guard let overlay = self.overlay, let superview = overlay.superview else { return }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        overlay.alpha = 0
        self.frame.origin.y += self.frame.size.height
      } completion: { finished in
        if finished {
          superview.accessibilityElements = self.originalAccessibilityElements
          self.originalAccessibilityElements = nil

          overlay.removeFromSuperview()
          self.overlay = nil
          self.removeFromSuperview()
          self.dismissHandler?()
        } else {
          overlay.alpha = 1
        }
      }
    } else {
      superview.accessibilityElements = self.originalAccessibilityElements
      self.originalAccessibilityElements = nil

      overlay.removeFromSuperview()
      self.overlay = nil
      self.removeFromSuperview()
      dismissHandler?()
    }
  }
  
}
