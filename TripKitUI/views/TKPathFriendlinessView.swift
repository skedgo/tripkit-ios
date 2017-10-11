//
//  TKPathFriendlinessView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 27/9/17.
//

import UIKit

public class TKPathFriendlinessView: UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  
  // Bar chart  
  @IBOutlet weak var friendlyBarView: UIView!
  @IBOutlet weak var unfriendlyBarView: UIView!
  @IBOutlet weak var unknownBarView: UIView!
  
  // Chart label
  @IBOutlet weak var friendlyMetreLabel: UILabel!
  @IBOutlet weak var unfriendlyMetreLabel: UILabel!
  @IBOutlet weak var unknownMetreLabel: UILabel!
  
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
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    friendlyMetreLabel.isHidden = friendlyMetreLabel.frame.width < friendlyMetreLabel.intrinsicContentSize.width
    unfriendlyMetreLabel.isHidden = unfriendlyMetreLabel.frame.width < unfriendlyMetreLabel.intrinsicContentSize.width
    unknownMetreLabel.isHidden = unknownMetreLabel.frame.width < unknownMetreLabel.intrinsicContentSize.width
  }
  
  fileprivate func update() {
    guard
      let segment = self.segment,
      segment.template != nil,
      let metres = segment.template.metres
      else { return }
    
    let friendlyMetres = segment.template.metresFriendly != nil ? segment.template.metresFriendly.doubleValue : Double(0)
    let friendlyRatio = friendlyMetres / metres.doubleValue
    
    let unfriendlyMetres = segment.template.metresUnfriendly != nil ? segment.template.metresUnfriendly.doubleValue : Double(0)
    let unfriendlyRatio = unfriendlyMetres / metres.doubleValue
    
    let unknownMetres = metres.doubleValue - friendlyMetres - unfriendlyMetres
    let unknownRatio = unknownMetres / metres.doubleValue
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    
    // Update title
    let format: String
    if segment.isCycling() {
      format = NSLocalizedString("%@ cycle friendly", tableName: "TripKit", bundle: .tripKitUI, comment: "Indicator for how cycle-friendly a cycling route is. Placeholder will get replaced with '75%'.")
    } else {
      format = NSLocalizedString("%@ wheelchair friendly", tableName: "TripKit", bundle: .tripKitUI, comment: "Indicator for how wheelchair-friendly a wheeelchair route is. Placeholder will get replaced with '75%'.")
    }
    titleLabel.text = String(format: format, formatter.string(from: NSNumber(value: friendlyRatio))!)
    
    // Update bar chart.
    let widthConstraints = [
        friendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(friendlyRatio)),
        unfriendlyBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unfriendlyRatio)),
        unknownBarView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(unknownRatio))
      ]
    
    widthConstraints.forEach { $0.priority = 999 }
    
    NSLayoutConstraint.activate(widthConstraints)
    
    let distanceFormatter = MKDistanceFormatter()
    
    // Update labels
    friendlyMetreLabel.text = distanceFormatter.string(fromDistance: friendlyMetres)
    unfriendlyMetreLabel.text = distanceFormatter.string(fromDistance: unfriendlyMetres)
    unknownMetreLabel.text = distanceFormatter.string(fromDistance: unknownMetres)
    
    NSLayoutConstraint.activate([
        friendlyMetreLabel.widthAnchor.constraint(equalTo: friendlyBarView.widthAnchor, multiplier: 1),
        unfriendlyMetreLabel.widthAnchor.constraint(equalTo: unfriendlyBarView.widthAnchor, multiplier: 1),
        unknownMetreLabel.widthAnchor.constraint(equalTo: unknownBarView.widthAnchor, multiplier: 1)
      ])
  }
  
}

extension TKPathFriendlinessView {
  
  public static func newInstance() -> TKPathFriendlinessView {
    return Bundle.tripKitUI.loadNibNamed("TKPathFriendlinessView", owner: self, options: nil)?.first as! TKPathFriendlinessView
  }
  
}

