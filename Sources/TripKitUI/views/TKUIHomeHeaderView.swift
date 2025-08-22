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
    searchBar.tintColor = .tkAppTintColor
    searchBar.searchBarStyle = .minimal // No background *around* the search bar
    if #available(iOS 26.0, *) {
#if compiler(>=6.2) // Xcode 26 proxy
      searchBar.searchTextField.cornerConfiguration = .corners(radius: .containerConcentric(minimum: 22))
      searchBar.searchTextField.backgroundColor = .tkBackgroundNotClear
#endif
    } else {
      searchBar.barTintColor = .tkBackground
    }
    
    let directionButtonSize: CGFloat
    if #available(iOS 26.0, *) {
      directionButtonSize = 44
    } else {
      directionButtonSize = 32
    }
    let directionsButton = UIButton(type: .custom)
    directionsButton.translatesAutoresizingMaskIntoConstraints = false
    directionsButton.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond.fill"), for: .normal)
    directionsButton.tintColor = .white
    directionsButton.backgroundColor = .tkAppTintColor
    directionsButton.layer.cornerRadius = directionButtonSize / 2
    
    let directionsWrapper = UIView()
    directionsWrapper.backgroundColor = .clear
    directionsWrapper.translatesAutoresizingMaskIntoConstraints = false
    self.directionsWrapper = directionsWrapper
    
    directionsWrapper.addSubview(directionsButton)
    NSLayoutConstraint.activate([
      directionsWrapper.widthAnchor.constraint(equalToConstant: 44),
      directionsButton.widthAnchor.constraint(equalToConstant: directionButtonSize),
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

    let padding: UIEdgeInsets  // negative spacer on top to minimise gap to grab handle
    if #available(iOS 26.0, *) {
      padding = UIEdgeInsets(top: hasGrabHandle ? -6 : 8, left: 14, bottom: 0, right: 20)
    } else {
      padding = UIEdgeInsets(top: hasGrabHandle ? -10 : 0, left: 6, bottom: 0, right: 10)
    }
    
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
      trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: padding.right),
      bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: padding.bottom),
    ])
    
    self.stackView = stackView
    self.searchBar = searchBar
    self.directionsButton = directionsButton
  }
  
}

