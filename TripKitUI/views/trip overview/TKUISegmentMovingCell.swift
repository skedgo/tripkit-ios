//
//  TKUISegmentMovingCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentMovingCell: UITableViewCell {
  @IBOutlet weak var modeImage: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var accessoryViewStack: UIStackView!
  
  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var line: UIView!
  
  static let nib = UINib(nibName: "TKUISegmentMovingCell", bundle: Bundle(for: TKUISegmentMovingCell.self))
  
  static let reuseIdentifier = "TKUISegmentMovingCell"
  
  func addAccessories(_ views: [UIView]) {
    removeAccessories()
    views.forEach(accessoryViewStack.addArrangedSubview)
  }
  
  private func removeAccessories() {
    accessoryViewStack.arrangedSubviews.forEach(accessoryViewStack.removeArrangedSubview(_:))
    accessoryViewStack.removeAllSubviews()
  }
}

extension TKUISegmentMovingCell {
  
  func configure(with item: TKUITripOverviewViewModel.MovingItem) {
    modeImage.setImage(with: item.iconURL, asTemplate: item.iconIsTemplate, placeholder: item.icon)
    modeImage.tintColor = TKStyleManager.darkTextColor() // TODO: add a colorCodingTransitIcon here, too?
    
    titleLabel.text = item.title
    titleLabel.textColor = TKStyleManager.darkTextColor()
    subtitleLabel.text = item.notes
    subtitleLabel.textColor = TKStyleManager.lightTextColor()
    subtitleLabel.isHidden = item.notes == nil

    line.backgroundColor = item.connection?.color ?? .lightGray
    
    let accessories = item.accessories.map { $0.buildView() }
    addAccessories(accessories)
  }
  
}

extension TKUITripOverviewViewModel.SegmentAccessory {
  func buildView() -> UIView {
    switch self {
    case .averageOccupancy(let occupancy):
      return TKUIOccupancyView(with: .occupancy(occupancy))
      
    case .carriageOccupancies(let occupancies):
      let trainView = TKUITrainOccupancyView()
      trainView.occupancies = occupancies
      return trainView

    case .pathFriendliness(let segment):
      let pathFriendlinessView = TKUIPathFriendlinessView.newInstance()
      pathFriendlinessView.segment = segment
      return pathFriendlinessView

    case .wheelchairFriendly:
      return TKUIOccupancyView(with: .wheelchair)
    }

  }
}
