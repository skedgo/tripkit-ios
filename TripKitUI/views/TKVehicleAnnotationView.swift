//
//  TKVehicleAnnotationView.swift
//  Pods
//
//  Created by Kuan Lun Huang on 3/11/2016.
//
//

import Foundation

import MapKit
import SGPulsingAnnotationView

public class TKVehicleAnnotationView: SVPulsingAnnotationView {
  
  private weak var vehicleShape: VehicleView?
  private weak var vehicleImageView: UIImageView?
  private weak var label: UILabel!
  private weak var wrapper: UIView!
  
  private let vehicleWidth = CGFloat(30)
  private let vehicleHeight = CGFloat(15)
  
  // MARK: - Initialisers
  
  public init(with annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    update(for: annotation)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var annotation: MKAnnotation? {
    didSet {
      update(for: annotation)
    }
  }
  
  // MARK: - View drawing.
  
  private func update(for annotation: MKAnnotation?) {
    subviews.forEach {
      $0.removeFromSuperview()
    }
    
    guard
      let annotation = annotation,
      let vehicle = annotation as? Vehicle else {
      return // happens on getting removed.
    }
    
    calloutOffset = CGPoint(x: 0, y: 10)
    frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    backgroundColor = UIColor.clear
    isOpaque = false
    
    showDot = false
    
    // The wrapper
    let wrapper = UIView(frame: frame)
    wrapper.backgroundColor = UIColor.clear
    wrapper.isOpaque = false
    
    // The vehicle
    let vehicleRect = CGRect(x: (frame.width - vehicleWidth)/2, y: (frame.height - vehicleHeight)/2, width: vehicleWidth, height: vehicleHeight)
    
    let serviceColor: UIColor
    if let color = vehicle.serviceColor {
      serviceColor = color
    } else {
      serviceColor = UIColor.black
    }
    
    var vehicleView: UIView?
    
    if let iconUrlString = vehicle.icon {
      let URL = SVKServer.imageURL(forIconFileNamePart: iconUrlString, of: .vehicle)
      if URL != nil {
        let vehicleImageView = UIImageView(frame: vehicleRect)
        vehicleImageView.contentMode = .scaleAspectFit
        vehicleImageView.setImageWith(URL)
        vehicleView = vehicleImageView
        self.vehicleImageView = vehicleImageView
      }
    }
    
    if vehicleView == nil {
      let vehicleShape = VehicleView(frame: vehicleRect, color: serviceColor)
      vehicleView = vehicleShape
      self.vehicleShape = vehicleShape
    }
    
    // Here, we are guaranteed to have non-nil vehicle view
    vehicleView!.alpha = vehicle.displayAsPrimary ? 1 : 0.66
    wrapper.addSubview(vehicleView!)
    
    // The label
    var rect = vehicleRect.insetBy(dx: 2, dy: 2)
    rect.size.width -= rect.height/2
    let label = UILabel(frame: rect)
    label.text = vehicle.serviceNumber
    label.backgroundColor = UIColor.clear
    label.isOpaque = false
    label.textAlignment = .center
    label.textColor = textColorForBackgroundColor(serviceColor)
    label.font = SGStyleManager.systemFont(withSize: 10)
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.75
    wrapper.addSubview(label)
    self.label = label
    
    // Add wrapper
    addSubview(wrapper)
    self.wrapper = wrapper
    
    // Rotate it
    if let bearing = vehicle.bearing?.floatValue {
      rotateVehicle(bearingAngle: CLLocationDirection(bearing))
    }
    
  }
  
  public func rotateVehicle(bearingAngle: CLLocationDirection) {
    vehicleShape?.setNeedsDisplay()
    vehicleImageView?.setNeedsDisplay()
    
    // rotate the wrapper
    wrapper.rotate(forBearing: CGFloat(bearingAngle))
    
    // flip the label
    if bearingAngle > 180 {
      label.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
    } else {
      label.transform = CGAffineTransform.identity
    }
  }
  
  public func rotateVehicle(headingAngle: CLLocationDirection, bearingAngle: CLLocationDirection) {
    rotateVehicle(bearingAngle: bearingAngle - headingAngle)
  }
  
  public func update(for agingFactor: CGFloat) {
    wrapper.alpha = 1 - agingFactor
    
    if agingFactor > 0.9 {
      if delayBetweenPulseCycles != Double.infinity {
        delayBetweenPulseCycles = Double.infinity
        setNeedsLayout()
      }
    } else {
      if delayBetweenPulseCycles == Double.infinity {
        delayBetweenPulseCycles = 1
        setNeedsLayout()
      }
    }
  }
  
  private func textColorForBackgroundColor(_ color: UIColor) -> UIColor {
    let red = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
    let green = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
    let blue = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
    let alpha = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
    
    color.getRed(red, green: green, blue: blue, alpha: alpha)
    
    let color: UIColor
    
    if (red.pointee + green.pointee + blue.pointee) * alpha.pointee / 3 < 0.5 {
      color = UIColor.white
    } else {
      color = UIColor.black
    }
    
    red.deallocate(capacity: 1)
    green.deallocate(capacity: 1)
    blue.deallocate(capacity: 1)
    alpha.deallocate(capacity: 1)
    
    return color
  }
}
