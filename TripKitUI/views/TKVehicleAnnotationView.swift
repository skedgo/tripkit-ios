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
        .filter { $0 != nil }
        .map { rawOccupancy -> UIColor? in
          let occupancy = TKOccupancy(rawValue: rawOccupancy!.intValue)
          return occupancy?.color
        }
        .subscribe(onNext: { [weak self] color in
          guard let `self` = self else { return }
          self.vehicleShape?.color = color
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
    wrapper.backgroundColor = .clear
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
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    let textColor: UIColor
    if (red + green + blue) * alpha / 3 < 0.5 {
      textColor = .white
    } else {
      textColor = .black
    }
    
    return textColor
  }
}
