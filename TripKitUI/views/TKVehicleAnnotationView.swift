//
//  TKVehicleAnnotationView.swift
//  Pods
//
//  Created by Kuan Lun Huang on 3/11/2016.
//
//

import Foundation

import RxSwift
import MapKit
import SGPulsingAnnotationView

public class TKVehicleAnnotationView: SVPulsingAnnotationView {
  
  private weak var vehicleShape: VehicleView?
  private weak var vehicleImageView: UIImageView?
  private weak var label: UILabel!
  private weak var wrapper: UIView!
  
  private let vehicleWidth = CGFloat(30)
  private let vehicleHeight = CGFloat(15)
  
  private let disposeBag = DisposeBag()
  
  override public var annotation: MKAnnotation? {
    didSet {
      updated(with: annotation)
    }
  }
  
  // MARK: -
  
  public init(with annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    updated(with: annotation)
    
    // Vehicle color needs to change following real-time update.
    if let vehicle = annotation as? Vehicle {
      vehicle.rx.observeWeakly(NSNumber.self, "occupancyRaw")
        .debug()
        .subscribe(onNext: { [weak self] rawOccupancy in
          guard
            let `self` = self,
            let rawValue = rawOccupancy,
            let occupancy = TKOccupancy(rawValue: rawValue.intValue),
            let color = occupancy.color,
            let vehicleView = self.vehicleShape else {
            return
          }
          
          vehicleView.color = color
        })
        .addDisposableTo(disposeBag)
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - UI Update
  
  public func aged(by factor: CGFloat) {
    wrapper.alpha = 1 - factor
    
    if factor > 0.9 {
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
  
  private func updated(with annotation: MKAnnotation?) {
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
  
  // MARK: - Orientation.
  
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
  
  // MARK: - Helpers
  
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
