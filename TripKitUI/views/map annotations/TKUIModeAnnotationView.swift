//
//  TKUIModeAnnotationView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
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
      circle.layer.borderColor = UIColor.white.cgColor
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
      imageView.tintColor = .white
      
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
    guard let identifier = self.identifier else { return TKStyleManager.globalTintColor() }
    
    switch identifier {
    case "in_air":            return #colorLiteral(red: 0.2354567349, green: 0.6183182597, blue: 0.5550506115, alpha: 1)
    case "pt_pub_bus":        return #colorLiteral(red: 0, green: 0.7074869275, blue: 0.3893686533, alpha: 1)
    case "pt_pub_coach":      return #colorLiteral(red: 0.3531380296, green: 0.6268352866, blue: 1, alpha: 1)
    case "pt_pub_train":      return #colorLiteral(red: 0.4003433585, green: 0.3975370526, blue: 0.7013071179, alpha: 1)
    case "pt_pub_subway":     return #colorLiteral(red: 0.6026608944, green: 0.3418461382, blue: 0.614194572, alpha: 1)
    case "pt_pub_tram":       return #colorLiteral(red: 0.9155990481, green: 0.6139323115, blue: 0.2793464363, alpha: 1)
    case "pt_pub_ferry":      return #colorLiteral(red: 0.3049013913, green: 0.617303133, blue: 0.8455126882, alpha: 1)
    case "pt_pub_cablecar":   return #colorLiteral(red: 0.8532444835, green: 0.3551393449, blue: 0.2957291603, alpha: 1)
    case "pt_pub_funicular":  return #colorLiteral(red: 0.4494780302, green: 0.664527297, blue: 0.954687655, alpha: 1)
    case "pt_pub_monorail":   return #colorLiteral(red: 0.8918713927, green: 0.7548664212, blue: 0.08011957258, alpha: 1)
    case "ps_tax":            return #colorLiteral(red: 0.892275691, green: 0.8211820722, blue: 0.07182558626, alpha: 1)
    case "me_car":            return #colorLiteral(red: 0.2567383349, green: 0.5468673706, blue: 0.9439687133, alpha: 1) // parking
    case "me_car-s":          return #colorLiteral(red: 0.4492250085, green: 0.6646941304, blue: 0.9505276084, alpha: 1)
    default: return TKStyleManager.globalTintColor()
    }
    
  }
  
}
