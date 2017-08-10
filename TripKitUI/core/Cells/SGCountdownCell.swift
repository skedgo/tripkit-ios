//
//  SGCountdownCell.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 28/10/16.
//
//

import Foundation

public struct SGCountdownCellModel {
  
  public var title: NSAttributedString
  public var subtitle: String?
  public var subsubtitle: String?
  public var icon: UIImage?
  public var iconImageURL: URL?
  public var time: Date?
  public var parking: String?
  public var position: SGKGrouping
  public var color: UIColor?
  public var alertText: String?
  public var alertIconType: STKInfoIconType
  public var isCancelled: Bool = false
  public var isWheelchairEnabled: Bool = false
  public var isAccessible: Bool?
  
  public init(title: NSAttributedString, position: SGKGrouping = .edgeToEdge, alertIconType: STKInfoIconType = .none) {
    self.title = title
    self.position = position
    self.alertIconType = alertIconType
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
      , parkingAvailable: model.parking
      , position: model.position
      , stripColor: model.color)
    
    // We may have alert.
    configureAlertView(withText: model.alertText, andType: model.alertIconType)
    
    // We may need to show accessibility info.
    configureAccessibleView(asEnabled: model.isWheelchairEnabled, isAccessible: model.isAccessible)
  }
  
  
  /// Configures the cell with the defined content.
  ///
  /// - Parameters:
  ///   - title: The title to be displayed in the first line. Doesn't need to wrap.
  ///   - subtitle: The subtitle to be displayed below. Can be long and should wrap.
  ///   - subsubtitle: An even smaller title displayed below subtitle.
  ///   - icon: Image to be displayed on the left.
  ///   - iconImageURL: URL to remote image to replace icon
  ///   - timeToCountdownTo: Optional time to countdown to/from. If this is in the past, the cell should appear faded.
  ///   - parkingAvailable: Amount of parking to display
  ///   - position: Position of this cell relative to the cells around it.
  ///   - stripColor: Optional color to display a coloured strip under the icon.
  ///   - alert: Alert text
  ///   - alertIconType: Alert icon to display next to alert text
  public func configure(title: NSAttributedString, subtitle: String?, subsubtitle: String?, icon: SGKImage?, iconImageURL: URL?, timeToCountdownTo: Date?, parkingAvailable: String?, position: SGKGrouping, stripColor: SGKColor?) {
    
    _resetContents()
    
    _configure(withTitle: title
      , subtitle: subtitle
      , subsubtitle: subsubtitle
      , icon: icon
      , iconImageURL: iconImageURL
      , timeToCountdownTo: timeToCountdownTo
      , parkingAvailable: parkingAvailable
      , position: position
      , strip: stripColor)
  }
  
  
  public func configureAlertView(withText alertText: String?, andType alertType: STKInfoIconType) {
    if alertText?.isEmpty ?? true {
      alertLabel.text = nil
      alertSymbol.image = nil
    } else {
      alertLabel.text = alertText
      alertSymbol.image = STKInfoIcon.image(for: alertType, usage: .normal)
    }
  }
  
  
  public func configureAccessibleView(asEnabled isEnabled: Bool, isAccessible: Bool?) {
    accessibleIcon.isHidden = !isEnabled
    accessibleSeparator.isHidden = !isEnabled
    
    guard isEnabled else { return }
    
    var info: (icon: UIImage, text: String)
    
    switch isAccessible {
    case true?:
      info.icon = SGStyleManager.imageNamed("icon-wheelchair-accessible")
      info.text = Loc.WheelchairAccessible
    case false?:
      info.icon = SGStyleManager.imageNamed("icon-wheelchair-not-accessible")
      info.text = Loc.WheelchairNotAccessible
    default:
      info.icon = SGStyleManager.imageNamed("icon-wheelchair-unknow")
      info.text = Loc.WheelchairAccessibilityUnknown
    }
    
    accessibleIcon.image = info.icon
    accessibleLabel.text = info.text
  }
  
  
  public func addViewToFootnote(_ view: UIView) {
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
