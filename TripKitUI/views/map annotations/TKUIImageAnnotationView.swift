//
//  TKUIImageAnnotationView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

/// A annotation to display a simple image on a map, which might have been
/// downloaded from a server.
@objc
public class TKUIImageAnnotationView: MKAnnotationView {
  
  private weak var imageView: UIImageView!
  
  @objc
  public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    
    isOpaque = true
    backgroundColor = .clear
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override var annotation: MKAnnotation? {
    didSet {
      guard let image = annotation as? TKUIImageAnnotation else { return }
      update(for: image)
    }
  }
  
  private func update(for annotation: TKUIImageAnnotation) {
    guard let image = annotation.image else { return }

    if let imageView = self.imageView, imageView.image?.size == image.size {
      imageView.image = image
    } else {
      self.imageView?.removeFromSuperview()
      
      let imageView = UIImageView(image: image)
      addSubview(imageView)
      self.imageView = imageView

      frame.size = image.size
      centerOffset = CGPoint(x: 0, y: frame.height * -0.5)
    }
    
    if annotation.imageURL != nil {
      imageView.setImage(with: annotation.imageURL, placeholder: image)
    }
  }
}
