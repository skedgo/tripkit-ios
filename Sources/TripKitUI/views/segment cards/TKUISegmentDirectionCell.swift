//
//  TKUISegmentDirectionCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUISegmentDirectionCell: UITableViewCell {
  
  static let reuseIdentifier = "TKUISegmentDirectionCell"
  static let nib = UINib(nibName: "TKUISegmentDirectionCell", bundle: .tripKitUI)

  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var bubbleStack: UIStackView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    contentView.backgroundColor = .clear
    durationLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    durationLabel.textColor = .tkLabelPrimary
    nameLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    nameLabel.textColor = .tkLabelSecondary
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
  }
  
  override var frame: CGRect {
    didSet {
      bubbleStack?.arrangedSubviews.forEach { $0.layer.cornerRadius = $0.bounds.height / 2 }
    }
  }
  
  func setBubbles(_ bubbles: [(String, UIColor)]) {
    bubbleStack.arrangedSubviews.forEach(bubbleStack.removeArrangedSubview)
    bubbleStack.subviews.forEach { $0.removeFromSuperview() }

    let views = bubbles.map { text, color -> UIView in
      let wrapper = UIView(frame: .init(x: 0, y: 0, width: 50, height: 16))
      wrapper.translatesAutoresizingMaskIntoConstraints = false
      wrapper.backgroundColor = color
      wrapper.layer.cornerRadius = 8 // will get fixed if necessary
      
      let label = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 16))
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = TKStyleManager.customFont(forTextStyle: .caption1)
      label.text = text
      label.textColor = color.isDark ? .white : .black
      
      wrapper.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 8),
        label.topAnchor.constraint(equalTo: wrapper.topAnchor),
        wrapper.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
        wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor),
      ])
      
      return wrapper
    }
    
    views.forEach(bubbleStack.addArrangedSubview(_:))
  }
    
}
