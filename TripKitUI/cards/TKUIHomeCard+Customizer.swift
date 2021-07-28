//
//  TKUIHomeCard+Customizer.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 18/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
  
  static let TKUIHomeComponentsCustomized = Notification.Name("TKUIHomeComponentsCustomized")

}


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
    
    fileprivate func save() {
      UserDefaults.standard.set(!isEnabled, forKey: "home-hide.\(id)")
    }
  }
  
  public static func hideComponent(id: String) {
    UserDefaults.standard.set(true, forKey: "home-hide.\(id)")
    NotificationCenter.default.post(name: .TKUIHomeComponentsCustomized, object: nil)
  }
  
  static func sortedAsInDefaults(_ items: [CustomizedItem]) -> [CustomizedItem] {
    guard let preferred = UserDefaults.standard.array(forKey: "home-order") as? [String] else { return items }
    return items.sorted { one, two in
      (preferred.firstIndex(of: one.id) ?? 0) < (preferred.firstIndex(of: two.id) ?? 0)
    }
  }
  
  static func saveSorting(ids: [String]) {
    UserDefaults.standard.set(ids, forKey: "home-order")
    NotificationCenter.default.post(name: .TKUIHomeComponentsCustomized, object: nil)
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
    TKUIHomeCard.saveSorting(ids: items.map(\.id)) // this notifies, too
    
    controller.dismiss(animated: true)
  }
}
