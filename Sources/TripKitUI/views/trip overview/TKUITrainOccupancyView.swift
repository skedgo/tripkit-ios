//
//  TKUITrainOccupancyView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 21.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import UIKit

import TripKit

class TKUITrainOccupancyView: UIView {
  
  private weak var stack: UIStackView!
  
  // MARK: - Initialisers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  // Setup
  
  private func didInit() {
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.alignment = .leading
    stack.distribution = .fill
    stack.spacing = 2

    addSubview(stack)
    self.stack = stack
    
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

  }
  
  // Configuring with content
  
  var occupancies: [[TKAPI.VehicleOccupancy]] = [[]] {
    didSet {
      self.updateStack()
    }
  }
  
  private func updateStack() {
    stack.arrangedSubviews.forEach(stack.removeArrangedSubview)
    stack.subviews.forEach { $0.removeFromSuperview() }
    
    for outer in occupancies {
      for (index, inner) in outer.enumerated() {
        let imageName: String
        switch index {
        case 0: imageName = "icon-train-last-carriage"
        case ..<(outer.count-1): imageName = "icon-train-carriage"
        default: imageName = "icon-train-head"
        }
        let image = TripKitUIBundle.imageNamed(imageName)
        let imageView = UIImageView(image: image)
        imageView.tintColor = inner.color ?? .tkLabelTertiary
        stack.addArrangedSubview(imageView)
      }
    }
  }
  
}
