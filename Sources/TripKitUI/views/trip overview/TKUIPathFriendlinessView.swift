//
//  TKUIPathFriendlinessView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 27/9/17.
//

import UIKit
import CoreLocation
import MapKit

import TripKit

class TKUIPathFriendlinessView: UIView {
  
  // Bar chart
  @IBOutlet weak var friendlyBarView: UIView!
  @IBOutlet weak var unfriendlyBarView: UIView!
  @IBOutlet weak var dismountBarView: UIView!
  @IBOutlet weak var unknownBarView: UIView!
  
  // Chart label
  @IBOutlet weak var friendlyMetreLabel: UILabel!
  @IBOutlet weak var unfriendlyMetreLabel: UILabel!
  @IBOutlet weak var dismountMetreLabel: UILabel!
  @IBOutlet weak var unknownMetreLabel: UILabel!
  
  // Legend
  @IBOutlet weak var friendlyLegendLabel: UILabel!
  @IBOutlet weak var unfriendlyLegendLabel: UILabel!
  @IBOutlet weak var dismountLegendLabel: UILabel!
  @IBOutlet weak var unknownLegendLabel: UILabel!
  @IBOutlet weak var friendlyLegendDot: UIView!
  @IBOutlet weak var unfriendlyLegendDot: UIView!
  @IBOutlet weak var dismountLegendDot: UIView!
  @IBOutlet weak var unknownLegendDot: UIView!
  
  // Spacers
  @IBOutlet weak var friendlyToUnfriendlySpacingConstraint: NSLayoutConstraint!
  @IBOutlet weak var unfriendlyToDismountSpacingConstraint: NSLayoutConstraint!
  @IBOutlet weak var dismountToUnknownSpacingConstraint: NSLayoutConstraint!
  
  var segment: TKSegment? {
    didSet {
      update()
    }
  }
  
