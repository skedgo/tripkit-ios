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
  public func showErrorAsAlert(_ error: Error) {
    let alertController = UIAlertController(title: Loc.Error, message: error.localizedDescription, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: Loc.OK, style: .cancel, handler: nil))
    present(alertController, animated: true)
  }
}

extension TGCardViewController {
  public func show(_ error: Error) {
    self.showErrorAsAlert(error)
  }
}
