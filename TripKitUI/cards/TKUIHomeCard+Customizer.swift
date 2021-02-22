//
//  TKUIHomeCard+Customizer.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 18/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKUIHomeCard {
  struct CustomizedItem {
    init(fromUserDefaultsWithId id: String, item: TKUIHomeCardCustomizerItem) {
      self.id = id
      self.item = item
      self.isEnabled = !UserDefaults.standard.bool(forKey: "home-hide.\(id)")
    }
    
    let id: String
    let item: TKUIHomeCardCustomizerItem
    var isEnabled: Bool
    
    func save() {
      UserDefaults.standard.set(!isEnabled, forKey: "home-hide.\(id)")
    }
  }
}

extension TKUIHomeCard {
  
  @available(iOS 13.0, *)
  func showCustomizer(items: [TKUIHomeCard.CustomizedItem]) {
    guard let controller = controller else { return assertionFailure() }
    let customizer = TKUIHomeCardCustomizationViewController(items: items)
    customizer.delegate = self
    
    let wrapper = UINavigationController(rootViewController: customizer)
    controller.present(wrapper, animated: true)
  }
  
}

@available(iOS 13.0, *)
extension TKUIHomeCard: TKUIHomeCardCustomizationViewControllerDelegate {

  func customizer(_ controller: TKUIHomeCardCustomizationViewController, completed items: [CustomizedItem]) {
    guard let controller = self.controller else { return assertionFailure() }
    
    items.forEach { $0.save() }
    
    customizationTriggered.onNext(items)
    
    controller.dismiss(animated: true)
  }
}
