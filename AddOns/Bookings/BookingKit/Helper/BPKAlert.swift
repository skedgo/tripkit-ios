//
//  BPKAlertHelper.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 16/2/17.
//
//

import UIKit

//import SGCoreKit

public class BPKAlert: NSObject {
  
  @objc public class func present(in vc: UIViewController, title: String?, message: String, actions: [UIAlertAction]? = nil) {
    let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    if let provided = actions {
      provided.forEach { alertVC.addAction($0) }
    } else {
      // provide a default OK.
      let ok = UIAlertAction(title: Loc.OK, style: .default, handler: nil)
      alertVC.addAction(ok)
    }
    
    vc.present(alertVC, animated: true, completion: nil)
  }

}
