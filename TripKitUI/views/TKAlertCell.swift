//
//  TKAlertCell.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

#if TK_NO_MODULE
#else
  import TripKit
#endif


class TKAlertCell: UITableViewCell {

  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var fromDateLabel: UILabel!
  @IBOutlet weak var toDateLabel: UILabel!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var affectedRoutesLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var statusView: UIView!
  @IBOutlet weak var statusIconView: UIImageView!
  @IBOutlet weak var statusViewHeight: NSLayoutConstraint!
  @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
  
  private var textViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var dateStackViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var routeStackViewBottomConstraint: NSLayoutConstraint!
  
  // MARK: -
  
  @objc static var nib: UINib {
    return UINib(nibName: String(describing: self), bundle: Bundle(for: TKAlertCell.self))
  }
  
  @objc var alert: TKAlert? {
    didSet {
      updateUI()
    }
  }
  
  private var showStatusView: Bool = true {
    didSet {
      statusView.isHidden = !showStatusView
      statusViewHeight.constant = showStatusView ? 44.0 : 0.0
    }
  }
  
  private var disposeBag = DisposeBag()
  
  var tappedOnLink = PublishSubject<URL>()
  
  // MARK: - Configuration
  
  private func updateUI() {
    guard let alert = alert else {
      return
    }
    
    reset()
    
    titleLabel.text = alert.title
    iconView.image = alert.icon
    if let iconURL = alert.iconURL {
      iconView.setImage(with: iconURL, placeholder: alert.icon)
    }
    
    if let text = alert.text {
      textView.text = removeStrongTag(from: text)
    } else {
      textView.text = nil
    }
    
    if let url = alert.infoURL {
      actionButton.isHidden = false
      actionButton.rx.tap
        .subscribe(onNext: { [unowned self] in
          self.tappedOnLink.onNext(url)
        })
        .disposed(by: disposeBag)
    } else {
      actionButton.isHidden = true
    }
    
    if let lastUpdated = alert.lastUpdated {
      statusLabel.isHidden = false
      statusLabel.text = SGStyleManager.string(for: lastUpdated, for: NSTimeZone.local, showDate: true, showTime: true)
    } else {
      statusLabel.isHidden = true
      statusLabel.text = nil
    }
    
    // Show the status view if both status label & action
    // button are visible
    showStatusView = actionButton.isHidden == false || statusLabel.isHidden == false
  }
  
  private func reset() {
    disposeBag = DisposeBag()
    tappedOnLink = PublishSubject<URL>()
  }
  
  private func removeStrongTag(from text: String) -> String {
    // remove strong tag.
    var massaged = removeHTMLMarkdown(markdown: "<strong>", from: text)
    massaged = removeHTMLMarkdown(markdown: "</strong>", from: massaged)
    return massaged
  }
  
  private func removeHTMLMarkdown(markdown: String, from text: String) -> String {
    return text.replacingOccurrences(of: markdown, with: "")
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    super.awakeFromNib()
    SGStyleManager.addDefaultOutline(contentWrapper)
    textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 0)
    actionButton.setTitle(Loc.MoreInfo, for: .normal)
    fromDateLabel.textColor = SGStyleManager.globalTintColor()
    toDateLabel.textColor = SGStyleManager.globalTintColor()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    reset()
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.25) {
      self.contentWrapper.backgroundColor = highlighted ? SGStyleManager.cellSelectionBackgroundColor() : UIColor.white
    }
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    
    dateStackViewTopConstraint.constant = (fromDateLabel.isHidden && toDateLabel.isHidden) ? 0 : 12
    textViewHeightConstraint.isActive = textView.text.isEmpty
    textViewBottomConstraint.constant = textView.text.isEmpty ? 0 : 8
    routeStackViewBottomConstraint.constant = affectedRoutesLabel.isHidden ? 0 : 12
  }
}
