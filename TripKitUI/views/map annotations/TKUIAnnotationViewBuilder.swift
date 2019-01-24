//
//  AnnotationViewBuilder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/4/17.
//
//

import Foundation

import MapKit
import Kingfisher

@available(*, unavailable, renamed: "TKUIAnnotationViewBuilder")
public typealias TKAnnotationViewBuilder = TKUIAnnotationViewBuilder

open class TKUIAnnotationViewBuilder: NSObject {
  
  fileprivate var asLarge: Bool
  fileprivate var asTravelled: Bool = true
  fileprivate var heading: CLLocationDirection?
  fileprivate var alpha: CGFloat = 1
  fileprivate var preferMarker: Bool = false
  fileprivate var enableClustering: Bool = false
  fileprivate var drawStopAsCircle: Bool = true
  
  @objc public let annotation: MKAnnotation
  @objc public let mapView: MKMapView
  
  @objc(initForAnnotation:inMapView:)
  public init(for annotation: MKAnnotation, in mapView: MKMapView) {
    self.annotation = annotation
    self.mapView = mapView
    self.asLarge = annotation is StopVisits
    
    // TODO: Then also handle `regionDidChangeAnimated` as in RMM
    
    super.init()
  }
  
  @objc @discardableResult
  public func drawCircleAsTravelled(_ travelled: Bool) -> TKUIAnnotationViewBuilder {
    self.asTravelled = travelled
    return self
  }

  @objc @discardableResult
  public func drawCircleAsLarge(_ asLarge: Bool) -> TKUIAnnotationViewBuilder {
    self.asLarge = asLarge
    return self
  }

  @objc @discardableResult
  public func drawStopAsCircle(_ asCircle: Bool) -> TKUIAnnotationViewBuilder {
    self.drawStopAsCircle = asCircle
    return self
  }
  
  @objc @discardableResult
  public func withAlpha(_ alpha: CGFloat) -> TKUIAnnotationViewBuilder {
    self.alpha = alpha
    return self
  }
  
  @objc @discardableResult
  public func withHeading(_ heading: CLLocationDirection) -> TKUIAnnotationViewBuilder {
    self.heading = heading
    return self
  }
  
  @objc @discardableResult
  public func enableClustering(_ cluster: Bool) -> TKUIAnnotationViewBuilder {
    self.enableClustering = cluster
    return self
  }

  @objc @discardableResult
  public func preferMarker(_ prefer: Bool) -> TKUIAnnotationViewBuilder {
    self.preferMarker = prefer
    return self
  }

  
  @objc
  open func build() -> MKAnnotationView? {
    if #available(iOS 11, *), preferMarker, let glyphable = annotation as? TKGlyphableAnnotation {
      return build(for: glyphable, enableClustering: enableClustering)
    } else if let vehicle = annotation as? Vehicle {
      return build(for: vehicle)      
    } else if let timePoint = annotation as? TKDisplayableTimePoint, timePoint.prefersSemaphore {
      return buildSemaphore(for: timePoint)
    } else if let visit = annotation as? StopVisits {
      return buildCircle(for: visit)
    } else if drawStopAsCircle, let stop = annotation as? StopLocation {
      return buildCircle(for: stop)
    } else if let segment = annotation as? TKSegment {
      return buildSemaphore(for: segment)
    } else if let displayable = annotation as? TKDisplayablePoint {
      return build(for: displayable, enableClustering: enableClustering)
    }
    
    return nil
  }
  
}

// MARK: - Glyphable

private extension TKUIAnnotationViewBuilder {
  
  @available(iOS 11.0, *)
  private func build(for glyphable: TKGlyphableAnnotation, enableClustering: Bool) -> MKAnnotationView {
    let identifier = glyphable is MKClusterAnnotation ? "ClusterMarker" : "ImageMarker"
    
    let view: MKMarkerAnnotationView
    if let marker = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
      view = marker
      view.annotation = glyphable
    } else {
      view = MKMarkerAnnotationView(annotation: glyphable, reuseIdentifier: identifier)
    }
    
    view.glyphImage = glyphable.glyphImage
    view.markerTintColor = glyphable.glyphColor
    view.canShowCallout = annotation.title != nil
    
