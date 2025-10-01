//
//  TKUIHomeHeaderView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIHomeHeaderView: UIView {
  
  var searchBar: UISearchBar!
  var directionsButton: UIButton?
  
  private var directionsWrapper: UIView?
  
  private let hasGrabHandle: Bool
  private let prompt: String?

  init(hasGrabHandle: Bool, prompt: String? = nil) {
    self.hasGrabHandle = hasGrabHandle
    self.prompt = prompt
    super.init(frame: .zero)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    self.hasGrabHandle = true
    self.prompt = nil
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
    
    let hStack = UIStackView(arrangedSubviews: [searchBar, directionsWrapper])
    hStack.translatesAutoresizingMaskIntoConstraints = false
    hStack.axis = .horizontal
    hStack.spacing = 0

    addSubview(hStack)

    let padding: UIEdgeInsets  // negative spacer on top to minimise gap to grab handle
    if #available(iOS 26.0, *) {
      padding = UIEdgeInsets(top: hasGrabHandle ? -6 : 8, left: 14, bottom: 0, right: 20)
    } else {
      padding = UIEdgeInsets(top: hasGrabHandle ? -10 : 0, left: 6, bottom: 0, right: 10)
    }
    
    if let prompt {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
      label.text = prompt
      addSubview(label)

      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left + 6),
        trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: padding.left + 6),
        hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
        trailingAnchor.constraint(equalTo: hStack.trailingAnchor, constant: padding.right),

        label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
        hStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
        bottomAnchor.constraint(equalTo: hStack.bottomAnchor, constant: padding.bottom),
      ])

    } else {
      NSLayoutConstraint.activate([
        hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
        hStack.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
        trailingAnchor.constraint(equalTo: hStack.trailingAnchor, constant: padding.right),
        bottomAnchor.constraint(equalTo: hStack.bottomAnchor, constant: padding.bottom),
      ])
    }
    
    self.searchBar = searchBar
    self.directionsButton = directionsButton
    
    searchBar.tintColor = .tkAppTintColor
    searchBar.barTintColor = .tkBackground
  }
  
}

