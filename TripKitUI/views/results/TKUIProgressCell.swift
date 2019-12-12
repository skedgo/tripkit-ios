//
//  TKUIProgressCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 12/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUIProgressCell: UITableViewCell {
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  public static let nib = UINib(nibName: "TKUIProgressCell", bundle: Bundle(for: TKUIProgressCell.self))
  
  public static let reuseIdentifier: String = "TKUIProgressCell"

  override public func awakeFromNib() {
    super.awakeFromNib()
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    spinner.startAnimating()
  }
  
}
