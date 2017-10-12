//
//  TKOccupancyView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/10/2016.
//
//

import UIKit

@available(iOS 9.0, *)
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

@available(iOS 9.0, *)
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
    
    let heightConstraint = icon.heightAnchor.constraint(equalToConstant: 16)
    heightConstraint.priority = 999
    
    NSLayoutConstraint.activate([
        heightConstraint,
        icon.widthAnchor.constraint(equalToConstant: 16),
        icon.leadingAnchor.constraint(equalTo: leadingAnchor),
        icon.centerYAnchor.constraint(equalTo: centerYAnchor)
      ])
    
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
      label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
      bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
      trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 0)
      ])
  }

}

@available(iOS 9.0, *)
extension TKOccupancyView {
  
  public static var bundle: Bundle {
    return Bundle(for: TKOccupancyView.self)
  }
  
}

@available(iOS 9.0, *)
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
      let color = #colorLiteral(red: 0, green: 0.6078431373, blue: 0.8745098039, alpha: 1)
      
      label.text = Loc.WheelchairAccessible.uppercased()
      label.textColor = color
      
      icon.image = UIImage(named: "icon-wheelchair-mini", in: TKOccupancyView.bundle, compatibleWith: nil)
      icon.backgroundColor = color
      icon.tintColor = UIColor.white
      icon.layer.cornerRadius = 2
    }
  }
  
}