  typealias PathFriedliness = (friendly: CGFloat, unfriendly: CGFloat, dismount: CGFloat, unknown: CGFloat)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    friendlyLegendLabel.text   = TKPathFriendliness.friendly.title
    unfriendlyLegendLabel.text = TKPathFriendliness.unfriendly.title
    dismountLegendLabel.text   = TKPathFriendliness.dismount.title
    unknownLegendLabel.text    = TKPathFriendliness.unknown.title
  }
  
  fileprivate func update() {
    guard
      let segment = segment,
      let totalMetres = segment.distanceInMetres?.doubleValue
      else { return }
    
    guard totalMetres > 0 else {
      assertionFailure("Don't display this for segments that have no distance.")
      return
    }
    
    let friendlyMetres = segment.distanceInMetresFriendly?.doubleValue ?? 0
    let friendlyRatio = friendlyMetres / totalMetres
    
    let unfriendlyMetres = segment.distanceInMetresUnfriendly?.doubleValue ?? 0
    let unfriendlyRatio = unfriendlyMetres / totalMetres

    let dismountMetres = segment.distanceInMetresDismount?.doubleValue ?? 0
    let dismountRatio = dismountMetres / totalMetres

    let unknownMetres = totalMetres - friendlyMetres - dismountMetres - unfriendlyMetres - 1 // -1 for rounding issues
    let unknownRatio = unknownMetres / totalMetres
    
    // Legend
    friendlyLegendLabel.text   = TKPathFriendliness.friendly.title
    friendlyLegendLabel.font   = TKStyleManager.customFont(forTextStyle: .caption1)
    unfriendlyLegendLabel.text = TKPathFriendliness.unfriendly.title
    unfriendlyLegendLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    dismountLegendLabel.text   = TKPathFriendliness.dismount.title
    dismountLegendLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    unknownLegendLabel.text    = TKPathFriendliness.unknown.title
    unknownLegendLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    
    // Colors
    friendlyLegendDot.backgroundColor = TKPathFriendliness.friendly.color
    unfriendlyLegendDot.backgroundColor = TKPathFriendliness.unfriendly.color
    dismountLegendDot.backgroundColor = TKPathFriendliness.dismount.color
    unknownLegendDot.backgroundColor = TKPathFriendliness.unknown.color
    friendlyBarView.backgroundColor = TKPathFriendliness.friendly.color
    unfriendlyBarView.backgroundColor = TKPathFriendliness.unfriendly.color
    dismountBarView.backgroundColor = TKPathFriendliness.dismount.color
    unknownBarView.backgroundColor = TKPathFriendliness.unknown.color
    friendlyMetreLabel.textColor = TKPathFriendliness.friendly.color
    unfriendlyMetreLabel.textColor = TKPathFriendliness.unfriendly.color
    dismountMetreLabel.textColor = TKPathFriendliness.dismount.color
    unknownMetreLabel.textColor = TKPathFriendliness.unknown.color
    friendlyLegendLabel.textColor = .tkLabelSecondary
    unfriendlyLegendLabel.textColor = .tkLabelSecondary
    dismountLegendLabel.textColor = .tkLabelSecondary
    unknownLegendLabel.textColor = .tkLabelSecondary

    // Update bar chart.
    let widthConstraints = [
      friendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(friendlyRatio)),
      unfriendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unfriendlyRatio)),
      dismountBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(dismountRatio)),
      unknownBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unknownRatio))
    ]
    
    // Lower the priority of the width constraint because floating point arithmetic may produce
    // ratios that don't add up to precisely 1 should one of the bar views has zero width.
    widthConstraints.forEach { $0.priority = .defaultHigh }
    NSLayoutConstraint.activate(widthConstraints)
    
    let distanceFormatter = MKDistanceFormatter()
    
    // Update labels
    friendlyMetreLabel.text = distanceFormatter.string(fromDistance: friendlyMetres)
    friendlyMetreLabel.font = TKStyleManager.systemFont(size: 12)
    unfriendlyMetreLabel.text = distanceFormatter.string(fromDistance: unfriendlyMetres)
    unfriendlyMetreLabel.font = TKStyleManager.systemFont(size: 12)
    dismountMetreLabel.text = distanceFormatter.string(fromDistance: dismountMetres)
    dismountMetreLabel.font = TKStyleManager.systemFont(size: 12)
    unknownMetreLabel.text = distanceFormatter.string(fromDistance: unknownMetres)
    unknownMetreLabel.font = TKStyleManager.systemFont(size: 12)
    
    updateAccessibilityLabel(friendly: friendlyMetres, unfriendly: unfriendlyMetres, dismount: dismountMetres, unknown: unknownMetres)
    
    // Hide labels if required
    friendlyMetreLabel.isHidden = friendlyMetres < 0.5
    unfriendlyMetreLabel.isHidden = unfriendlyMetres < 0.5
    dismountMetreLabel.isHidden = dismountMetres < 0.5
    unknownMetreLabel.isHidden = unknownMetres < 0.5
    friendlyLegendLabel.isHidden = friendlyMetreLabel.isHidden
    unfriendlyLegendLabel.isHidden = unfriendlyMetreLabel.isHidden
    dismountLegendLabel.isHidden = dismountMetreLabel.isHidden
    unknownLegendLabel.isHidden = unknownMetreLabel.isHidden
    friendlyLegendDot.isHidden = friendlyMetreLabel.isHidden
    unfriendlyLegendDot.isHidden = unfriendlyMetreLabel.isHidden
    dismountLegendDot.isHidden = dismountMetreLabel.isHidden
    unknownLegendDot.isHidden = unknownMetreLabel.isHidden

    // Account for non-zero width of hidden labels
    friendlyMetreLabel.widthAnchor.constraint(equalToConstant: 0).isActive = friendlyMetreLabel.isHidden
    unfriendlyMetreLabel.widthAnchor.constraint(equalToConstant: 0).isActive = unfriendlyMetreLabel.isHidden
    dismountMetreLabel.widthAnchor.constraint(equalToConstant: 0).isActive = dismountMetreLabel.isHidden
    unknownMetreLabel.widthAnchor.constraint(equalToConstant: 0).isActive = unknownMetreLabel.isHidden
    
    // Spacing
    friendlyToUnfriendlySpacingConstraint.constant = friendlyMetreLabel.isHidden ? 0 : 8
    unfriendlyToDismountSpacingConstraint.constant = dismountMetreLabel.isHidden ? 0 : 8
    dismountToUnknownSpacingConstraint.constant = unfriendlyMetreLabel.isHidden ? 0 : 8
  }
  
  private func updateAccessibilityLabel(friendly: CLLocationDistance, unfriendly: CLLocationDistance, dismount: CLLocationDistance, unknown: CLLocationDistance) {
    let distanceFormatter = MKDistanceFormatter()

    let parts = [
        (Loc.FriendlyPath, friendly),
        (Loc.UnfriendlyPath, unfriendly),
        (Loc.Dismount, dismount),
        (Loc.Unknown, unknown),
      ]
      .filter { $0.1 > 0.5 }
      .map { ($0.0, distanceFormatter.string(fromDistance: $0.1)) }
    
    isAccessibilityElement = true
    accessibilityLabel = parts.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
  }
  
}

extension TKUIPathFriendlinessView {
  
  static func newInstance() -> TKUIPathFriendlinessView {
    return Bundle.tripKitUI.loadNibNamed("TKUIPathFriendlinessView", owner: self, options: nil)?.first as! TKUIPathFriendlinessView
  }
  
}
