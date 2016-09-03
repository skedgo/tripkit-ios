//
//  TKAlertCell.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit
import RxSwift

struct TKAlertDisplayModel {
  let title: String
  let text: String?
  let URL: String?
  let icon: UIImage?
  let lastUpdated: NSDate?
  
  init(title: String, text: String? = nil, URL: String? = nil, icon: UIImage? = nil, lastUpdated: NSDate?) {
    self.title = title
    self.text = text
    self.URL = URL
    self.icon = icon
    self.lastUpdated = lastUpdated
  }
}

extension TKAlertDisplayModel {
  
  static func fromAlert(alert: Alert) -> TKAlertDisplayModel {
    let icon = STKInfoIcon.image(for: alert.infoIconType(), usage: STKInfoIconUsageNormal)
    return TKAlertDisplayModel(title: alert.title, text: alert.text, URL: alert.url, icon: icon, lastUpdated: nil)
  }
  
  static func fromAlertInformation(info: TransitAlertInformation) -> TKAlertDisplayModel {
    return TKAlertDisplayModel(title: info.title, text: info.text, URL: info.URL, icon: nil, lastUpdated: nil)
  }
  
}

class TKAlertCell: UITableViewCell {

  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var statusView: UIView!
  @IBOutlet weak var statusViewHeight: NSLayoutConstraint!
  @IBOutlet weak var statusIconView: UIImageView!
  
  // MARK: -
  
  static var nib: UINib {
    return UINib(nibName: String(describing: self), bundle: Bundle(for: TKAlertCell.self))
  }
  
  var alert: TKAlert? {
    didSet {
      updateUI()
    }
  }
  
  private var showStatusView: Bool = true {
    didSet {
      statusView.isHidden = !showStatusView
      statusViewHeight.constant = showStatusView ? CGFloat(40) : CGFloat(0)
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
    
    if let text = alert.text {
      textView.text = removeStrongTag(from: text)
    }
    
    if let stringURL = alert.URL,
       let URL = URL(string: stringURL) {
      actionButton.isHidden = false
      actionButton.rx.tap
        .subscribeNext { [unowned self] in
          self.tappedOnLink.onNext(URL)
        }
        .addDisposableTo(disposeBag)
    } else {
      actionButton.isHidden = true
    }
    
    if let lastUpdated = alert.lastUpdated {
      statusLabel.isHidden = false
    } else {
      statusLabel.isHidden = true
    }
    
    // Show the status view if both status label & action
    // button are visible
    showStatusView = actionButton.isHidden == false || statusLabel.isHidden == false
  }
  
  private func reset() {
    disposeBag = DisposeBag()
    tappedOnLink = PublishSubject<URL>()
    
    iconView.image = nil
    titleLabel.text = nil
    textView.text = nil
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
    actionButton.setTitle(NSLocalizedString("More info", comment: ""), for: .normal)
    textView.textContainerInset = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
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
}
