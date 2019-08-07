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
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.textColor = .tkLabelSecondary
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? TKStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
}

fileprivate extension UIStackView {
  func resetViews(_ views: [UIView]) {
    arrangedSubviews.forEach(removeArrangedSubview)
    removeAllSubviews()
    views.forEach(addArrangedSubview)
  }
}

extension TKUISegmentMovingCell {
  
  func configure(with item: TKUITripOverviewViewModel.MovingItem, for card: TKUITripOverviewCard) {
    modeImage.setImage(with: item.iconURL, asTemplate: item.iconIsTemplate, placeholder: item.icon)
    modeImage.tintColor = .white
    
    titleLabel.text = item.title
    subtitleLabel.text = item.notes
    subtitleLabel.isHidden = item.notes == nil

    let lineColor = item.connection?.color ?? .lightGray
    modeWrapper.backgroundColor = lineColor
    line.backgroundColor = lineColor
    
    let accessories = item.accessories.map(TKUISegmentMovingCell.buildView)
    accessoryViewStack.resetViews(accessories)
    
    let buttons = item.actions.map { buildView(for: $0, for: card) }
    buttonStackView.resetViews(buttons)
  }
  
  private static func buildView(for segmentAccessory: TKUITripOverviewViewModel.SegmentAccessory) -> UIView {
    switch segmentAccessory {
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
  
  private func buildView(for action: TKUITripOverviewCardAction, for card: TKUITripOverviewCard) -> UIView {
    let button = UIButton(type: .custom)
    button.setTitle(action.title, for: .normal)
    button.setImage(action.icon, for: .normal)
    button.rx.tap
      .subscribe(onNext: { [unowned card] in
        _ = action.handler(card, button)
      })
      .disposed(by: disposeBag)
    return button
  }
}
