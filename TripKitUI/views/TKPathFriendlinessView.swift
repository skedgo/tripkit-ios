//
//  TKPathFriendlinessView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 27/9/17.
//

import UIKit

public class TKPathFriendlinessView: UIView {
  
  public typealias PathFriedliness = (friendly: CGFloat, unfriendly: CGFloat, unknown: CGFloat)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public func setup(with friendliness: PathFriedliness) {
    let chartWrapper = UIStackView()
    chartWrapper.axis = .horizontal
    chartWrapper.distribution = .fill
    chartWrapper.alignment = .fill
    chartWrapper.spacing = 0
    addSubview(chartWrapper)
    
    chartWrapper.translatesAutoresizingMaskIntoConstraints = false
    chartWrapper.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    chartWrapper.topAnchor.constraint(equalTo: topAnchor).isActive = true
    bottomAnchor.constraint(equalTo: chartWrapper.bottomAnchor).isActive = true
    trailingAnchor.constraint(equalTo: chartWrapper.trailingAnchor).isActive = true
    
    let friendlyView = UIView()
    chartWrapper.addArrangedSubview(friendlyView)
    friendlyView.translatesAutoresizingMaskIntoConstraints = false
    friendlyView.backgroundColor = #colorLiteral(red: 0, green: 0.6078431373, blue: 0.8745098039, alpha: 1)
    friendlyView.widthAnchor.constraint(equalTo: chartWrapper.widthAnchor, multiplier: friendliness.friendly).isActive = true
    
    let unfriendlyView = UIView()
    chartWrapper.addArrangedSubview(unfriendlyView)
    unfriendlyView.translatesAutoresizingMaskIntoConstraints = false
    unfriendlyView.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.09411764706, alpha: 1)
    unfriendlyView.widthAnchor.constraint(equalTo: chartWrapper.widthAnchor, multiplier: friendliness.unfriendly).isActive = true
    
    let unknownView = UIView()
    chartWrapper.addArrangedSubview(unknownView)
    unknownView.translatesAutoresizingMaskIntoConstraints = false
    unknownView.backgroundColor = #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
    unknownView.widthAnchor.constraint(equalTo: chartWrapper.widthAnchor, multiplier: friendliness.unknown).isActive = true
  }
}

extension TKPathFriendlinessView {
  
  public convenience init?(_ segment: TKSegment) {
    guard
      segment.template != nil,
      let metres = segment.template.metres
      else { return nil }
    
    self.init()
    
    let friendly = segment.template.metresFriendly != nil ? segment.template.metresFriendly.doubleValue : Double(0)
    let friendlyRatio = CGFloat(friendly / metres.doubleValue)
    
    let unfriendly = segment.template.metresUnfriendly != nil ? segment.template.metresUnfriendly.doubleValue : Double(0)
    let unfriendlyRatio = CGFloat(unfriendly / metres.doubleValue)
    
    let unknown = metres.doubleValue - friendly - unfriendly
    let unknownRatio = CGFloat(unknown / metres.doubleValue)
    
    let pathFriendliness: PathFriedliness = (friendly: friendlyRatio, unfriendly: unfriendlyRatio, unknown: unknownRatio)
    setup(with: pathFriendliness)
  }
}

