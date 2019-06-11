//
//  TKUIServiceTitleView.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TGCardViewController

class TKUIServiceTitleView: UIView {

  @IBOutlet weak var modeIcon: UIImageView!
  @IBOutlet weak var coloredStrip: UIView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var subsubtitleLabel: UILabel!
  
  @IBOutlet weak var footnoteSpacerHeight: NSLayoutConstraint!
  @IBOutlet weak var footnoteView: UIView!
  
  @IBOutlet weak var dismissButton: UIButton!
  
  private let disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceTitleView {
    return Bundle(for: TKUIServiceTitleView.self).loadNibNamed("TKUIServiceTitleView", owner: self, options: nil)?.first as! TKUIServiceTitleView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    coloredStrip.isHidden = true
    titleLabel.text = nil
    subtitleLabel.text = nil
    subsubtitleLabel.text = nil
    
    footnoteSpacerHeight.constant = 0
    footnoteView.isHidden = true
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }
  
  func replaceFootnoteView(_ view: UIView) {
    // Make sure we start clean.
    for subview in footnoteView.subviews {
      subview.removeFromSuperview()
    }
    
    // Keep some space between footnote and the rest of the labels
    footnoteSpacerHeight.constant = 3

    footnoteView.isHidden = false
    footnoteView.addSubview(view)
    
    // Hook up constraints.
    view.translatesAutoresizingMaskIntoConstraints = false
    
    view.leadingAnchor.constraint(equalTo: footnoteView.leadingAnchor).isActive = true
    view.topAnchor.constraint(equalTo: footnoteView.topAnchor).isActive = true
    footnoteView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    footnoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
}

// MARK: - TKUIDepartureCardContentModel compatibility

extension TKUIServiceTitleView {
  func configure(with model: TKUIDepartureCardContentModel) {
    // Main content
    titleLabel.attributedText = model.title
    subtitleLabel.text = model.subtitle
    subsubtitleLabel.text = model.subsubtitle
    modeIcon.setImage(with: model.serviceImageURL, asTemplate: model.serviceImageIsTemplate, placeholder: model.servicePlaceholderImage)
    modeIcon.tintColor = TKStyleManager.darkTextColor()
    coloredStrip.backgroundColor = model.serviceLineColor
    
    // TODO: Also include alerts
    
    // Footer
    if let occupancies = model.serviceOccupancies {
      occupancies.subscribe(onNext: { [weak self] occupancies in
        if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1 {
          let trainView = TKUITrainOccupancyView()
          trainView.occupancies = occupancies
          self?.replaceFootnoteView(trainView)
        } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
          let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy))
          self?.replaceFootnoteView(occupancyView)
        }
      }).disposed(by: disposeBag)
    }
  }
}
