//
//  AnnotationViewBuilder.swift
//  Pods
//
//  Created by Adrian Schoenig on 21/4/17.
//
//

import Foundation

import MapKit

public class AnnotationViewBuilder: NSObject {
  
  fileprivate var asLarge: Bool
  fileprivate var asTravelled: Bool = true
  fileprivate var heading: CLLocationDirection?
  fileprivate var alpha: CGFloat = 1
  fileprivate var preferSemaphore: Bool = false
  
  let annotation: MKAnnotation
  let mapView: MKMapView
  
  @objc(initForAnnotation:inMapView:)
  public init(for annotation: MKAnnotation, in mapView: MKMapView) {
    self.annotation = annotation
    self.mapView = mapView
    self.asLarge = annotation is StopVisits
    
    // TODO: Also set alpha. As RouteMapManager.alphaForCircleAnnotations
    // TODO: Then also handle `regionDidChangeAnimated` as in RMM
    
    super.init()
  }
  
  @discardableResult
  public func drawCircleAsTravelled(_ travelled: Bool) -> AnnotationViewBuilder {
    self.asTravelled = travelled
    return self
  }

  @discardableResult
  public func drawCircleAsLarge(_ asLarge: Bool) -> AnnotationViewBuilder {
    self.asLarge = asLarge
    return self
  }

  @discardableResult
  public func withAlpha(_ alpha: CGFloat) -> AnnotationViewBuilder {
    self.alpha = alpha
    return self
  }
  
  @discardableResult
  public func withHeading(_ heading: CLLocationDirection) -> AnnotationViewBuilder {
    self.heading = heading
    return self
  }
  
  @discardableResult
  public func preferSemaphore(_ prefer: Bool) -> AnnotationViewBuilder {
    self.preferSemaphore = prefer
    return self
  }
  
  public func build() -> MKAnnotationView? {
    if let vehicle = annotation as? Vehicle {
      return build(for: vehicle)
    } else if let visit = annotation as? StopVisits {
      return preferSemaphore ? buildSemaphore(for: visit) : buildCircle(for: visit)
    } else if let stop = annotation as? StopLocation {
      return buildCircle(for: stop)
    } else if let segment = annotation as? TKSegment {
      return buildSemaphore(for: segment)
    } else if let displayable = annotation as? STKDisplayablePoint {
      return build(for: displayable)
    }
    
    return nil
  }
  
}

// MARK: Vehicles

fileprivate extension AnnotationViewBuilder {
  fileprivate func build(for vehicle: Vehicle) -> MKAnnotationView {
    let identifier = "VehicleAnnotationView"
    
    let vehicleView: TKVehicleAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKVehicleAnnotationView {
      vehicleView = recycled
      vehicleView.annotation = vehicle
    } else {
      vehicleView = TKVehicleAnnotationView(with: vehicle, reuseIdentifier: identifier)
    }
    
    vehicleView.rotateVehicle(heading: heading, bearing: vehicle.bearing?.doubleValue)
    vehicleView.annotationColor = UIColor(red: 0.31, green: 0.64, blue: 0.22, alpha: 1)
    vehicleView.aged(by: CGFloat(vehicle.ageFactor))
    
    vehicleView.canShowCallout = annotation.title != nil
    vehicleView.isEnabled = true
    
    return vehicleView
  }
}

fileprivate extension TKVehicleAnnotationView {
  func rotateVehicle(heading: CLLocationDirection?, bearing: CLLocationDirection?) {
    guard let bearing = bearing else { return }
    
    if let heading = heading {
      rotateVehicle(headingAngle: heading, bearingAngle: bearing)
    } else {
      rotateVehicle(bearingAngle: bearing)
    }
  }
}

// MARK: Semaphores

