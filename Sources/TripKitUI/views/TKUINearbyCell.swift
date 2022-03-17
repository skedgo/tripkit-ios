//
//  TKUINearbyCell.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 26/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

import TripKit
import RxSwift

 public class TKUINearbyCell: UITableViewCell {

  @IBOutlet weak var modeIconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var bearingIconView: UIImageView!
  @IBOutlet weak var distanceLabel: UILabel!
  
  var disposeBag = DisposeBag()
  
  public static var reuseIdentifier: String {
    return "TKUINearbyCell"
  }
  
  public static var nib: UINib {
    return UINib(nibName: "TKUINearbyCell", bundle: Bundle(for: TKUINearbyCell.self))
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    modeIconView.tintColor = .tkLabelPrimary
    bearingIconView.tintColor = .tkLabelSecondary
    bearingIconView.image = UIImage.iconCompass
    distanceLabel.textColor = .tkLabelSecondary
    distanceLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .tkLabelSecondary
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    contentView.backgroundColor = .clear
  }
  
  // MARK: - Configuration
  
  public var nearbyItem: TKUINearbyViewModel.Item? {
    didSet {
      updateUI()
    }
  }
  
  fileprivate let formatter = MKDistanceFormatter()
  
  fileprivate func updateUI() {
    guard let item = nearbyItem else {
      assertionFailure("Unable to update UI without a nearby item")
      return
    }
    
    disposeBag = DisposeBag()

    titleLabel.text = item.title
    subtitleLabel.isHidden = true
    distanceLabel.isHidden = true
    bearingIconView.isHidden = true
    
    // Use remote image if possible
    if let url = item.iconURL {
      modeIconView.setImage(with: url, placeholder: item.icon)
    } else {
      modeIconView.image = item.icon
    }
    
    item.subtitle
      .drive(onNext: { [weak self] subtitle in
        guard let self = self else { return }
        self.subtitleLabel.isHidden = subtitle == nil
        self.subtitleLabel.text = subtitle
      })
      .disposed(by: disposeBag)
    
    item.distance
      .map { [weak self] distance -> String? in
        guard let distance = distance else { return nil }
        return self?.formatter.string(fromDistance: distance)
      }
      .drive(onNext: { [weak self] text in
        guard let self = self else { return }
        self.distanceLabel.isHidden = text == nil
        self.distanceLabel.text = text
      })
      .disposed(by: disposeBag)
    
    item.heading
      .map { heading -> CGFloat? in
        guard let heading = heading else { return nil }
        // 0 if icon is pointing up, 180 if down, others: try...
        let start: CGFloat = 180
        let rotation = -1 * (start - CGFloat(heading))
        return rotation
      }
      .map { rotation -> CGAffineTransform? in
        guard let rotation = rotation else { return nil }
        return CGAffineTransform(rotationAngle: rotation * .pi / 180)
      }
      .drive(onNext: { [weak self] transform in
        if let transform = transform {
          self?.bearingIconView.isHidden = false
          self?.bearingIconView.transform = transform
        } else {
          self?.bearingIconView.isHidden = true
        }
      })
      .disposed(by: disposeBag)
  }
  
}