    // We may have remote icons
    if let url = glyphable.glyphImageURL {
      ImageDownloader.default.downloadImage(
        with: url,
        options: [.imageModifier(RenderingModeImageModifier(renderingMode: .alwaysTemplate))]
      ) { image, error, downloadedURL, _ in
        guard
          let image = image,
          let latest = view.annotation as? TKGlyphableAnnotation,
          latest.glyphImageURL == downloadedURL
          else { return }
        view.glyphImage = image
      }
    }
    
    if let displayable = glyphable as? TKDisplayablePoint {
      view.clusteringIdentifier = enableClustering && displayable.priority.rawValue < 500
        ? displayable.pointClusterIdentifier : nil
      view.displayPriority = displayable.priority
    }
    
    return view
  }
  
}

// MARK: - Vehicles

fileprivate extension TKUIAnnotationViewBuilder {
  fileprivate func build(for vehicle: Vehicle) -> MKAnnotationView {
    let identifier = "TKUIVehicleAnnotationView"
    
    let vehicleView: TKUIVehicleAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUIVehicleAnnotationView {
      vehicleView = recycled
      vehicleView.annotation = vehicle
    } else {
      vehicleView = TKUIVehicleAnnotationView(with: vehicle, reuseIdentifier: identifier)
    }
    
    vehicleView.rotateVehicle(heading: heading, bearing: vehicle.bearing?.doubleValue)
    vehicleView.annotationColor = #colorLiteral(red: 0.3696880937, green: 0.6858631968, blue: 0.2820466757, alpha: 1)
    vehicleView.aged(by: CGFloat(vehicle.ageFactor))
    
    vehicleView.canShowCallout = annotation.title != nil
    vehicleView.isEnabled = true
    
    return vehicleView
  }
}

fileprivate extension TKUIVehicleAnnotationView {
  func rotateVehicle(heading: CLLocationDirection?, bearing: CLLocationDirection?) {
    guard let bearing = bearing else { return }
    
    if let heading = heading {
      rotateVehicle(headingAngle: heading, bearingAngle: bearing)
    } else {
      rotateVehicle(bearingAngle: bearing)
    }
  }
}

// MARK: - Semaphores

