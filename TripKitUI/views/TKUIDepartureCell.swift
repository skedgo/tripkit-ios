//
//  TKUIDepartureCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 28/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

public protocol TKUIDepartureCellContentDataSource {
  var placeHolderImage: UIImage? { get }
  var imageURL: URL? { get }
  var imageIsTemplate: Bool { get }
  var lineColor: UIColor? { get }
  var title: NSAttributedString { get }
  var subtitle: String? { get }
  var subsubtitle: String? { get }
  var approximateTimeToDepart: Date? { get }
  var accessibilityDisplaySetting: TKUIAccessibilityDisplaySetting { get }
  var alerts: [Alert] { get }
  var vehicleOccupancies: Observable<[[API.VehicleOccupancy]]>? { get }
}

public enum TKUIAccessibilityDisplaySetting {
  case enabled(Bool?)
  case disabled
}

public class TKUIDepartureCell: UITableViewCell {
  
  @IBOutlet weak var serviceImageView: UIImageView!
  @IBOutlet weak var serviceColorView: UIView!
  @IBOutlet weak var titleLabel: TKUIStyledLabel!
  @IBOutlet weak var subtitleLabel: TKUIStyledLabel!
  @IBOutlet weak var subsubtitleLabel: TKUIStyledLabel!
  @IBOutlet weak var additionalInfoStackView: UIStackView!
  
  @IBOutlet weak var accessibilityStackView: UIStackView!
  @IBOutlet weak var accessibleImageView: UIImageView!
  @IBOutlet weak var accessibleTextLabel: TKUIStyledLabel!
  
  @IBOutlet weak var alertStackView: UIStackView!
  @IBOutlet weak var alertImageView: UIImageView!
  @IBOutlet weak var alertActionButton: UIButton!
  @IBOutlet weak var alertTextLabel: TKUIStyledLabel!
  
  public static let reuseIdentifier = "TKUIDepartureCell"
  public static let nib = UINib(nibName: "TKUIDepartureCell", bundle: .tripKitUI)
  
  public var dataSource: TKUIDepartureCellContentDataSource? {
    didSet {
      updateUI()
    }
  }
  
  public var disposeBag = DisposeBag()

  public override func awakeFromNib() {
    super.awakeFromNib()
  }

  public override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
  
}

// MARK: - Configuring cell content

extension TKUIDepartureCell {
  
  private func updateUI() {
    guard let dataSource = dataSource else { return }
    
    serviceColorView.backgroundColor = dataSource.lineColor
    serviceImageView.setImage(with: dataSource.imageURL, asTemplate: dataSource.imageIsTemplate, placeholder: dataSource.placeHolderImage)
    
    titleLabel.attributedText = dataSource.title
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    subtitleLabel.text = dataSource.subtitle
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subsubtitleLabel.text = dataSource.subsubtitle
    subsubtitleLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    
    updateAdditionalInfoSection()
    updateAccessibilitySection()
    updateServiceAlertSection()
  }
  
  private func updateAccessibilitySection() {
    guard let dataSource = dataSource else { return }
    
    switch dataSource.accessibilityDisplaySetting {
    case .enabled(let isAccessible):
      var info: (icon: UIImage, text: String)
      
      switch isAccessible {
      case true?:
        info.icon = TripKitUIBundle.imageNamed("icon-wheelchair-accessible")
        info.text = Loc.WheelchairAccessible
      case false?:
        info.icon = TripKitUIBundle.imageNamed("icon-wheelchair-not-accessible")
        info.text = Loc.WheelchairNotAccessible
      default:
        info.icon = TripKitUIBundle.imageNamed("icon-wheelchair-unknow")
        info.text = Loc.WheelchairAccessibilityUnknown
      }
      
      accessibleImageView.image = info.icon
      accessibleTextLabel.text = info.text
      accessibleTextLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
      accessibilityStackView.isHidden = false
      
    case .disabled:
      accessibilityStackView.isHidden = true
    }    
  }
  
  private func updateServiceAlertSection() {
    guard
      let dataSource = dataSource,
      !dataSource.alerts.isEmpty
      else {
        alertStackView.isHidden = true
        return
    }
    
    alertStackView.isHidden = false
    
    // For now, we only show the first alert.
    let alert = dataSource.alerts[0]
    alertImageView.image = TKInfoIcon.image(for: alert.infoIconType, usage: .normal)
    
    alertTextLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    if let description = alert.title ?? alert.text, dataSource.alerts.count == 1 {
      alertTextLabel.text = description
    } else {
      alertTextLabel.text = Loc.Alerts(dataSource.alerts.count)
    }
    
    alertActionButton.setTitle(Loc.Show, for: .normal)
    alertActionButton.titleLabel?.font = TKStyleManager.semiboldSystemFont(size: 13)
  }
  
  private func updateAdditionalInfoSection() {
    if let occupancies = dataSource?.vehicleOccupancies {
      occupancies
        .subscribe(onNext: { [weak self] occupancies in
          if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1 {
            let trainView = TKUITrainOccupancyView()
            trainView.occupancies = occupancies
            self?.updateAdditionalInfoStackViewContent(with: trainView)
          } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
            let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy))
            self?.updateAdditionalInfoStackViewContent(with: occupancyView)
          } else {
            self?.updateAdditionalInfoStackViewContent(with: nil)
          }
        })
        .disposed(by: disposeBag)
      
      additionalInfoStackView.isHidden = false
    } else {
      additionalInfoStackView.isHidden = true
    }
  }
  
  private func updateAdditionalInfoStackViewContent(with newView: UIView?) {
    additionalInfoStackView.arrangedSubviews.forEach {
      additionalInfoStackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    
    if let newView = newView {
      additionalInfoStackView.addArrangedSubview(newView)
      additionalInfoStackView.isHidden = false
    } else {
      additionalInfoStackView.isHidden = true
    }
  }
  
}
