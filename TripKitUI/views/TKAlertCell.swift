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
    return UINib(nibName: String(self), bundle: NSBundle(forClass: TKAlertCell.self))
  }
  
  var alert: TKAlert? {
    didSet {
      updateUI()
    }
  }
  
  private var showStatusView: Bool = true {
    didSet {
      statusView.hidden = !showStatusView
      statusViewHeight.constant = showStatusView ? CGFloat(40) : CGFloat(0)
    }
  }
  
  private var disposeBag = DisposeBag()
  
  var tappedOnLink = PublishSubject<NSURL>()
  
  // MARK: - Configuration
  
  private func updateUI() {
    guard let alert = alert else {
      return
    }
    
    reset()
    
    titleLabel.text = alert.title
    iconView.image = alert.icon
    
    if let text = alert.text {
      textView.text = removeStrongTagFromText(text)
    }
    
    if let stringURL = alert.URL,
       let URL = NSURL(string: stringURL) {
      actionButton.hidden = false
      actionButton.rx_tap
        .subscribeNext { [unowned self] in
          self.tappedOnLink.onNext(URL)
        }
        .addDisposableTo(disposeBag)
    } else {
      actionButton.hidden = true
    }
    
    if let lastUpdated = alert.lastUpdated {
      statusLabel.hidden = false
      statusLabel.text = SGStyleManager.stringForDate(lastUpdated, forTimeZone: NSTimeZone.localTimeZone(), showDate: true, showTime: true)
    } else {
      statusLabel.hidden = true
    }
    
    // Show the status view if both status label & action
    // button are visible
    showStatusView = actionButton.hidden == false || statusLabel.hidden == false
  }
  
  private func reset() {
    disposeBag = DisposeBag()
    tappedOnLink = PublishSubject<NSURL>()
    
    iconView.image = nil
    titleLabel.text = nil
    textView.text = nil
  }
  
  private func removeStrongTagFromText(text: String) -> String {
    // remove strong tag.
    var massaged = text
    massaged = removeHTMLMarkdown("<strong>", from: text)
    massaged = removeHTMLMarkdown("</strong>", from: massaged)
    return massaged
  }
  
  private func removeHTMLMarkdown(markdown: String, from text: String) -> String {
    return text.stringByReplacingOccurrencesOfString(markdown, withString: "")
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    super.awakeFromNib()
    SGStyleManager.addDefaultOutline(contentWrapper)
    actionButton.setTitle(NSLocalizedString("More info", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title of button to get more details about an alert"), forState: .Normal)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    reset()
  }
  
  override func setHighlighted(highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animateWithDuration(0.25) {
      self.contentWrapper.backgroundColor = highlighted ? SGStyleManager.cellSelectionBackgroundColor() : UIColor.whiteColor()
    }
  }
}
