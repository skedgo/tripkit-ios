//
//  TKUISegmentTitleView
//  TripKitUI
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import TGCardViewController

import TripKit

public class TKUISegmentTitleView: UIView, TGPreferrableView {
  
  public typealias Action = TKUICardAction<TGCard, TKSegment>
  
  typealias SegmentTitleActionsView = TKUICardActionsView<TGCard, TKSegment>

  @IBOutlet weak var modeWrapper: UIView!
  @IBOutlet weak var modeIcon: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var subsubtitleLabel: UILabel!
  
  @IBOutlet weak var separator: UIView!
  @IBOutlet weak var actionsWrapper: UIView!
  
  @IBOutlet public weak var dismissButton: UIButton!
  
  @IBOutlet weak var separatorToLabelStackConstraint: NSLayoutConstraint!
  @IBOutlet weak var separatorToActionsWrapperConstraint: NSLayoutConstraint!
  @IBOutlet weak var actionsWrapperBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var actionsWrapperHeightConstraint: NSLayoutConstraint!
  
  var disposeBag: DisposeBag!
  
  public static func newInstance() -> TKUISegmentTitleView {
    return Bundle(for: TKUISegmentTitleView.self).loadNibNamed("TKUISegmentTitleView", owner: self, options: nil)?.first as! TKUISegmentTitleView
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    let primaryColor = TKUICustomization.shared.cardStyle.titleTextColor
    titleLabel.font = TKUICustomization.shared.cardStyle.titleFont
    titleLabel.textColor = primaryColor
    titleLabel.text = nil

    subtitleLabel.font = TKUICustomization.shared.cardStyle.subtitleFont
    subtitleLabel.textColor = TKUICustomization.shared.cardStyle.subtitleTextColor
    subtitleLabel.text = nil

    subsubtitleLabel.text = nil
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close

    modeIcon.tintColor = primaryColor
    
    // no actions by default
    separator.backgroundColor = .clear
    actionsWrapper.backgroundColor = nil
    showActionsWrapper(false)
  }
  
  public var preferredView: UIView? {
    titleLabel
  }
  
  public func setCustomActions(_ actions: [TKUISegmentTitleView.Action], for model: TKSegment, card: TGCard) {
    actionsWrapper.subviews.forEach { $0.removeFromSuperview() }
    
    if actions.isEmpty {
      showActionsWrapper(false)
    } else {
      let actionsView = SegmentTitleActionsView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 80))
      actionsView.configure(with: actions, model: model, card: card)
      actionsView.hideSeparator = true
      actionsWrapper.addSubview(actionsView)
      
      actionsView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        actionsView.leadingAnchor.constraint(equalTo: actionsWrapper.leadingAnchor),
        actionsView.topAnchor.constraint(equalTo: actionsWrapper.topAnchor),
        actionsView.trailingAnchor.constraint(equalTo: actionsWrapper.trailingAnchor),
        actionsView.bottomAnchor.constraint(equalTo: actionsWrapper.bottomAnchor)
      ])
      
      showActionsWrapper(true)
    }
  }
  
  public func applyStyleToCloseButton(_ style: TGCardStyle) {
    guard dismissButton != nil else { return }
    
    let styledImage = TGCard.closeButtonImage(style: style)
    dismissButton.setImage(styledImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }
  
  private func showActionsWrapper(_ show: Bool) {
    actionsWrapper.isHidden = !show
    separatorHeightConstraint.constant = show ? 1 : 0
    separatorToActionsWrapperConstraint.constant = show ? 8 : 0
    actionsWrapperBottomConstraint.constant = show ? 8 : 0
    
    if show {
      if let content = actionsWrapper.subviews.first {
        actionsWrapperHeightConstraint.constant = content.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      }
    } else {
      actionsWrapperHeightConstraint.constant = 0
    }
  }
  
}
