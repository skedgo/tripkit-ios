//
//  TKUIRoutingSupportView+Show.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

extension TKUIRoutingSupportView {
  
  static func clear(from view: UIView) {
    view.subviews
      .filter { $0 is TKUIRoutingSupportView }
      .forEach { $0.removeFromSuperview() }
  }

  static func show(
    with error: Error,
    for request: TripRequest? = nil,
    in view: UIView,
    aboveSubview: UIView? = nil,
    topPadding: CGFloat = 0,
    allowRequest: Bool
  ) -> TKUIRoutingSupportView {
    // Start fresh
    clear(from: view)
    
    let message = buildPrefilledSupportMessage(for: request) ?? NSAttributedString(string: error.localizedDescription)
    
    let supportView = TKUIRoutingSupportView.makeView(with: message, allowRoutingRequest: allowRequest)
    supportView.backgroundColor = .tkBackground
    supportView.translatesAutoresizingMaskIntoConstraints = false
    if let above = aboveSubview {
      view.insertSubview(supportView, aboveSubview: above)
    } else {
      view.addSubview(supportView)
    }
    
    supportView.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding).isActive = true
    supportView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    view.trailingAnchor.constraint(equalTo: supportView.trailingAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: supportView.bottomAnchor).isActive = true
    
    return supportView
  }
  
  private static func buildPrefilledSupportMessage(for request: TripRequest?) -> NSAttributedString? {
    guard
      let fromAddress = request?.fromLocation.address,
      let toAddress = request?.toLocation.address else {
        return nil
    }
    
    // Set attributes
    let font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    
    // Build the final string
    let text = Loc.RoutingFrom(fromAddress, toIsNotYetSupported: toAddress)
    let message = NSMutableAttributedString(string: text)
    
    let attributes: [NSAttributedString.Key : Any] = [
      .foregroundColor: UIColor.tkLabelPrimary,
                 .font: font
    ]
    
    let fromRange = (text as NSString).range(of: fromAddress)
    message.addAttributes(attributes, range: fromRange)
    
    let toRange = (text as NSString).range(of: toAddress)
    message.addAttributes(attributes, range: toRange)
    
    return message
  }
  
}
