//
//  TKUIAttributionView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 24/10/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

public class TKUIAttributionView: UIView {
  
  public enum Alignment {
    case leading
    case trailing
    case center
  }

  public enum Wording {
    case poweredBy
    case dataProvidedBy
    case mapBy
  }
  
  public enum Style {
    /// Regular use, typically on a background colour
    case regular
    
    /// Meant for displaying over a map
    case mapAnnotation
  }
  
  @IBOutlet public weak var title: UILabel!
  @IBOutlet public weak var logo: UIImageView!
  
  public var contentAlignment: Alignment = .leading
  
  public var style: Style = .regular
  
  public init(contentAlignment: Alignment = .leading) {
    self.contentAlignment = contentAlignment
    super.init(frame: .zero)
    didInit()
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  fileprivate func didInit() {
    backgroundColor = .tkBackground
    
    let label = UILabel()
    label.numberOfLines = 0
    label.font = TKStyleManager.customFont(forTextStyle: .footnote)
    label.backgroundColor = .clear
    label.textColor = .tkLabelSecondary
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    title = label
    
    let imageView = UIImageView()
    imageView.backgroundColor = .clear
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(imageView)
    logo = imageView
    
    imageView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 4).isActive = true
    imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 12).isActive = true
    imageView.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
    imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    
    switch contentAlignment {
    case .leading:
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
      trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor, constant: 16).isActive = true
    case .trailing:
      label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8).isActive = true
      trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
    case .center:
      label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8).isActive = true
      trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor, constant: 8).isActive = true
      label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
  }
  
  // MARK: - Creating view
  
  public static func newView(title: String, icon: UIImage? = nil, iconURL: URL? = nil, url: URL? = nil, alignment: Alignment = .leading, wording: Wording, style: Style = .regular) -> TKUIAttributionView {
    let view = TKUIAttributionView(contentAlignment: alignment)
    
    let font: UIFont
    switch style {
    case .regular: font = TKStyleManager.semiboldCustomFont(forTextStyle: .footnote)
    case .mapAnnotation: font = TKStyleManager.semiboldCustomFont(forTextStyle: .caption2)
    }
    
    if let icon = icon {
      // Powered by `provider` where provider logo is used.
      // Provider logo is provided locally, e.g., TripGo.
      view.title.text = Loc.PoweredBy
      view.logo.image = icon
      view.title.isUserInteractionEnabled = false
      view.title.font = font
    } else if let iconURL = iconURL {
      // Powered by `provider` where provider logo is used.
      view.title.text = Loc.PoweredBy
      view.logo.setImage(with: iconURL)
      view.title.isUserInteractionEnabled = false
      view.title.font = font

    } else {
      // Powered by `provider`, where provider is a text.
      let plain: String
      switch wording {
      case .poweredBy: plain = Loc.PoweredBy(title)
      case .dataProvidedBy: plain = Loc.DataProvided(by: title)
      case .mapBy: plain = Loc.MapBy(title)
      }
      
      let attributedTitle = NSMutableAttributedString(string: plain)
      attributedTitle.addAttribute(.font, value: font, range: NSRange(location: 0, length: plain.count))
      attributedTitle.addAttribute(.foregroundColor, value: UIColor.tkLabelSecondary, range: NSRange(location: 0, length: plain.count))
      
      let range = (plain as NSString).range(of: title)
      if let url = url, range.location != NSNotFound {
        attributedTitle.addAttribute(.link, value: url, range: range)
        view.title.isUserInteractionEnabled = true
      } else {
        switch style {
        case .regular:
          attributedTitle.addAttribute(.foregroundColor, value: UIColor.tkAppTintColor, range: range)
        case .mapAnnotation:
          attributedTitle.addAttribute(.underlineStyle, value: NSNumber(value: NSUnderlineStyle.single.rawValue), range: range)
        }
        view.title.isUserInteractionEnabled = false
      }
      
      view.logo.image = nil
      view.title.attributedText = attributedTitle
    }
    
    return view
  }
  
  public static func newView(_ sources: [TKAPI.DataAttribution], wording: Wording = .dataProvidedBy, fitsIn view: UIView? = nil, alignment: Alignment = .leading, style: Style = .regular) -> TKUIAttributionView? {
    guard !sources.isEmpty else { return nil }
    
    let names = sources.map(\.provider.name)
    guard let title = ListFormatter().string(from: names) else { return nil }

    let attributionView = newView(title: title + ".", alignment: alignment, wording: wording, style: style)
    
    if let containingView = view {
      attributionView.frame.size.width = containingView.frame.width
      attributionView.frame.size.height = attributionView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    return attributionView
  }
  
  public static func newView(_ attribution: TKAPI.DataAttribution, wording: Wording = .poweredBy, fitsIn view: UIView? = nil, alignment: Alignment = .leading) -> TKUIAttributionView {
    let attributionView = newView(title: attribution.provider.name, iconURL: attribution.provider.remoteIconURL, url: attribution.provider.website, alignment: alignment, wording: wording)
    
    if let containingView = view {
      attributionView.frame.size.width = containingView.frame.width
      attributionView.setNeedsLayout()
      attributionView.layoutIfNeeded()
      attributionView.frame.size.height = attributionView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    return attributionView
  }
  
}

