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
  private var directionsWrapper: UIView?
  
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
  
  func hideDirectionButton(_ hide: Bool) {
    directionsWrapper?.isHidden = hide
  }
  
  private func didInit() {
    // The hierarchy
    let searchBar = UISearchBar()
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.searchBarStyle = .minimal
    
    let directionsButton = UIButton(type: .custom)
    directionsButton.translatesAutoresizingMaskIntoConstraints = false
    directionsButton.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond.fill"), for: .normal)
    directionsButton.tintColor = .white
    directionsButton.backgroundColor = .tkAppTintColor
    directionsButton.layer.cornerRadius = 16
    
    let directionsWrapper = UIView()
    directionsWrapper.backgroundColor = .clear
    directionsWrapper.translatesAutoresizingMaskIntoConstraints = false
    self.directionsWrapper = directionsWrapper
    
    directionsWrapper.addSubview(directionsButton)
    NSLayoutConstraint.activate([
      directionsWrapper.widthAnchor.constraint(equalToConstant: 44),
      directionsButton.widthAnchor.constraint(equalToConstant: 32),
      directionsButton.heightAnchor.constraint(equalTo: directionsButton.widthAnchor),
      directionsWrapper.centerYAnchor.constraint(equalTo: directionsButton.centerYAnchor),
      directionsWrapper.centerXAnchor.constraint(equalTo: directionsButton.centerXAnchor),
    ])
    
    let stackedViews: [UIView] = [searchBar, directionsWrapper]
    
    let stackView = UIStackView(arrangedSubviews: stackedViews)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.spacing = 0
    
    addSubview(stackView)
    
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
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

