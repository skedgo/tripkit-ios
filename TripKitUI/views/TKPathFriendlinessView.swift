//
//  TKPathFriendlinessView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 27/9/17.
//

import UIKit

public class TKPathFriendlinessView: UIView {
  
  // Bar chart
  @IBOutlet weak var friendlyBarView: UIView!
  @IBOutlet weak var unfriendlyBarView: UIView!
  @IBOutlet weak var unknownBarView: UIView!
  
  // Chart label
  @IBOutlet weak var friendlyMetreLabel: UILabel!
  @IBOutlet weak var unfriendlyMetreLabel: UILabel!
  @IBOutlet weak var unknownMetreLabel: UILabel!
  
  // Legend
  @IBOutlet var friendlyLegendLabel: UILabel!
  @IBOutlet var unfriendlyLegendLabel: UILabel!
  @IBOutlet var unknownLegendLabel: UILabel!
  @IBOutlet weak var friendlyLegendDot: UIView!
  @IBOutlet weak var unfriendlyLegendDot: UIView!
  @IBOutlet weak var unknownLegendDot: UIView!
  
  @IBOutlet weak var friendlyToUnfriendlySpacing: NSLayoutConstraint!
  @IBOutlet weak var unfriendlyToUnknownSpacing: NSLayoutConstraint!
  
  public var segment: TKSegment? {
    didSet {
      update()
    }
  }
  
  public typealias PathFriedliness = (friendly: CGFloat, unfriendly: CGFloat, unknown: CGFloat)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    friendlyLegendLabel.text = Loc.FriendlyPath
    unfriendlyLegendLabel.text = Loc.UnfriendlyPath
    unknownLegendLabel.text = Loc.UnknownPathFriendliness
  }
  
  fileprivate func update() {
    guard
      let segment = self.segment,
      segment.template != nil,
      let metres = segment.template.metres
      else { return }
    
    let friendlyMetres = segment.template?.metresFriendly?.doubleValue ?? Double(0)
    let friendlyRatio = friendlyMetres / metres.doubleValue
    
    let unfriendlyMetres = segment.template?.metresUnfriendly?.doubleValue ?? Double(0)
    let unfriendlyRatio = unfriendlyMetres / metres.doubleValue
    
    let unknownMetres = metres.doubleValue - friendlyMetres - unfriendlyMetres
    let unknownRatio = unknownMetres / metres.doubleValue
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    
    // Legend
    friendlyLegendLabel.text = Loc.FriendlyPath
    unfriendlyLegendLabel.text = Loc.UnfriendlyPath
    unknownLegendLabel.text = Loc.UnknownPathFriendliness
    
    // Update bar chart.
    let widthConstraints = [
        friendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(friendlyRatio)),
        unfriendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unfriendlyRatio)),
        unknownBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unknownRatio))
      ]
    
    // Lower the priority of the width constraint because floating point arithmetic may produce
    // ratios that don't add up to precisely 1 should one of the bar views has zero width.
    widthConstraints.forEach { $0.priority = .defaultHigh }
    NSLayoutConstraint.activate(widthConstraints)
    
    let distanceFormatter = MKDistanceFormatter()
    
    // Update labels
    friendlyMetreLabel.text = distanceFormatter.string(fromDistance: friendlyMetres)
    unfriendlyMetreLabel.text = distanceFormatter.string(fromDistance: unfriendlyMetres)
    unknownMetreLabel.text = distanceFormatter.string(fromDistance: unknownMetres)
    
    // Hide labels if required
    friendlyMetreLabel.isHidden = friendlyMetres < 0.5
    unfriendlyMetreLabel.isHidden = unfriendlyMetres < 0.5
    unknownMetreLabel.isHidden = unknownMetres < 0.5
    friendlyLegendLabel.isHidden = friendlyMetreLabel.isHidden
    unfriendlyLegendLabel.isHidden = unfriendlyMetreLabel.isHidden
    unknownLegendLabel.isHidden = unknownMetreLabel.isHidden
    friendlyLegendDot.isHidden = friendlyMetreLabel.isHidden
    unfriendlyLegendDot.isHidden = unfriendlyMetreLabel.isHidden
    unknownLegendDot.isHidden = unknownMetreLabel.isHidden

    // Account for non-zero width of hidden labels
    let friendlyLabelWidth = friendlyMetreLabel.widthAnchor.constraint(equalToConstant: 0)
    let unfriendlyLabelWidthConstraint = unfriendlyMetreLabel.widthAnchor.constraint(equalToConstant: 0)
    let unknownLabelWidthConstraint = unknownMetreLabel.widthAnchor.constraint(equalToConstant: 0)
    
    friendlyLabelWidth.isActive = friendlyMetreLabel.isHidden
    unfriendlyLabelWidthConstraint.isActive = unfriendlyMetreLabel.isHidden
    unknownLabelWidthConstraint.isActive = unknownMetreLabel.isHidden
    
    friendlyToUnfriendlySpacing.constant = friendlyMetres < 0.5 ? 0 : 8
    unfriendlyToUnknownSpacing.constant = unknownMetres < 0.5 ? 0 : 8
  }
  
}

extension TKPathFriendlinessView {
  
  public static func newInstance() -> TKPathFriendlinessView {
    return Bundle.tripKitUI.loadNibNamed("TKPathFriendlinessView", owner: self, options: nil)?.first as! TKPathFriendlinessView
  }
  
}
