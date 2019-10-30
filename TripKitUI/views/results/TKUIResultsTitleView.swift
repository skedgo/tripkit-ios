//
//  TKUIResultsTitleView.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 3/10/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

import RxSwift
import RxCocoa

class TKUIResultsTitleView: UIView {
  
  @IBOutlet weak var originLabel: UILabel!
  @IBOutlet weak var destinationLabel: UILabel!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var originButton: UIButton!
  @IBOutlet weak var originButtonBackground: UIView!
  
  @IBOutlet private weak var topLevelStack: UIStackView!
  @IBOutlet private weak var accessoryViewContainer: UIView!
  
  @IBOutlet private weak var topLevelStackBottomSpacing: NSLayoutConstraint!
  
  var enableTappingLocation: Bool = true {
    didSet {
      originButton.isEnabled = enableTappingLocation
    }
  }
  
  private let locationSearchPublisher = PublishSubject<TKUIRoutingResultsViewModel.SearchMode>()
  var locationTapped: Signal<TKUIRoutingResultsViewModel.SearchMode> {
    return locationSearchPublisher.asSignal(onErrorSignalWith: .empty())
  }
  
  var accessoryView: UIView? {
    get {
      return accessoryViewContainer.subviews.first
    }
    set {
      accessoryViewContainer.subviews.forEach { $0.removeFromSuperview() }
      
      guard let accessory = newValue else {
        accessoryViewContainer.isHidden = true
        topLevelStack.spacing = 0
        topLevelStackBottomSpacing.constant = 16
        return
      }
      
      accessoryViewContainer.isHidden = false
      topLevelStack.spacing = 16
      topLevelStackBottomSpacing.constant = 0
      
      accessoryViewContainer.addSubview(accessory)
      accessory.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
          accessory.leadingAnchor.constraint(equalTo: accessoryViewContainer.leadingAnchor),
          accessory.topAnchor.constraint(equalTo: accessoryViewContainer.topAnchor),
          accessory.trailingAnchor.constraint(equalTo: accessoryViewContainer.trailingAnchor),
          accessory.bottomAnchor.constraint(equalTo: accessoryViewContainer.bottomAnchor)
        ]
      )
    }
  }
  
  static func newInstance() -> TKUIResultsTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUIResultsTitleView", owner: self, options: nil)?.first as! TKUIResultsTitleView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    originLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    originLabel.textColor = .tkLabelSecondary
    let originLabelTapper = UITapGestureRecognizer(target: self, action: #selector(originLabelTapped))
    originLabelTapper.delegate = self
    originLabel.isUserInteractionEnabled = true
    originLabel.addGestureRecognizer(originLabelTapper)
    
    originButton.tintColor = .tkAppTintColor
    originButton.accessibilityLabel = Loc.StartLocation
    originButtonBackground.backgroundColor = UIColor.tkAppTintColor.withAlphaComponent(0.12)
    
    destinationLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
    destinationLabel.textColor = .tkLabelPrimary
    let destinationTapper = UITapGestureRecognizer(target: self, action: #selector(destinationLabelTapped))
    destinationTapper.delegate = self
    destinationLabel.isUserInteractionEnabled = true
    destinationLabel.addGestureRecognizer(destinationTapper)
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close
  }
  
  func configure(destination: String?, origin: String?) {
    let destinationText: String
    if let name = destination {
      destinationText = Loc.To(location: name)
    } else {
      destinationText = Loc.PlanTrip
    }
    destinationLabel.text = destinationText

    let originName = origin ?? "..."
    let originText = Loc.From(location: originName)
    let attributedOrigin = NSMutableAttributedString(string: originText)
    attributedOrigin.addAttribute(
      .foregroundColor, value: UIColor.tkLabelSecondary,
      range: NSRange(location: 0, length: (originText as NSString).length)
    )
    attributedOrigin.addAttribute(
      .foregroundColor, value: UIColor.tkAppTintColor,
      range: (originText as NSString).range(of: originName)
    )
    
    originLabel.attributedText = attributedOrigin
  }
  
  @objc @IBAction
  private func originLabelTapped() {
    guard enableTappingLocation else { return }
    
    locationSearchPublisher.onNext(.origin)
  }
  
  @objc private func destinationLabelTapped() {
    guard enableTappingLocation else { return }

    locationSearchPublisher.onNext(.destination)
  }
  
}

extension TKUIResultsTitleView: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
}
