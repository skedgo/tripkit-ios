//
//  TKUIPathFriendlinessView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 27/9/17.
//

import UIKit

@available(*, unavailable, renamed: "TKUIPathFriendlinessView")
public typealias TKPathFriendlinessView = TKUIPathFriendlinessView

public class TKUIPathFriendlinessView: UIView {
  
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
  
  public var segment: TKSegment? {
    didSet {
      update()
    }
  }
  
  public typealias PathFriedliness = (friendly: CGFloat, unfriendly: CGFloat, dismount: CGFloat, unknown: CGFloat)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    friendlyLegendLabel.text   = TKPathFriendliness.friendly.title
    unfriendlyLegendLabel.text = TKPathFriendliness.unfriendly.title
    dismountLegendLabel.text   = TKPathFriendliness.dismount.title
    unknownLegendLabel.text    = TKPathFriendliness.unknown.title
  }
  
  fileprivate func update() {
    guard
      let template = self.segment?.template,
      let totalMetres = template.metres?.doubleValue
      else { return }
    
    let friendlyMetres = template.metresFriendly?.doubleValue ?? Double(0)
    let friendlyRatio = friendlyMetres / totalMetres
    
    let unfriendlyMetres = template.metresUnfriendly?.doubleValue ?? Double(0)
    let unfriendlyRatio = unfriendlyMetres / totalMetres

    let dismountMetres = template.metresDismount?.doubleValue ?? Double(0)
    let dismountRatio = dismountMetres / totalMetres

    let unknownMetres = totalMetres - friendlyMetres - dismountMetres - unfriendlyMetres - 1 // -1 for rounding issues
    let unknownRatio = unknownMetres / totalMetres
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    
    // Legend
    friendlyLegendLabel.text   = TKPathFriendliness.friendly.title
    friendlyLegendLabel.font = TKStyleManager.systemFont(size: 12)
    unfriendlyLegendLabel.text = TKPathFriendliness.unfriendly.title
    unfriendlyLegendLabel.font = TKStyleManager.systemFont(size: 12)
    dismountLegendLabel.text   = TKPathFriendliness.dismount.title
    dismountLegendLabel.font = TKStyleManager.systemFont(size: 12)
    unknownLegendLabel.text    = TKPathFriendliness.unknown.title
    unknownLegendLabel.font = TKStyleManager.systemFont(size: 12)
    
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
  
}

extension TKUIPathFriendlinessView {
  
  public static func newInstance() -> TKUIPathFriendlinessView {
    return Bundle.tripKitUI.loadNibNamed("TKUIPathFriendlinessView", owner: self, options: nil)?.first as! TKUIPathFriendlinessView
  }
  
}
