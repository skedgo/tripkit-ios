//
//  TKUIVehicleAnnotationView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 3/11/2016.
//
//

import Foundation

import RxSwift
import MapKit

import TripKit

protocol TKUIVehicleAnnotation: MKAnnotation {
  var serviceColor: TKColor? { get }
  var icon: String? { get }
  var serviceNumber: String? { get }
  var bearing: NSNumber? { get }
  var componentsData: Data? { get }
}

extension TKUIVehicleAnnotation {
  var serviceColor: TKColor? { nil }
  var icon: String? { nil }
  var serviceNumber: String? { nil }
  var bearing: NSNumber? { nil }
  var componentsData: Data? { nil }
}

extension Vehicle: TKUIVehicleAnnotation {}

class TKUIVehicleAnnotationView: TKUIPulsingAnnotationView {
  
  private weak var vehicleShape: TKUIVehicleView?
  private weak var vehicleImageView: UIImageView?
  private weak var label: UILabel!
  private weak var wrapper: UIView!
  
  private let vehicleWidth = CGFloat(38)
  private let vehicleHeight = CGFloat(21)
  
  private let disposeBag = DisposeBag()
  
  override var annotation: MKAnnotation? {
    didSet {
      updated(with: annotation)
    }
  }
  
  // MARK: -
  
  init(with annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    updated(with: annotation)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - UI Update
  
  func aged(by factor: CGFloat) {
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
      let vehicle = annotation as? TKUIVehicleAnnotation else {
      return // happens on getting removed.
    }
    
    calloutOffset = CGPoint(x: 0, y: 10)
    frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    backgroundColor = UIColor.clear
    isOpaque = false
    
    // The wrapper
    let wrapper = UIView(frame: frame)
    wrapper.backgroundColor = .clear
    wrapper.isOpaque = false
    
    // The vehicle
    let vehicleRect = CGRect(x: (frame.width - vehicleWidth)/2, y: (frame.height - vehicleHeight)/2, width: vehicleWidth, height: vehicleHeight)
    
    let serviceColor = vehicle.serviceColor ?? .tkLabelPrimary
    
    let vehicleView: UIView
    
    if let iconUrlString = vehicle.icon, let url = TKServer.imageURL(iconFileNamePart: iconUrlString, iconType: .vehicle) {
      let vehicleImageView = UIImageView(frame: vehicleRect)
      vehicleImageView.contentMode = .scaleAspectFit
      vehicleImageView.setImage(with: url)
      vehicleView = vehicleImageView
      self.vehicleImageView = vehicleImageView
    } else {
      let vehicleShape = TKUIVehicleView(frame: vehicleRect, color: serviceColor)
      vehicleShape.layer.shadowColor = UIColor.black.cgColor
      vehicleShape.layer.shadowOpacity = 0.3
      vehicleShape.layer.shadowRadius = 3
      vehicleShape.layer.shadowOffset = CGSize(width: 0, height: 1)
      vehicleShape.layer.masksToBounds = false
      vehicleView = vehicleShape
      self.vehicleShape = vehicleShape
    }
    
    vehicleView.alpha = 1
    wrapper.addSubview(vehicleView)
    
    // The label
    var rect = vehicleRect.insetBy(dx: 2, dy: 2)
    rect.size.width -= rect.height/2
    let label = UILabel(frame: rect)
    label.text = vehicle.serviceNumber
    label.backgroundColor = UIColor.clear
    label.isOpaque = false
    label.textAlignment = .center
    label.textColor = textColorForBackgroundColor(serviceColor)
    label.font = TKStyleManager.semiboldCustomFont(forTextStyle: .caption2)
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
    
    observe(vehicle)
  }
  
  private func observe(_ vehicle: TKUIVehicleAnnotation) {
    guard let tkVehicle = vehicle as? Vehicle else { return }
    
    // Vehicle color needs to change following real-time update.
    tkVehicle.rx.observeWeakly(Data.self, "componentsData")
      .compactMap { data in
        guard let data else { return nil }
        let components = Vehicle.components(from: data)
        return TKAPI.VehicleOccupancy.average(in: components)?.0.color
      }
      .subscribe(onNext: { [weak self] color in
        self?.vehicleShape?.color = color
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Orientation.
  
  func rotateVehicle(bearingAngle: CLLocationDirection) {
    vehicleShape?.setNeedsDisplay()
    vehicleImageView?.setNeedsDisplay()
    
    // rotate the wrapper
    wrapper.rotate(bearing: CGFloat(bearingAngle))
    
    // flip the label
    if bearingAngle > 180 {
      label.transform = CGAffineTransform(rotationAngle: .pi)
    } else {
      label.transform = CGAffineTransform.identity
    }
  }
  
  func rotateVehicle(headingAngle: CLLocationDirection, bearingAngle: CLLocationDirection) {
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

#if DEBUG
class PreviewVehicle: NSObject, TKUIVehicleAnnotation {
  var coordinate: CLLocationCoordinate2D = .invalid
  var serviceNumber: String?
  
  init(serviceNumber: String? = nil) {
    self.serviceNumber = serviceNumber
  }
}

@available(iOS 17.0, *)
#Preview {
  let wrapper = UIView(frame: .init(x: 0, y: 0, width: 300, height: 600))
  let vehicleView = TKUIVehicleAnnotationView(with: PreviewVehicle(serviceNumber: "311"), reuseIdentifier: "")
  vehicleView.frame = .init(x: 50, y: 100, width: 50, height: 50)
  wrapper.addSubview(vehicleView)
  return wrapper
}
#endif
