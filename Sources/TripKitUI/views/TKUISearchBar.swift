//
//  TKUISearchBar.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 3/9/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A search bar that keeps its cancel button usable after the keyboard got dismissed
///
/// `UISearchBar` disables the cancel button as soon as the search bar stops being the
/// first responder, assuming that you only ever leave editing through that button. That
/// doesn't hold when the results below dismiss the keyboard on drag, as the cancel
/// button then stays visible but dead: tapping it falls through to the search bar
/// itself, which brings the keyboard back up rather than leaving search mode.
class TKUISearchBar: UISearchBar {

  override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }

  private func didInit() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleDidEndEditing),
      name: UITextField.textDidEndEditingNotification, object: searchTextField
    )
  }

  @objc private func handleDidEndEditing() {
    // UIKit disables the button *after* this fires, so wait for it to be done.
    DispatchQueue.main.async { [weak self] in
      guard let self, showsCancelButton else { return }
      cancelButton?.isEnabled = true
    }
  }

  /// The cancel button, which UIKit doesn't expose; `nil` if it isn't currently shown
  /// or if we can't find it in the view hierarchy.
  private var cancelButton: UIButton? {
    func firstButton(in view: UIView) -> UIButton? {
      for subview in view.subviews where subview !== searchTextField {
        if let button = subview as? UIButton {
          return button
        } else if let button = firstButton(in: subview) {
          return button
        }
      }
      return nil
    }

    // Everything but the cancel button lives inside the text field, e.g., the
    // clear button.
    return firstButton(in: self)
  }

}
