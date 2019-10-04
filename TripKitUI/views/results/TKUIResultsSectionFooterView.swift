//
//  TKUIResultsSectionFooterView.swift
//  TripKit
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIResultsSectionFooterView: UITableViewHeaderFooterView {

  static let nib = UINib(nibName: "TKUIResultsSectionFooterView", bundle: Bundle(for: TKUIResultsSectionFooterView.self))
  static let reuseIdentifier = "TKUIResultsSectionFooterView"
  
  static func newInstance() -> TKUIResultsSectionFooterView {
    return Bundle.tripKitUI.loadNibNamed("TKUIResultsSectionFooterView", owner: self, options: nil)?.first as! TKUIResultsSectionFooterView
  }
  
  @IBOutlet weak var costLabel: UILabel!
  @IBOutlet weak var button: UIButton!
  
  var disposeBag = DisposeBag()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    contentView.backgroundColor = .tkBackgroundTile
    
    costLabel.text = nil
    costLabel.textColor = .tkLabelSecondary
    costLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    costLabel.text = nil
    disposeBag = DisposeBag()
  }
  
  var cost: String? {
    get { costLabel.text }
    set { costLabel.text = newValue }
  }
  
  var attributedCost: NSAttributedString? {
    get { costLabel.attributedText }
    set { costLabel.attributedText = newValue }
  }
  
}
