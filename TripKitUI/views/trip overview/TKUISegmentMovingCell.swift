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
    
    backgroundColor = .tkBackground

    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.textColor = .tkLabelSecondary
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    buttonStackView.arrangedSubviews
      .compactMap { $0 as? UIButton }
      .forEach { $0.setTitleColor(tintColor, for: .normal) }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
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

fileprivate extension UIStackView {
  func resetViews(_ views: [UIView]) {
    arrangedSubviews.forEach(removeArrangedSubview)
    removeAllSubviews()
    views.forEach(addArrangedSubview)
    isHidden = views.isEmpty
  }
}

extension TKUISegmentMovingCell {
  
  func configure(with item: TKUITripOverviewViewModel.MovingItem, for card: TKUITripOverviewCard) {
    let hasLine = item.connection?.color != nil
    
    modeImage.setImage(with: item.iconURL, asTemplate: item.iconIsTemplate, placeholder: item.icon)
    modeImage.tintColor = hasLine ? .tkBackground : .tkLabelPrimary
    
    if item.iconURL != nil, !item.iconIsTemplate {
      // If we have a remote image, that's not a template, put it as is on
      // the background
      modeImage.tintColor = .tkLabelPrimary
      modeWrapper.backgroundColor = .tkBackground
      
    } else {
      // ... otherwise, put the image on a background
      modeImage.tintColor = hasLine ? .tkBackground : .tkLabelPrimary
      modeWrapper.backgroundColor = item.connection?.color ?? .clear
    }
    
    titleLabel.text = item.title
    subtitleLabel.text = item.notes
    subtitleLabel.isHidden = item.notes == nil

    line.backgroundColor = item.connection?.color
    line.isHidden = !hasLine
    
    let accessories = item.accessories.map(TKUISegmentMovingCell.buildView)
    accessoryViewStack.resetViews(accessories)
    
    let buttons = item.actions.map { buildView(for: $0, for: card) }
    buttonStackView.resetViews(buttons)
  }
  
  private static func buildView(for segmentAccessory: TKUITripOverviewViewModel.SegmentAccessory) -> UIView {
    switch segmentAccessory {
    case .averageOccupancy(let occupancy):
      return TKUIOccupancyView(with: .occupancy(occupancy, simple: true))
      
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
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    button.setTitleColor(tintColor, for: .normal)

    // We could add an icon here, too, but that's not yet in the style guide
    // button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
    // button.setImage(action.icon, for: .normal)

    button.setTitle(action.title, for: .normal)
    button.rx.tap
      .subscribe(onNext: { [unowned card] in
        _ = action.handler(card, button)
      })
      .disposed(by: disposeBag)
    return button
  }
}
