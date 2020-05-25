//
//  TKUISegmentMovingCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUISegmentMovingCell: UITableViewCell {
  @IBOutlet weak var modeWrapper: UIView!
  @IBOutlet weak var modeImage: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var accessoryViewStack: UIStackView!
  @IBOutlet weak var buttonStackView: UIStackView!
  
  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var line: UIView!
  
  static let nib = UINib(nibName: "TKUISegmentMovingCell", bundle: Bundle(for: TKUISegmentMovingCell.self))
  
  static let reuseIdentifier = "TKUISegmentMovingCell"
  
  private var disposeBag = DisposeBag()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear

    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.textColor = .tkLabelSecondary
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    buttonStackView.arrangedSubviews
      .compactMap { $0 as? UIButton }
      .forEach { $0.setTitleColor(tintColor, for: .normal) }
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : self.backgroundColor
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
}

extension TKUISegmentMovingCell {
  
  func configure(with item: TKUITripOverviewViewModel.MovingItem, for card: TKUITripOverviewCard) {
    let hasLine = item.connection?.color != nil
    let modeImageColor: UIColor
    switch item.connection?.color?.isDark() {
    case .some(true): modeImageColor = .tkLabelOnDark
    case .some(false): modeImageColor = .tkLabelOnLight
    case nil: modeImageColor = .tkLabelPrimary
    }
    
    modeImage.setImage(with: item.iconURL, asTemplate: item.iconIsTemplate, placeholder: item.icon)
    modeImage.tintColor = modeImageColor
    
    modeWrapper.isHidden = item.icon == nil && item.iconURL == nil
    
    if item.iconURL != nil, item.iconIsBranding {
      // We have a branded icon, we have to place it light on dark
      modeImage.tintColor = .black
      modeWrapper.backgroundColor = .white

    } else if item.iconURL != nil, !item.iconIsTemplate {
      // If we have a remote image, that's not a template, put it as is on
      // the background
      modeImage.tintColor = .tkLabelOnDark
      modeWrapper.backgroundColor = .tkBackground
      
    } else {
      // ... otherwise, put the image on a background
      modeImage.tintColor = modeImageColor
      modeWrapper.backgroundColor = item.connection?.color ?? .clear
    }
    
    titleLabel.text = item.title
    subtitleLabel.text = item.notes
    subtitleLabel.isHidden = item.notes == nil

    line.backgroundColor = item.connection?.color
    line.isHidden = !hasLine
    
    let accessories = item.accessories.map(TKUISegmentMovingCell.buildView)
    accessoryViewStack.resetViews(accessories)
    
    let buttons = item.actions.map { TKUISegmentCellHelper.buildView(for: $0, model: item.segment, for: card, tintColor: tintColor, disposeBag: disposeBag) }
    buttonStackView.resetViews(buttons)
  }
  
  private static func buildView(for segmentAccessory: TKUITripOverviewViewModel.SegmentAccessory) -> UIView {
    switch segmentAccessory {
    case .averageOccupancy(let occupancy, let title):
      return TKUIOccupancyView(with: .occupancy(occupancy, title: title, simple: true))
      
    case .carriageOccupancies(let occupancies):
      let trainView = TKUITrainOccupancyView()
      trainView.occupancies = occupancies
      return trainView

    case .pathFriendliness(let segment):
      let pathFriendlinessView = TKUIPathFriendlinessView.newInstance()
      pathFriendlinessView.segment = segment
      return pathFriendlinessView

    case .wheelchairAccessibility(let accessibility):
      return TKUIOccupancyView(with: .wheelchair(accessibility))
    }
  }

}
