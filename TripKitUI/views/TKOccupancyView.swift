//
//  TKOccupancyView.swift
//  Pods
//
//  Created by Kuan Lun Huang on 31/10/2016.
//
//

import UIKit

public struct TKOccupancyInfo {
  public let text: String
  public let icon: UIImage?
  public let color: UIColor
  public let isCritical: Bool
  
  public init(text: String, icon: UIImage?, color: UIColor, isCritical: Bool) {
    self.text = text
    self.icon = icon
    self.color = color
    self.isCritical = isCritical
  }
}

@available(iOSApplicationExtension 8.2, *)

public class TKOccupancyView: UIView {
  
  public weak var icon: UIImageView!
  public weak var label: UILabel!
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  public var occupancyInfo: TKOccupancyInfo? {
    didSet {
      guard let info = occupancyInfo else { return }
      
      icon.image = info.icon
      icon.tintColor = UIColor.white
      icon.backgroundColor = info.color
      label.text = info.text.uppercased()
      
      if info.isCritical {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = info.color
        icon.layer.cornerRadius = 0
        label.textColor = UIColor.white
      } else {
        icon.layer.cornerRadius = 8
        label.textColor = info.color
      }
    }
  }
  
  // Setup
  
  private func didInit() {
    let icon = UIImageView()
    icon.contentMode = .center
    icon.translatesAutoresizingMaskIntoConstraints = false
    addSubview(icon)
    self.icon = icon
    
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 10, weight: UIFontWeightSemibold)
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    self.label = label
    
    if #available(iOSApplicationExtension 9.0, *) {
      icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
      icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
      icon.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      icon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
      icon.topAnchor.constraint(equalTo: topAnchor).isActive = true
      
      label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4).isActive = true
      label.centerYAnchor.constraint(equalTo: icon.centerYAnchor).isActive = true
      label.heightAnchor.constraint(equalTo: icon.heightAnchor).isActive = true
      trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8).isActive = true
    } else {
      // Constraints on icon
      let widthConstraint = NSLayoutConstraint(item: icon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 16)
      let heightConstraint = NSLayoutConstraint(item: icon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 16)
      let iconLeadingSpace = NSLayoutConstraint(item: icon, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
      let iconCenterY = NSLayoutConstraint(item: icon, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
      let topSpace = NSLayoutConstraint(item: icon, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
      addConstraints([widthConstraint, heightConstraint, iconLeadingSpace, iconCenterY, topSpace])
      
      // Constraints on label
      let labelLeadingSpace = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: icon, attribute: .trailing, multiplier: 1, constant: 4)
      let labelCenterY = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: icon, attribute: .centerY, multiplier: 1, constant: 0)
      let labelHeight = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: icon, attribute: .height, multiplier: 1, constant: 0)
      let trailingSpace = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: label, attribute: .trailing, multiplier: 1, constant: 8)
      addConstraints([labelLeadingSpace, labelCenterY, labelHeight, trailingSpace])
    }
  }

}
