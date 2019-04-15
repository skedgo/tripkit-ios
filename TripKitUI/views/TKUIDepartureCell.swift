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
  var imageTintColor: UIColor? { get }
  var lineColor: UIColor? { get }
  var title: NSAttributedString { get }
  var subtitle: String? { get }
  var subsubtitle: String? { get }
  var approximateTimeToDepart: Date? { get }
  var serviceIsCancelled: Bool { get }
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
  
  @IBOutlet weak var timeToDepartContentView: UIView!
  @IBOutlet weak var timeToDepartTextLabel: TKUIStyledLabel!
  
  @IBOutlet weak var accessibilityStackView: UIStackView!
  @IBOutlet weak var accessibleImageView: UIImageView!
  @IBOutlet weak var accessibleTextLabel: TKUIStyledLabel!
  
  @IBOutlet weak var alertStackView: UIStackView!
  @IBOutlet weak var alertImageView: UIImageView!
  @IBOutlet weak var alertActionButton: UIButton!
  @IBOutlet weak var alertTextLabel: TKUIStyledLabel!
  
  @IBOutlet weak var selectionIndicator: UIView!

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
    
    timeToDepartContentView.layer.cornerRadius = 3
    
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subsubtitleLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    accessibleTextLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    alertTextLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    alertActionButton.titleLabel?.font = TKStyleManager.semiboldSystemFont(size: 13)
    timeToDepartTextLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = TKStyleManager.globalTintColor()
  }

  public override func setSelected(_ selected: Bool, animated: Bool) {
    // Not calling super, to not highlight background
    selectionIndicator.isHidden = !selected
  }
  
  public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
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
    
    serviceColorView.backgroundColor = dataSource.lineColor
    serviceImageView.setImage(with: dataSource.imageURL, asTemplate: dataSource.imageIsTemplate, placeholder: dataSource.placeHolderImage)
    serviceImageView.tintColor = dataSource.imageTintColor ?? TKStyleManager.darkTextColor()
    
    titleLabel.attributedText = dataSource.title
    subtitleLabel.text = dataSource.subtitle
    subsubtitleLabel.text = dataSource.subsubtitle
    
    updateAdditionalInfoSection()
    updateAccessibilitySection()
    updateServiceAlertSection()
    
    if dataSource.approximateTimeToDepart != nil {
      Observable<Int>.interval(5, scheduler: MainScheduler.instance)
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
      
      accessibleImageView.image = info.icon
      accessibleTextLabel.text = info.text
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
    
    if let description = alert.title ?? alert.text, dataSource.alerts.count == 1 {
      alertTextLabel.text = description
    } else {
      alertTextLabel.text = Loc.Alerts(dataSource.alerts.count)
    }
    
    alertActionButton.setTitle(Loc.Show, for: .normal)
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
        timeToDepartContentView.isHidden = true
        return
    }
    
    timeToDepartContentView.isHidden = false
    
    let minutesToShow = minutesToCount(till: timeToDepart)
    
    // Setting counter text
    var text: String?
    var accessibilityText: String?
    
    if dataSource.serviceIsCancelled {
      text = Loc.Cancelled
      
    } else if (TKStyleManager.departureIsNow(forMinutes: minutesToShow, fuzzifyMinutes: true)) {
      text = Loc.Now
      
    } else {
      text = TKStyleManager.departureString(forMinutes: minutesToShow, fuzzifyMinutes: true)
      accessibilityText = TKStyleManager.departureAccessibilityLabel(forMinutes: minutesToShow, fuzzifyMinutes: true)
    }
    
    timeToDepartTextLabel.text = text
    timeToDepartTextLabel.accessibilityLabel = accessibilityText
    
    // Setting counter background
    if dataSource.serviceIsCancelled {
      timeToDepartContentView.backgroundColor = UIColor(red: 231/255, green: 77/255, blue: 79/255, alpha: 1)
    } else {
      UIView.animate(withDuration: 0.25) {
        self.timeToDepartContentView.backgroundColor = self.color(forCountingDownFrom: minutesToShow)
      }
    }
    
    // Fade if required
    UIView.animate(withDuration: 0.25) {
      self.contentView.alpha = minutesToShow < 0 ? 0.5 : 1
    }
  }
  
  private func color(forCountingDownFrom minutesToCount: Int) -> UIColor {
    let strongHighlight = TKStyleManager.globalTintColor()
    let subtleHighlight = TKStyleManager.globalTintColor().withAlphaComponent(0.7)
    
    if minutesToCount < 0 {
      return UIColor(white: 183/255, alpha: 1.0)
      
    } else if minutesToCount > 15 {
      return subtleHighlight
      
    } else {
      let fadeFrom = subtleHighlight
      var redFrom: CGFloat = 0, greenFrom: CGFloat = 0, blueFrom: CGFloat = 0, alpha: CGFloat = 0
      fadeFrom.getRed(&redFrom, green: &greenFrom, blue: &blueFrom, alpha: &alpha)
      
      let fadeTo = strongHighlight
      var redTo: CGFloat = 0, greenTo: CGFloat = 0, blueTo: CGFloat = 0
      fadeTo.getRed(&redTo, green: &greenTo, blue: &blueTo, alpha: &alpha)
      
      let danger = CGFloat((15 - minutesToCount)) / 15
      let red = redTo + (redFrom - redTo) * (1 - danger)
      let green = greenTo + (greenFrom - greenTo) * (1 - danger)
      let blue = blueTo + (blueFrom - blueTo) * (1 - danger)
      return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
  }
  
}