fileprivate extension AnnotationViewBuilder {
  
  fileprivate func semaphoreView(for annotation: MKAnnotation) -> SGSemaphoreView {
    let identifier = "Semaphore"
    
    let semaphoreView: SGSemaphoreView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SGSemaphoreView {
      semaphoreView = recycled
      semaphoreView.update(for: annotation, heading: heading)
    } else {
      semaphoreView = SGSemaphoreView(annotation: annotation, reuseIdentifier: identifier, heading: heading)
    }
    return semaphoreView
  }
  
  fileprivate func semaphoreLabel(for bearing: CLLocationDirection?) -> SGSemaphoreLabel {
    if let bearing = bearing, let heading = heading {
      return (bearing - heading) > 180 ? .onRight : .onLeft
    } else {
      return .onLeft
    }
  }

  fileprivate func buildSemaphore(for visit: StopVisits) -> MKAnnotationView {
    let semaphoreView = self.semaphoreView(for: visit)
    
    // Set time stamp on the side opposite to direction of travel
    let side = semaphoreLabel(for: visit.bearing?.doubleValue)
    semaphoreView.setTime(visit.departure, isRealTime: visit.service.isRealTime, in: visit.stop.region?.timeZone, onSide: side)

    semaphoreView.canShowCallout = annotation.title != nil
    semaphoreView.isEnabled = true
    
    return semaphoreView
  }
  
  fileprivate func buildSemaphore(for segment: TKSegment) -> MKAnnotationView {
    let semaphoreView = self.semaphoreView(for: segment)
    
    // Only public transport get the time stamp. And they get it on the side opposite to the
    // travel direction.
    let side: SGSemaphoreLabel
    if segment.isPublicTransport() {
      side = semaphoreLabel(for: segment.bearing?.doubleValue)
      
    } else if segment.isTerminal {
      let fromCoordinate = segment.trip.request.fromLocation.coordinate
      let toCoordinate = segment.trip.request.toLocation.coordinate
      let isLeft = fromCoordinate.longitude > toCoordinate.longitude
      side = isLeft ? .onLeft : .onRight
      
    } else {
      side = .disabled
    }
    
    if let frequency = segment.frequency() {
      semaphoreView.setFrequency(frequency, onSide: side)
    } else {
      semaphoreView.setTime(segment.departureTime, isRealTime: segment.timesAreRealTime(), in: (segment as STKDisplayableTimePoint).timeZone, onSide: side)
    }
    
    semaphoreView.canShowCallout = annotation.title != nil
    semaphoreView.isEnabled = true
    
    return semaphoreView
  }
  
}

fileprivate extension SGSemaphoreView {
  
  convenience init(annotation: MKAnnotation, reuseIdentifier: String, heading: CLLocationDirection?) {
    if let heading = heading {
      self.init(annotation: annotation, reuseIdentifier: reuseIdentifier, withHeading: heading)
    } else {
      self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
  }
  
  func update(for annotation: MKAnnotation, heading: CLLocationDirection?) {
    if let heading = heading {
      update(for: annotation, withHeading: heading)
    } else {
      update(for: annotation)
    }
  }

}

// MARK: Circles

fileprivate extension AnnotationViewBuilder {
  
  fileprivate func buildCircle(for visit: StopVisits) -> MKAnnotationView {
    let color: SGKColor?
    if asTravelled, let serviceColor = visit.service.color as? SGKColor {
      color = serviceColor
    } else {
      color = nil
    }
    return buildCircle(for: visit, color: color)
  }
  
  fileprivate func buildCircle(for stop: StopLocation) -> MKAnnotationView {
    return buildCircle(for: stop)
    
  }
  
  fileprivate func buildCircle(for annotation: MKAnnotation, color: SGKColor? = nil) -> MKAnnotationView {
    let identifier = asLarge ? "LargeCircleView" : "SmallCircleView"
    
    let circleView: CircleAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CircleAnnotationView {
      circleView = recycled
      circleView.annotation = annotation
    } else {
      circleView = CircleAnnotationView(annotation: annotation, drawLarge: asLarge, reuseIdentifier: identifier)
    }
    
    circleView.isFaded = !asTravelled
    circleView.circleColor = color ?? SGKTransportStyler.routeDashColorNontravelled()
    circleView.alpha = alpha
    circleView.setNeedsDisplay()

    circleView.canShowCallout = annotation.title != nil
    circleView.isEnabled = true
    
    return circleView
  }
  
}

// MARK: Generic annotations

fileprivate extension AnnotationViewBuilder {

  fileprivate func build(for displayable: STKDisplayablePoint) -> MKAnnotationView {
    
    let identifier = "ImageAnnotationIdenfifier"
    
    let imageView: ASImageAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ASImageAnnotationView {
      imageView = recycled
      imageView.annotation = annotation
    } else {
      imageView = ASImageAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    }
    
    imageView.alpha = 1
    imageView.leftCalloutAccessoryView = nil
    imageView.rightCalloutAccessoryView = nil

    imageView.canShowCallout = annotation.title != nil
    imageView.isEnabled = true
    
    return imageView
  }
  
}

// MARK: Updating views with headings

public extension AnnotationViewBuilder {
  
  public static func update(annotationView: MKAnnotationView, forHeading heading: CLLocationDirection) {
    
    if let vehicleView = annotationView as? TKVehicleAnnotationView, let vehicle = vehicleView.annotation as? Vehicle {
      vehicleView.rotateVehicle(heading: heading, bearing: vehicle.bearing?.doubleValue)
      
    } else if let semaphore = annotationView as? SGSemaphoreView {
      
      let bearing: CLLocationDirection
      if let segment = annotationView.annotation as? TKSegment {
        bearing = segment.bearing?.doubleValue ?? 0
        
      } else if let timePoint = annotationView.annotation as? STKDisplayableTimePoint {
        bearing = timePoint.bearing?.doubleValue ?? 0
      } else {
        bearing = 0
      }
      semaphore.updateHead(forMagneticHeading: heading, andBearing: bearing)
      
    }
    
  }
  
}
