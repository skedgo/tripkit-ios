//
//  TKUIHomeHeaderView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIHomeHeaderView: UIView {
  
  var searchBar: UISearchBar!
  var directionsButton: UIButton?
  
  private var stackView: UIStackView!
  
  private let hasGrabHandle: Bool

  init(hasGrabHandle: Bool) {
    self.hasGrabHandle = hasGrabHandle
    super.init(frame: .zero)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    self.hasGrabHandle = true
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    // The hierarchy
    let searchBar = UISearchBar()
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.searchBarStyle = .minimal
    
    let directionsButton: UIButton?
    if #available(iOS 14.0, *) {
      directionsButton = UIButton(type: .custom)
      directionsButton!.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond.fill"), for: .normal)
      directionsButton!.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    } else {
      directionsButton = nil // would be easy to add with right icon
    }
    
    let stackView = UIStackView(arrangedSubviews: [searchBar, directionsButton].compactMap { $0 })
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    
    addSubview(stackView)
    
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: hasGrabHandle ? -10 : 0), // negative spacer to minimise gap to grab handle
      trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 10),
      bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
    ])
    
    self.stackView = stackView
    self.searchBar = searchBar
    self.directionsButton = directionsButton
    
    // Styling
    searchBar.tintColor = .tkAppTintColor
    searchBar.barTintColor = .tkBackground

  }
  
}