fileprivate extension TKUIAnnotationViewBuilder {
  
  fileprivate func semaphoreView(for annotation: MKAnnotation) -> TKUISemaphoreView {
    let identifier = "Semaphore"
    
    let semaphoreView: TKUISemaphoreView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUISemaphoreView {
      semaphoreView = recycled
      semaphoreView.update(for: annotation, heading: heading)
    } else {
      semaphoreView = TKUISemaphoreView(annotation: annotation, reuseIdentifier: identifier, heading: heading)
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

  fileprivate func buildSemaphore(for point: TKDisplayableTimePoint) -> MKAnnotationView {
    let semaphoreView = self.semaphoreView(for: point)
    
    // Set time stamp on the side opposite to direction of travel
    let side = semaphoreLabel(for: point.bearing?.doubleValue)
    
    if let frequency = point.frequency {
      semaphoreView.setFrequency(frequency, onSide: side)
    } else {
      semaphoreView.setTime(point.time, isRealTime: point.timeIsRealTime, in: point.timeZone, onSide: side)
    }

    semaphoreView.canShowCallout = annotation.title != nil
    semaphoreView.isEnabled = true
    
    return semaphoreView
  }
  
  fileprivate func buildSemaphore(for segment: TKSegment) -> MKAnnotationView {
    let semaphoreView = self.semaphoreView(for: segment)
    
    // Only public transport get the time stamp. And they get it on the side opposite to the
    // travel direction.
    let side: SGSemaphoreLabel
    if segment.isPublicTransport {
      side = semaphoreLabel(for: segment.bearing?.doubleValue)
      
    } else if segment.isTerminal {
      let fromCoordinate = segment.trip.request.fromLocation.coordinate
      let toCoordinate = segment.trip.request.toLocation.coordinate
      let isLeft = fromCoordinate.longitude > toCoordinate.longitude
      side = isLeft ? .onLeft : .onRight
      
    } else {
      side = .disabled
    }
    
    if let frequency = segment.frequency {
      semaphoreView.setFrequency(frequency, onSide: side)
    } else if let departure = segment.departureTime {
      semaphoreView.setTime(departure, isRealTime: segment.timesAreRealTime, in: (segment as TKDisplayableTimePoint).timeZone, onSide: side)
    }
    
    semaphoreView.canShowCallout = annotation.title != nil
    semaphoreView.isEnabled = true
    
    return semaphoreView
  }
  
}

fileprivate extension TKUISemaphoreView {
  
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

// MARK: - Circles

fileprivate extension TKUIAnnotationViewBuilder {
  
  fileprivate func buildCircle(for visit: StopVisits) -> MKAnnotationView {
    let color: TKColor?
    if asTravelled, let serviceColor = visit.service.color as? TKColor {
      color = serviceColor
    } else {
      color = nil
    }
    return buildCircle(for: visit, color: color)
  }
  
  fileprivate func buildCircle(for annotation: MKAnnotation, color: TKColor? = nil) -> MKAnnotationView {
    let identifier = asLarge ? "LargeCircleView" : "SmallCircleView"
    
    let circleView: TKUICircleAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUICircleAnnotationView {
      circleView = recycled
      circleView.annotation = annotation
    } else {
      circleView = TKUICircleAnnotationView(annotation: annotation, drawLarge: asLarge, reuseIdentifier: identifier)
    }
    
    circleView.isFaded = !asTravelled
    circleView.circleColor = color ?? .routeDashColorNonTravelled
    circleView.alpha = alpha
    circleView.setNeedsDisplay()

    circleView.canShowCallout = annotation.title != nil
    circleView.isEnabled = true
    
    if #available(iOS 11.0, *) {
      circleView.displayPriority = asLarge ? .defaultHigh : .defaultLow
    }
    
    return circleView
  }
  
}

// MARK: - Generic annotations

fileprivate extension TKUIAnnotationViewBuilder {

  fileprivate func build(for displayable: TKDisplayablePoint, enableClustering: Bool) -> MKAnnotationView {
    
    let identifier: String
    if #available(iOS 11, *), displayable is MKClusterAnnotation {
      identifier = "ClusterAnnotationIdentifier"
    } else {
      identifier = "ImageAnnotationIdentifier"
    }
    
    let imageView: TKUIImageAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUIImageAnnotationView {
      imageView = recycled
      imageView.annotation = displayable
    } else {
      imageView = TKUIImageAnnotationView(annotation: displayable, reuseIdentifier: identifier)
    }
    
    imageView.alpha = 1
    imageView.leftCalloutAccessoryView = nil
    imageView.rightCalloutAccessoryView = nil
    imageView.canShowCallout = annotation.title != nil
    imageView.isEnabled = true
    
    if #available(iOS 11, *) {
      imageView.collisionMode = .circle
      imageView.clusteringIdentifier = enableClustering && displayable.priority.rawValue < 500 ? displayable.pointClusterIdentifier : nil
      imageView.displayPriority = displayable.priority
    }
    
    return imageView
  }
  
}

@available(iOS 11.0, *)
fileprivate extension TKDisplayablePoint {
  
  var priority: MKFeatureDisplayPriority {
    if let mode = self as? TKModeCoordinate, let priority = mode.priority {
      return MKFeatureDisplayPriority(priority)
    } else {
      return .required
    }
  }
  
}

// MARK: - Updating views with headings

public extension TKUIAnnotationViewBuilder {
  
  @objc public static func update(annotationView: MKAnnotationView, forHeading heading: CLLocationDirection) {
    
    if let vehicleView = annotationView as? TKUIVehicleAnnotationView, let vehicle = vehicleView.annotation as? Vehicle {
      vehicleView.rotateVehicle(heading: heading, bearing: vehicle.bearing?.doubleValue)
      
    } else if let semaphore = annotationView as? TKUISemaphoreView {
      
      let bearing: CLLocationDirection
      if let segment = annotationView.annotation as? TKSegment {
        bearing = segment.bearing?.doubleValue ?? 0
        
      } else if let timePoint = annotationView.annotation as? TKDisplayableTimePoint {
        bearing = timePoint.bearing?.doubleValue ?? 0
      } else {
        bearing = 0
      }
      semaphore.updateHead(forMagneticHeading: heading, andBearing: bearing)
      
    }
    
  }
  
}
