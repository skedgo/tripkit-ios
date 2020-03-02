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
  public var placeholderImage: UIImage? = nil
  public var imageURL: URL?
  public var imageIsTemplate: Bool
  public var imageTintColor: UIColor?
  public var modeName: String
  
  public var serviceShortName: String?
  public var serviceColor: UIColor?
  public var serviceIsCancelled: Bool

  public var accessibilityLabel: String?
  public var accessibilityTimeText: String?
  public var timeText: NSAttributedString
  public var lineText: String?

  public var approximateTimeToDepart: Date?
  public var alwaysShowAccessibilityInformation: Bool
  public var wheelchairAccessibility: TKUIWheelchairAccessibility
  public var alerts: [Alert]
  public var vehicleOccupancies: Observable<([[TKAPI.VehicleOccupancy]], Date)>?
}

public enum TKUIWheelchairAccessibility {
  case accessible
  case notAccessible
  case unknown
  
  public var title: String {
    switch self {
    case .accessible:
      return Loc.WheelchairAccessible
    case .notAccessible:
      return Loc.WheelchairNotAccessible
    case .unknown:
      return Loc.WheelchairAccessibilityUnknown
    }
  }
  
  public var icon: UIImage {
    switch self {
    case .accessible:
      return TripKitUIBundle.imageNamed("icon-wheelchair-accessible")
    case .notAccessible:
      return TripKitUIBundle.imageNamed("icon-wheelchair-not-accessible")
    case .unknown:
      return TripKitUIBundle.imageNamed("icon-wheelchair-unknown")
    }
  }
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
  @IBOutlet weak var occupancyImageView: UIImageView!
  
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

    backgroundColor = .tkBackground
    
    titleLabel.textColor = .tkLabelSecondary
    subtitleLabel.textColor = .tkLabelSecondary
    timeToDepartTextLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
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
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : self.backgroundColor
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
    
    accessibilityLabel = dataSource.accessibilityLabel
    
    serviceImageView.setImage(with: dataSource.imageURL, asTemplate: dataSource.imageIsTemplate, placeholder: dataSource.placeholderImage)
    serviceImageView.tintColor = dataSource.imageTintColor ?? .tkLabelPrimary
    
    serviceShortNameLabel.text = dataSource.serviceShortName
    let serviceColor = dataSource.serviceColor ?? .tkLabelPrimary
    let textColor: UIColor = serviceColor.isDark() ? .tkLabelOnDark : .tkLabelOnLight
    serviceShortNameLabel.textColor = textColor
    serviceColorView.backgroundColor = serviceColor
    
    titleLabel.attributedText = dataSource.timeText
    subtitleLabel.text = dataSource.lineText
    
    updateAccessibilitySection()
    updateRealTime()
    
    if dataSource.approximateTimeToDepart != nil {
      Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
        .startWith(0)
        .subscribe(onNext: { [weak self] _ in
          self?.updateCounter()
        })
        .disposed(by: disposeBag)
    } else {
      timeToDepartTextLabel.isHidden = true
      timeToDepartUnitLabel.isHidden = true 
    }
  }
  
  private func updateAccessibilitySection() {
    guard let dataSource = dataSource else { return }
    
    if dataSource.alwaysShowAccessibilityInformation {
      accessibleImageView.isHidden = false
      accessibleImageView.image = dataSource.wheelchairAccessibility.icon
      accessibleImageView.accessibilityLabel = dataSource.wheelchairAccessibility.title
    } else {
      accessibleImageView.isHidden = true
    }    
  }
  
  private func updateRealTime() {
    guard let dataSource = dataSource else { return }

    if let sampleAlert = dataSource.alerts.first {
      alertImageView.isHidden = false
      alertImageView.tintColor = sampleAlert.isCritical() ? .tkStateError : .tkStateWarning
      alertImageView.accessibilityLabel = sampleAlert.title ?? Loc.Alert
    } else {
      alertImageView.isHidden = true
    }

    occupancyImageView.isHidden = true
    dataSource.vehicleOccupancies?
      .subscribe(onNext: { [weak self] in
        let average = TKAPI.VehicleOccupancy.average(in: $0.0.flatMap { $0 })
        self?.occupancyImageView.isHidden = average == nil
        self?.occupancyImageView.image = average?.standingPeople()
        self?.occupancyImageView.accessibilityLabel = average?.localizedTitle
      })
      .disposed(by: disposeBag)
  }
  
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
