//
//  TGCardController+ShowError.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 05.11.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

extension UIViewController {
  public func showErrorAsAlert(_ error: Error, title: String? = nil) {
    let alertController = UIAlertController(title: title ?? Loc.Error, message: error.localizedDescription, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: Loc.OK, style: .cancel, handler: nil))
    present(alertController, animated: true)
  }
}

extension TGCardViewController {
  public func show(_ error: Error, title: String? = nil) {
    self.showErrorAsAlert(error, title: title)
  }
}
