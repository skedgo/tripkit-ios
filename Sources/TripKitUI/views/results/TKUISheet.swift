//
//  TKUISheet.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

@available(iOS, deprecated: 26.0, message: "Use sheet presentations.")
open class TKUISheet: UIView {

  public var overlayColor: UIColor = .tkNeutral4
  
  private var overlay: UIView?
  
  public var isBeingOverlaid: Bool { overlay != nil }
  
  private var bottomConstraint: NSLayoutConstraint?

  private var originalAccessibilityElements: [Any]?
  
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
    
    // add a background, disable accessibility of anything that's hidden by it
    
    let overlay = makeOverlay(view.bounds)
    self.overlay = overlay
    
    originalAccessibilityElements = view.accessibilityElements
    view.accessibilityElements = [self]
    
    // First, position where it's supposed to go

    view.addSubview(self)
    view.insertSubview(overlay, belowSubview: self)

    self.translatesAutoresizingMaskIntoConstraints = false
    let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
    self.bottomConstraint = bottomConstraint
    
    NSLayoutConstraint.activate([
      bottomConstraint,
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])

    bottomConstraint.constant = 0
    view.setNeedsUpdateConstraints()
    view.layoutIfNeeded()

    // Then, animate it in from below
    
    let endFrame = frame
    frame.origin.y += frame.height
    UIView.animate(withDuration: 0.25) {
      overlay.alpha = 1
      self.frame = endFrame
    } completion: { _ in
      UIAccessibility.post(notification: .screenChanged, argument: self)
    }

    // track keyboard, in case that the sheet content brings it up
    
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    
    func onDismissal() {
      superview.accessibilityElements = originalAccessibilityElements
      originalAccessibilityElements = nil

      overlay.removeFromSuperview()
      self.overlay = nil
      removeFromSuperview()
      NotificationCenter.default.removeObserver(self)
      dismissHandler?()
    }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        overlay.alpha = 0
        self.frame.origin.y += self.frame.size.height
      } completion: { finished in
        if finished {
          onDismissal()
        } else {
          overlay.alpha = 1
        }
      }
    } else {
      onDismissal()
    }
  }
  
  // MARK: - Responding to Keyboard Appearance
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard
      let bottomConstraint = self.bottomConstraint,
      let info = notification.userInfo,
      let size = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size,
      let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    else { return }

    bottomConstraint.constant = size.height
    setNeedsUpdateConstraints()
    
    UIView.animate(withDuration: duration) {
      self.superview?.layoutIfNeeded()
    }
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard
      let bottomConstraint = self.bottomConstraint,
      let info = notification.userInfo,
      let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    else { return }

    
    bottomConstraint.constant = 0
    setNeedsUpdateConstraints()
    
    UIView.animate(withDuration: duration) {
      self.superview?.layoutIfNeeded()
    }
  }
  
}
