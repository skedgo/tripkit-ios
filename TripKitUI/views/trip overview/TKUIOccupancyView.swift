//
//  TKUIOccupancyView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/10/2016.
//
//

import UIKit

#if TK_NO_MODULE
#else
  import TripKit
#endif

extension TKAPI.VehicleOccupancy {
  
  var icon: UIImage? {
    switch self {
    case .empty, .manySeatsAvailable, .fewSeatsAvailable:
      return .iconCheckMini
    case .standingRoomOnly, .crushedStandingRoomOnly:
      return .iconExclamationmarkMini
    case .full, .notAcceptingPassengers:
      return .iconCrossMini
    case .unknown:
      return nil
    }
  }
  
  var isCritical: Bool {
    switch self {
    case .crushedStandingRoomOnly, .full, .notAcceptingPassengers:
      return true
    default:
      return false
    }
  }
  
}

@available(*, unavailable, renamed: "TKUIOccupancyView")
public typealias TKOccupancyView = TKUIOccupancyView

public class TKUIOccupancyView: UIView {
  
  public weak var icon: UIImageView!
  public weak var label: UILabel!
  private var heightConstraint: NSLayoutConstraint!
  
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
    label.font = TKStyleManager.customFont(forTextStyle: .caption1)
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    self.label = label
    
    heightConstraint = icon.heightAnchor.constraint(equalToConstant: 16)
    heightConstraint.priority = .defaultHigh
    
    NSLayoutConstraint.activate([
      heightConstraint,
      icon.widthAnchor.constraint(equalTo: icon.heightAnchor),
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

extension TKUIOccupancyView {
  
  public enum Purpose {
    case occupancy(TKAPI.VehicleOccupancy, simple: Bool = false)
    case wheelchair
  }
  
  public convenience init(with purpose: Purpose) {
    self.init()
    
    isAccessibilityElement = true

    switch purpose {
    case .occupancy(let occupancy, simple: true):
      guard let title = occupancy.localizedTitle else { return }

      accessibilityLabel = title
      label.text = title
      label.font = TKStyleManager.customFont(forTextStyle: .footnote)
      label.textColor = .tkLabelSecondary
      
      heightConstraint.constant = 24
      icon.image = occupancy.standingPeople(occupiedColor: .tkLabelPrimary) // dark as it'll get an alpha anyway
      
    case .occupancy(let occupancy, simple: false):
      guard let title = occupancy.localizedTitle else { return }
      
      accessibilityLabel = title
      
      label.text = title.localizedUppercase
      
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
      
      accessibilityLabel = Loc.WheelchairAccessible
      label.text = Loc.WheelchairAccessible.localizedUppercase
      label.textColor = color
      
      icon.image = .iconWheelchairMini
      icon.backgroundColor = color
      icon.tintColor = UIColor.white
      icon.layer.cornerRadius = 2
    }
  }
  
}