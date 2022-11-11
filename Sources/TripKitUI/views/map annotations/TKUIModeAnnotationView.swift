//
//  TKUIModeAnnotationView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TripKit

import MapKit

/// A annotation to display transport locations on the map.
///
/// Uses the mode icon in the centre, coloured circle around it. Also works with
/// remote icons.
public class TKUIModeAnnotationView: MKAnnotationView {
  
  public static let defaultSize = CGSize(width: 19, height: 19)

  private weak var backgroundCircle: UIView!
  private weak var imageView: UIImageView!
  private weak var remoteImageView: UIImageView?

  @objc
  public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    
    frame.size = TKUIModeAnnotationView.defaultSize
    centerOffset = CGPoint(x: 0, y: frame.height * -0.5)
    isOpaque = true
    backgroundColor = .clear
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override var annotation: MKAnnotation? {
    didSet {
      guard let stop = annotation as? TKUIModeAnnotation else { return }
      update(for: stop)
    }
  }
  
  private func update(for annotation: TKUIModeAnnotation) {
    if backgroundCircle == nil {
      let circleFrame = CGRect(origin: .zero, size: TKUIModeAnnotationView.defaultSize)
      let circle = UIView(frame: circleFrame)
      circle.layer.cornerRadius = circleFrame.width / 2
      circle.layer.borderWidth = 1
      circle.layer.borderColor = UIColor.tkBackground.cgColor
      insertSubview(circle, at: 0)
      backgroundCircle = circle
    }
    
    guard let modeInfo = annotation.modeInfo else {
      assertionFailure("Missing mode info")
      return
    }

    backgroundCircle.backgroundColor = modeInfo.color ?? modeInfo.defaultColor
    
    guard let image = modeInfo.image else {
      assertionFailure("Couldn't create image for \(annotation)")
      return
    }
    if let imageView = self.imageView, imageView.image?.size == image.size {
      imageView.image = image
    } else {
      self.imageView?.removeFromSuperview()
      
      let imageView = UIImageView(image: image)
      imageView.frame = backgroundCircle.frame.insetBy(dx: 3, dy: 3)
      imageView.tintColor = .tkBackground
      
      addSubview(imageView)
      self.imageView = imageView
    }
    
    // Template images fit into the normal image and we can use the regular
    // list style. Other's we specifically ask for the map icon, which then
    // replaces the circle and default image.
    showRemoteOnly = false
    if modeInfo.imageURL != nil {
      if modeInfo.remoteImageIsTemplate {
        remoteImageView?.removeFromSuperview()
        imageView.setImage(with: modeInfo.imageURL(type: .listMainMode), asTemplate: true, placeholder: image)
        
      } else {
        if remoteImageView == nil {
          let remoteImage = UIImageView(frame: CGRect(origin: .zero, size: TKUIModeAnnotationView.defaultSize))
          remoteImage.isHidden = true // will be shown on success
          addSubview(remoteImage)
          remoteImageView = remoteImage
        }
        remoteImageView?.setImage(with: modeInfo.imageURL(type: .mapIcon)) { [weak self] success in
          self?.showRemoteOnly = success
        }
      }

    } else {
      remoteImageView?.removeFromSuperview()
    }
  }
  
  private var showRemoteOnly: Bool = false {
    didSet {
      backgroundCircle.isHidden = showRemoteOnly
      imageView.isHidden = showRemoteOnly
      remoteImageView?.isHidden = !showRemoteOnly
    }
  }
  
}

fileprivate extension TKModeInfo {
  
  var defaultColor: TKColor {
    guard
      let identifier = self.identifier
    else { return TKStyleManager.globalTintColor }
    return TKTransportMode.color(for: identifier)
  }
  
}
