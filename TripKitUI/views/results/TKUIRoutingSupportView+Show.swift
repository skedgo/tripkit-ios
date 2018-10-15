//
//  TKUIRoutingSupportView+Show.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension TKUIRoutingSupportView {
  
  public static func clear(from view: UIView) {
    view.subviews
      .filter { $0 is TKUIRoutingSupportView }
      .forEach { $0.removeFromSuperview() }
  }

  public static func show(
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
    supportView.backgroundColor = TKStyleManager.backgroundColorForTileList()
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
    let font = UIFont.systemFont(ofSize: 16, weight: .medium)
    
    // Build the final string
    let text = Loc.RoutingFrom(fromAddress, toIsNotYetSupported: toAddress)
    let message = NSMutableAttributedString(string: text)
    
    let attributes = [ .foregroundColor: UIColor(red: 77/255.0, green: 77/255.0, blue: 77/255.0, alpha: 1.0),
                       .font: font ] as [NSAttributedString.Key : Any]
    
    let fromRange = (text as NSString).range(of: fromAddress)
    message.addAttributes(attributes, range: fromRange)
    
    let toRange = (text as NSString).range(of: toAddress)
    message.addAttributes(attributes, range: toRange)
    
    return message
  }
  
}
