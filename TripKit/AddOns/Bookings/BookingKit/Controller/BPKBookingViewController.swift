//
//  BPKbookingViewController.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 16/2/17.
//
//

import Foundation

extension BPKBookingViewController {
  
  // MARK: - Error alert
  
  @objc public func handle(_ error: Error, defaultDismissHandler: ((UIAlertAction) -> Void)? = nil) {
    guard let serverKitError = error as? TKError else {
      BPKAlert.present(in: self, title: nil, message: error.localizedDescription)
      return
    }
    
    guard
      let recovery = serverKitError.recovery,
      let title = recovery.title,
      let url = recovery.url
      else {
        BPKAlert.present(in: self, title: serverKitError.title, message: error.localizedDescription, actions: nil, defaultDismissHandler: defaultDismissHandler)
        return
    }
    
    let recoveryAction = UIAlertAction(title: title, style: .default) { [unowned self] _ in
      if let option = recovery.option, case .back = option {
        self.replace(with: url)
      } else {
        self.load(url)
      }
    }
    
    let cancel = UIAlertAction(title: Loc.Cancel, style: .default) { [unowned self] _ in
      self.dismiss(animated: true, completion: nil)
    }
    
    // Only include Contact support when the delegate method is available.
    if let responder = self.delegate?.contactSupportHandler,
       let handler = responder(self) {
      let contact = UIAlertAction(title: Loc.ContactSupport, style: .default) { _ in
        handler()
      }
      BPKAlert.present(in: self, title: serverKitError.title, message: serverKitError.localizedDescription, actions: [recoveryAction, contact, cancel])
    } else {
      BPKAlert.present(in: self, title: serverKitError.title, message: serverKitError.localizedDescription, actions: [recoveryAction, cancel])
    }
  }
  
  // MARK: - Loading forms
  
  @objc public func load(_ url: URL, data: [String : AnyObject]? = nil) {
    let nextFormCtr = BPKBookingViewController(booking: url, postData: data)
    load(nextFormCtr)
  }
  
  @objc public func load(_ rawForm: [String : AnyObject]) {
    guard
      BPKForm.canBuild(fromRawObject: rawForm)
      else {
        assertionFailure("Cannot construct a form from raw object")
        return
    }
    
    let form = BPKForm(json: rawForm)
    let nextFormCtr = BPKBookingViewController(form: form)
    load(nextFormCtr)
  }
  
  fileprivate func load(_ nextFormCtr: BPKBookingViewController) {
    nextFormCtr.manager = manager
    nextFormCtr.delegate = delegate
    nextFormCtr.progressText = form.actionText() ?? ""
    navigationController?.pushViewController(nextFormCtr, animated: true)
  }
  
  @objc public func replace(with url: URL) {
    guard var currentStack = navigationController?.viewControllers else {
      assertionFailure("Booking forms are expected to be presented inside a navigation controller")
      return
    }
    
    let replacementCtr = BPKBookingViewController(booking: url)
    
    if currentStack.count == 1 {
      currentStack[0] = replacementCtr
    } else {
      currentStack.removeLast()
      currentStack[currentStack.count - 1] = replacementCtr
    }
    
    navigationController?.setViewControllers(currentStack, animated: true)
  }
  
}
