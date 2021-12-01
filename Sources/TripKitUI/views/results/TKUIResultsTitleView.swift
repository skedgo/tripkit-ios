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

import TripKit

class TKUIResultsTitleView: UIView {
  
  @IBOutlet weak var originLabel: UILabel!
  @IBOutlet weak var destinationLabel: UILabel!
  @IBOutlet weak var dismissButton: UIButton!
  
  @IBOutlet private weak var fromToStack: UIStackView!
  @IBOutlet private weak var topLevelStack: UIStackView!
  @IBOutlet private weak var accessoryViewContainer: UIView!
  
  @IBOutlet private weak var topLevelStackBottomSpacing: NSLayoutConstraint!
  
  var enableTappingLocation: Bool = true
  
  private let locationSearchPublisher = PublishSubject<Void>()
  var locationTapped: Signal<Void> {
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
    
    destinationLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title3)
    destinationLabel.textColor = .tkLabelPrimary
    
    let fromToTapper = UITapGestureRecognizer(target: self, action: #selector(fromToTapped))
    fromToTapper.delegate = self
    fromToStack.isUserInteractionEnabled = true
    fromToStack.addGestureRecognizer(fromToTapper)
    
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

    let originName = origin ?? "…"
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
    
    originLabel.isAccessibilityElement = false
    destinationLabel.isAccessibilityElement = false
    fromToStack.isAccessibilityElement = true
    if destination != nil, origin != nil {
      fromToStack.accessibilityLabel = originText + " - " + destinationText
    } else if destination != nil {
      fromToStack.accessibilityLabel = Loc.PlanTrip + " - " + destinationText
    } else if origin != nil {
      fromToStack.accessibilityLabel = Loc.PlanTrip + " - " + originText
    } else {
      fromToStack.accessibilityLabel = Loc.PlanTrip
    }
    fromToStack.accessibilityHint = Loc.TapToChangeStartAndEndLocations
    fromToStack.accessibilityTraits = .button
    
    accessibilityElements = [
      fromToStack, dismissButton, accessoryView
    ].compactMap { $0 }
  }
  
  @objc @IBAction
  private func fromToTapped() {
    guard enableTappingLocation else { return }
    locationSearchPublisher.onNext(())
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
