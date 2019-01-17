//
//  TKUIAttributionView.swift
//  TripGo
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
  }

  public enum Wording {
    case poweredBy
    case dataProvidedBy
  }
  
  @IBOutlet public weak var title: UITextView!
  @IBOutlet public weak var logo: UIImageView!
  
  public var contentAlignment: Alignment = .leading
  
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
    backgroundColor = TKStyleManager.backgroundColorForTileList()
    
    let textView = UITextView()
    textView.font = TKStyleManager.systemFont(size: 15)
    textView.backgroundColor = .clear
    textView.textColor = TKStyleManager.darkTextColor()
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.isPagingEnabled = false
    textView.dataDetectorTypes = [.phoneNumber, .link, .address]
    textView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textView)
    title = textView
    
    textView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    textView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    
    let imageView = UIImageView()
    imageView.backgroundColor = .clear
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(imageView)
    logo = imageView
    
    imageView.leadingAnchor.constraint(equalTo: textView.trailingAnchor).isActive = true
    imageView.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
    imageView.heightAnchor.constraint(equalTo: textView.heightAnchor).isActive = true
    
    switch contentAlignment {
    case .leading:
      textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
      trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor, constant: 8).isActive = true
    case .trailing:
      textView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8).isActive = true
      trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
    }
  }
  
  // MARK: - Creating view
  
  public class func newView(title: String, iconURL: URL? = nil, url: URL? = nil, alignment: Alignment = .leading, wording: Wording) -> TKUIAttributionView {
    let view = TKUIAttributionView(contentAlignment: alignment)
    
    if let iconURL = iconURL {
      // Powered by `provider` where provider logo is used.
      view.title.text = Loc.PoweredBy
      view.logo.setImage(with: iconURL)
      view.title.isUserInteractionEnabled = false
      view.title.font = TKStyleManager.systemFont(size: 13)

    } else {
      // Powered by `provider`, where provider is a text.
      let plain: String
      switch wording {
      case .poweredBy: plain = Loc.PoweredBy(title)
      case .dataProvidedBy: plain = Loc.DataProvided(by: title)
      }
      
      let attributedTitle = NSMutableAttributedString(string: plain)
      attributedTitle.addAttribute(.font, value: TKStyleManager.systemFont(size: 13), range: NSRange(location: 0, length: plain.count))
      
      let range = (plain as NSString).range(of: title)
      if let url = url, range.location != NSNotFound {
        attributedTitle.addAttribute(.link, value: url, range: range)
        view.title.isUserInteractionEnabled = true
      } else {
        attributedTitle.addAttribute(.foregroundColor, value: TKStyleManager.globalTintColor(), range: range)
        view.title.isUserInteractionEnabled = false
      }
      
      view.logo.image = nil
      view.title.attributedText = attributedTitle
    }
    
    return view
  }
  
  public class func newView(_ sources: [API.DataAttribution], fitsIn view: UIView? = nil) -> TKUIAttributionView? {
    guard !sources.isEmpty else { return nil }
    
    let names = sources.map { $0.provider.name }.joined(separator: ", ")

    let attributionView = newView(title: names, wording: .dataProvidedBy)
    
    if let containingView = view {
      attributionView.frame.size.width = containingView.frame.width
      attributionView.frame.size.height = attributionView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    return attributionView
  }
  
  public class func newView(_ attribution: API.DataAttribution, fitsIn view: UIView? = nil) -> TKUIAttributionView {
    let attributionView = newView(title: attribution.provider.name, iconURL: attribution.provider.remoteIconURL, url: attribution.provider.website, wording: .poweredBy)
    
    if let containingView = view {
      attributionView.frame.size.width = containingView.frame.width
      attributionView.setNeedsLayout()
      attributionView.layoutIfNeeded()
      attributionView.frame.size.height = attributionView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    return attributionView
  }
  
}

