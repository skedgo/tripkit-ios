//
//  TKUIDepartureCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 28/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

public struct TKUIDepartureCellContent {
  public var placeHolderImage: UIImage? = nil
  public var imageURL: URL?
  public var imageIsTemplate: Bool
  public var imageTintColor: UIColor?

  public var serviceShortName: String?
  public var serviceColor: UIColor?
  public var serviceIsCancelled: Bool

  public var title: NSAttributedString
  public var subtitle: String?

  public var approximateTimeToDepart: Date?
  public var accessibilityDisplaySetting: TKUIAccessibilityDisplaySetting
  public var alerts: [Alert]
  public var vehicleOccupancies: Observable<[[API.VehicleOccupancy]]>?
}

public enum TKUIAccessibilityDisplaySetting {
  case enabled(Bool?)
  case disabled
}

class TKUIDepartureCell: UITableViewCell {
  
  @IBOutlet weak var serviceImageView: UIImageView!
  @IBOutlet weak var serviceColorView: UIView!
  @IBOutlet weak var serviceShortNameLabel: TKUIStyledLabel!
  
  @IBOutlet weak var titleLabel: TKUIStyledLabel!
  @IBOutlet weak var subtitleLabel: TKUIStyledLabel!
  
  @IBOutlet weak var timeToDepartTextLabel: TKUIStyledLabel!
  @IBOutlet weak var timeToDepartUnitLabel: TKUIStyledLabel!
  
  @IBOutlet weak var accessibleImageView: UIImageView!
  @IBOutlet weak var alertImageView: UIImageView!
  
  @IBOutlet weak var selectionIndicator: UIView!

  static let reuseIdentifier = "TKUIDepartureCell"
  static let nib = UINib(nibName: "TKUIDepartureCell", bundle: .tripKitUI)
   
  var dataSource: TKUIDepartureCellContent? {
    didSet {
      updateUI()
    }
  }
  
  public var disposeBag = DisposeBag()

  public override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.textColor = .tkLabelSecondary
    subtitleLabel.textColor = .tkLabelSecondary
    timeToDepartUnitLabel.textColor = .tkStateSuccess
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = TKStyleManager.globalTintColor()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    // Not calling super, to not highlight background
    selectionIndicator.isHidden = !selected
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25: 0) {
      self.contentView.backgroundColor = highlighted ? TKStyleManager.cellSelectionBackgroundColor() : .white
    }
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
    
    serviceImageView.setImage(with: dataSource.imageURL, asTemplate: dataSource.imageIsTemplate, placeholder: dataSource.placeHolderImage)
    serviceImageView.tintColor = dataSource.imageTintColor ?? TKStyleManager.darkTextColor()
    
    serviceShortNameLabel.text = dataSource.serviceShortName
    serviceShortNameLabel.textColor = .tkBackground
    serviceColorView.backgroundColor = dataSource.serviceColor ?? .tkLabelPrimary
    
    titleLabel.attributedText = dataSource.title
    subtitleLabel.text = dataSource.subtitle
    
    updateAdditionalInfoSection()
    updateAccessibilitySection()
    updateServiceAlertSection()
    
    if dataSource.approximateTimeToDepart != nil {
      Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
        .startWith(0)
        .subscribe(onNext: { [weak self] _ in
          self?.updateCounter()
        })
        .disposed(by: disposeBag)
    }
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
      
      accessibleImageView.isHidden = false
      accessibleImageView.image = info.icon
      accessibleImageView.accessibilityLabel = info.text
      
    case .disabled:
      accessibleImageView.isHidden = true
    }    
  }
  
  private func updateServiceAlertSection() {
    guard
      let dataSource = dataSource,
      !dataSource.alerts.isEmpty
      else {
        alertImageView.isHidden = true
        return
    }
    
    alertImageView.isHidden = false
    
    // For now, we only show the first alert.
    let alert = dataSource.alerts[0]
    alertImageView.image = TKInfoIcon.image(for: alert.infoIconType, usage: .normal)
    alertImageView.accessibilityLabel = alert.title ?? alert.text ?? Loc.Alert
  }
  
  private func updateAdditionalInfoSection() {
//    if let occupancies = dataSource?.vehicleOccupancies {
//      occupancies
//        .subscribe(onNext: { [weak self] occupancies in
//          if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1 {
//            let trainView = TKUITrainOccupancyView()
//            trainView.occupancies = occupancies
//            self?.updateAdditionalInfoStackViewContent(with: trainView)
//          } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
//            let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy))
//            self?.updateAdditionalInfoStackViewContent(with: occupancyView)
//          } else {
//            self?.updateAdditionalInfoStackViewContent(with: nil)
//          }
//        })
//        .disposed(by: disposeBag)
//
//      additionalInfoStackView.isHidden = false
//    } else {
//      additionalInfoStackView.isHidden = true
//    }
  }
  
//  private func updateAdditionalInfoStackViewContent(with newView: UIView?) {
//    additionalInfoStackView.arrangedSubviews.forEach {
//      additionalInfoStackView.removeArrangedSubview($0)
//      $0.removeFromSuperview()
//    }
//
//    if let newView = newView {
//      additionalInfoStackView.addArrangedSubview(newView)
//      additionalInfoStackView.isHidden = false
//    } else {
//      additionalInfoStackView.isHidden = true
//    }
//  }
  
}

// MARK: - Configure time to depart counter
extension TKUIDepartureCell {
  
  private func minutesToCount(till timeToDepart: Date) -> Int {
    return Int((timeToDepart.timeIntervalSinceNow) / 60)
  }
  
  private func updateCounter() {
    guard
      let dataSource = dataSource,
      let timeToDepart = dataSource.approximateTimeToDepart
      else {
        timeToDepartTextLabel.isHidden = true
        timeToDepartUnitLabel.isHidden = true
        return
    }
    
    timeToDepartTextLabel.isHidden = false
    
    let minutesToShow = minutesToCount(till: timeToDepart)
    
    if dataSource.serviceIsCancelled {
      timeToDepartTextLabel.text = Loc.Cancelled
      timeToDepartTextLabel.textColor = .tkStateError
      timeToDepartUnitLabel.isHidden = true
      
    } else {
      timeToDepartTextLabel.textColor = .tkStateSuccess
      
      let departure = TKStyleManager.departure(forMinutes: minutesToShow, fuzzifyMinutes: true)
      if departure.mode == .now {
        timeToDepartTextLabel.text = Loc.Now
        timeToDepartUnitLabel.isHidden = true
      } else {
        timeToDepartTextLabel.text = departure.number
        timeToDepartUnitLabel.text = departure.unit
        timeToDepartUnitLabel.isHidden = false
        timeToDepartTextLabel.accessibilityLabel = departure.accessibilityLabel
      }
    }
    
    // Fade if required
    UIView.animate(withDuration: 0.25) {
      self.contentView.alpha = minutesToShow < 0 ? 0.5 : 1
    }
  }
  
}
