//
//  TKOccupancyView.swift
//  Pods
//
//  Created by Kuan Lun Huang on 31/10/2016.
//
//

import UIKit

@available(iOS 8.2, *)
extension TKOccupancy {
  
  public var icon: UIImage? {
    switch self {
    case .empty, .manySeatsAvailable, .fewSeatsAvailable:
      return UIImage(named: "icon-check-mini", in: TKOccupancyView.bundle, compatibleWith: nil)
    case .standingRoomOnly, .crushedStandingRoomOnly:
      return UIImage(named: "icon-exclamation-mark-mini", in: TKOccupancyView.bundle, compatibleWith: nil)
    case .full, .notAcceptingPassengers:
      return UIImage(named: "icon-cross-mini", in: TKOccupancyView.bundle, compatibleWith: nil)
    case .unknown:
      return nil
    }
  }
  
  public var isCritical: Bool {
    switch self {
    case .crushedStandingRoomOnly, .full, .notAcceptingPassengers:
      return true
    default:
      return false
    }
  }
  
}

@available(iOS 8.2, *)
public class TKOccupancyView: UIView {
  
  public weak var icon: UIImageView!
  public weak var label: UILabel!
  
  // MARK: - Initialisers
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
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
    
    if #available(iOS 9.0, *) {
      let height = icon.heightAnchor.constraint(equalToConstant: 16)
      height.priority = 999
      height.isActive = true
      
      icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
      icon.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      icon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
      
      label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4).isActive = true
      label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
      label.heightAnchor.constraint(equalTo: icon.heightAnchor).isActive = true
      label.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
      trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8).isActive = true
    } else {
      // Constraints on icon
      let widthConstraint = NSLayoutConstraint(item: icon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 16)
      let heightConstraint = NSLayoutConstraint(item: icon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 16)
      heightConstraint.priority = 999
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

@available(iOS 8.2, *)
extension TKOccupancyView {
  
  public static var bundle: Bundle {
    return Bundle(for: TKOccupancyView.self)
  }
  
}

@available(iOS 8.2, *)
extension TKOccupancyView {
  
  public enum Purpose {
    case occupancy(TKOccupancy)
    case wheelchair
  }
  
  public convenience init(with purpose: Purpose) {
    self.init()
    
    switch purpose {
    case .occupancy(let occupancy):
      guard
        let title = occupancy.description else {
          return
      }
      
      label.text = title.uppercased()
      
      icon.image = occupancy.icon
      icon.backgroundColor = occupancy.color
      icon.tintColor = UIColor.white
      
      if occupancy.isCritical {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = occupancy.color
        icon.layer.cornerRadius = 0
        label.textColor = UIColor.white
      } else {
        icon.layer.cornerRadius = 8
        label.textColor = occupancy.color
      }
      
    case .wheelchair:
      let color = UIColor(red: 0/255.0, green: 155/255.0, blue: 223/255.0, alpha: 1.0)
      
      label.text = NSLocalizedString("Wheelchair accessible", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "").uppercased()
      label.textColor = color
      
      icon.image = UIImage(named: "icon-wheelchair-mini", in: TKOccupancyView.bundle, compatibleWith: nil)
      icon.backgroundColor = color
      icon.tintColor = UIColor.white
      icon.layer.cornerRadius = 2
    }
  }
  
}
