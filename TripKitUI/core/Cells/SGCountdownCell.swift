//
//  SGCountdownCell.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 28/10/16.
//
//

import Foundation

import RxSwift
import RxCocoa

public struct SGCountdownCellModel {
  
  public var title: NSAttributedString
  public var subtitle: String?
  public var subsubtitle: String?
  public var icon: UIImage?
  public var iconImageURL: URL?
  public var time: Date?
  public var position: SGKGrouping
  public var color: UIColor?
  public var isCancelled: Bool = false
  public var isWheelchairEnabled: Bool = false
  public var isAccessible: Bool?
  public var alerts: [Alert] = []
  
  public init(title: NSAttributedString, position: SGKGrouping = .edgeToEdge) {
    self.title = title
    self.position = position
  }
  
}

extension SGCountdownCell {
  
  public func configure(with model: SGCountdownCellModel) {
    showAsCanceled = model.isCancelled
    
    self.configure(title: model.title
      , subtitle: model.subtitle
      , subsubtitle: model.subsubtitle
      , icon: model.icon
      , iconImageURL: model.iconImageURL
      , timeToCountdownTo: model.time
      , position: model.position
      , stripColor: model.color)
    
    // We may have alert.
    configureAlertView(with: model.alerts)
    
    // We may need to show accessibility info.
    configureAccessibleView(asEnabled: model.isWheelchairEnabled, isAccessible: model.isAccessible)
  }
  
  
  /// Configures the cell with the defined content. Note that, this configure the main
  /// part of the cell only. In order to configure the alert and accessibility parts
  /// of the cell, separate method calls are required.
  ///
  /// - Parameters:
  ///   - title: The title to be displayed in the first line. Doesn't need to wrap.
  ///   - subtitle: The subtitle to be displayed below. Can be long and should wrap.
  ///   - subsubtitle: An even smaller title displayed below subtitle.
  ///   - icon: Image to be displayed on the left.
  ///   - iconImageURL: URL to remote image to replace icon
  ///   - timeToCountdownTo: Optional time to countdown to/from. If this is in the past, the cell should appear faded.
  ///   - position: Position of this cell relative to the cells around it.
  ///   - stripColor: Optional color to display a coloured strip under the icon.
  @objc public func configure(title: NSAttributedString, subtitle: String?, subsubtitle: String?, icon: SGKImage?, iconImageURL: URL?, timeToCountdownTo: Date?, position: SGKGrouping, stripColor: SGKColor?) {
    
    _resetContents()
    
    _configure(withTitle: title
      , subtitle: subtitle
      , subsubtitle: subsubtitle
      , icon: icon
      , iconImageURL: iconImageURL
      , timeToCountdownTo: timeToCountdownTo
      , position: position
      , strip: stripColor)
    
    // The cell doesn't show alert by default.
    configureAlertView(with: [])
  }
  
  
  @objc public func configureAlertView(with alerts: [Alert]) {
    alertIconWidth.constant = alerts.isEmpty ? 0 : 20
    alertViewTopConstraint.constant = alerts.isEmpty ? 0 : 8
    alertViewBottomConstraint.constant = alerts.isEmpty ? 0 : 8
    showButtonHeightConstraint.constant = alerts.isEmpty ? 0 : showButton.intrinsicContentSize.height
    
    showButton.isHidden = alerts.isEmpty
    alertSymbol.isHidden = alerts.isEmpty
    alertLabel.isHidden = alerts.isEmpty    
    alertSeparator.isHidden = alerts.isEmpty
    
    guard let mostSevere = alerts.first else {
      return
    }
    
    alertSymbol.image = STKInfoIcon.image(for: mostSevere.infoIconType, usage: .normal)
    alertLabel.text = alerts.count == 1 ? mostSevere.text : Loc.Alerts(alerts.count) ?? ""
    showButton.setTitle(Loc.Show, for: .normal)
    
    let disposeBag = objcDisposeBag.disposeBag    
    showButton.rx.tap
      .subscribe(onNext: { [unowned self] in
        guard self.alertPresentationHandler != nil else { return }
        self.alertPresentationHandler(alerts)
      })
      .disposed(by: disposeBag)
  }
  
  
  public func configureAccessibleView(asEnabled isEnabled: Bool, isAccessible: Bool?) {
    accessibleIcon.isHidden = !isEnabled
    accessibleSeparator.isHidden = !isEnabled
    
    guard isEnabled else { return }
    
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
    
    accessibleIcon.image = info.icon
    accessibleLabel.text = info.text
  }
  
  
  @objc public func addViewToFootnote(_ view: UIView) {
    // Make sure we start clean.
    for subview in footnoteView.subviews {
      subview.removeFromSuperview()
    }
    
    // Keep some space between footnote and the rest of the labels
    centerMainStack.spacing = 3
    
    footnoteView.isHidden = false
    footnoteView.addSubview(view)
    
    // Hook up constraints.
    view.translatesAutoresizingMaskIntoConstraints = false
    
    if #available(iOS 9.0, *) {
      view.leadingAnchor.constraint(equalTo: footnoteView.leadingAnchor).isActive = true
      view.topAnchor.constraint(equalTo: footnoteView.topAnchor).isActive = true
      footnoteView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
      footnoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    } else {
      let leadingSpace = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: footnoteView, attribute: .leading, multiplier: 1, constant: 0)
      let topSpace = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: footnoteView, attribute: .top, multiplier: 1, constant: 0)
      let trailingSpace = NSLayoutConstraint(item: footnoteView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
      let bottomSpace = NSLayoutConstraint(item: footnoteView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
      footnoteView.addConstraints([leadingSpace, topSpace, trailingSpace, bottomSpace])
    }
  }
}
