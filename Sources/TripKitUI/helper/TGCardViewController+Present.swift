//
//  TGCardViewController+Present.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 10.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import TGCardViewController

// MARK: - Navigation helpers

extension TGCardViewController {
  
  @objc
  func dismissNavigator() {
    dismiss(animated: true)
  }
  
  public func present(_ controller: UIViewController, inNavigator: Bool, includeDone: Bool = true, preferredStyle: UIModalPresentationStyle = .popover, sender: Any? = nil) {
    
    let presentee = inNavigator ? UINavigationController(rootViewController: controller) : controller
    let actualStyle = (sender is UIView || sender is UIBarButtonItem) ? preferredStyle : .formSheet
    
    if inNavigator && actualStyle != .popover, includeDone {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissNavigator))
      controller.navigationItem.leftBarButtonItem = doneButton
    }
    
    if traitCollection.horizontalSizeClass == .regular {
      presentee.modalPresentationStyle = actualStyle
      let presentation = presentee.popoverPresentationController
      if let view = sender as? UIView {
        presentation?.sourceView = view
        presentation?.sourceRect = view.bounds
      } else if let barButton = sender as? UIBarButtonItem {
        presentation?.barButtonItem = barButton
      } else {
        presentation?.sourceView = view
      }
    } else {
      presentee.modalPresentationStyle = actualStyle
    }
    present(presentee, animated: true)
    
  }
  
}
