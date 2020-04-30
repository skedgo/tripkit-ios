//
//  TKUISegmentImpossibleCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 10/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUISegmentImpossibleCell: UITableViewCell {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var button: UIButton!
  
  static let nib = UINib(nibName: "TKUISegmentImpossibleCell", bundle: Bundle(for: TKUISegmentImpossibleCell.self))
  
  static let reuseIdentifier = "TKUISegmentImpossibleCell"
  
  private(set) var disposeBag = DisposeBag()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = TKColor.tkLabelPrimary
    titleLabel.text = Loc.YouMightNotMakeThisTransfer
    
    button.setTitle(Loc.AlternativeRoutes, for: .normal)
    button.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    button.tintColor = TKColor.tkLabelPrimary
    
    button.layer.borderWidth = 2
    button.layer.borderColor = TKColor.tkLabelTertiary.cgColor
    
    // TODO: Add an image
    // button.setImage(<#T##image: UIImage?##UIImage?#>, for: .normal)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    button.layer.cornerRadius = button.bounds.height / 2
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    button.isHighlighted = highlighted
  }
    
}
