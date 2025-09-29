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
    
    let hStack = UIStackView(arrangedSubviews: [searchBar, directionsWrapper])
    hStack.translatesAutoresizingMaskIntoConstraints = false
    hStack.axis = .horizontal
    hStack.spacing = 0

    addSubview(hStack)
    
    if let prompt {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
      label.text = prompt
      addSubview(label)

      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
        trailingAnchor.constraint(equalTo: hStack.trailingAnchor, constant: 10),

        label.topAnchor.constraint(equalTo: topAnchor, constant: 0),
        hStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
        bottomAnchor.constraint(equalTo: hStack.bottomAnchor),
      ])

    } else {
      NSLayoutConstraint.activate([
        hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
        hStack.topAnchor.constraint(equalTo: topAnchor, constant: hasGrabHandle ? -10 : 0), // negative spacer to minimise gap to grab handle
        trailingAnchor.constraint(equalTo: hStack.trailingAnchor, constant: 10),
        bottomAnchor.constraint(equalTo: hStack.bottomAnchor),
      ])
    }
    
    self.searchBar = searchBar
    self.directionsButton = directionsButton
    
    searchBar.tintColor = .tkAppTintColor
    searchBar.barTintColor = .tkBackground
  }
  
}

