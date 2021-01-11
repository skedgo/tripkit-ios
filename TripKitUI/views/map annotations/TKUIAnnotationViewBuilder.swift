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
  fileprivate var drawImageAnnotationAsCircle: Bool = false
  fileprivate var circleColor: UIColor? = nil

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
  public func circleColor(_ color: UIColor) -> TKUIAnnotationViewBuilder {
    self.circleColor = color
    return self
  }

  @objc @discardableResult
  public func drawCircleAsLarge(_ asLarge: Bool) -> TKUIAnnotationViewBuilder {
    self.asLarge = asLarge
    return self
  }

  @objc @discardableResult
  public func drawImageAnnotationAsCircle(_ asCircle: Bool) -> TKUIAnnotationViewBuilder {
    self.drawImageAnnotationAsCircle = asCircle
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

    if preferMarker, let glyphable = annotation as? TKUIGlyphableAnnotation {
      return build(for: glyphable, enableClustering: enableClustering)
    } else if let vehicle = annotation as? Vehicle {
      return build(for: vehicle)      

    } else if let timePoint = annotation as? TKUISemaphoreDisplayable, timePoint.semaphoreMode != .none {
      return buildSemaphore(for: timePoint)
    
    } else if let segment = annotation as? TKSegment {
      return buildSemaphore(for: segment)

    } else if let visit = annotation as? StopVisits {
      return buildCircle(for: visit)

    } else if let mode = annotation as? TKUIModeAnnotation {
      if drawImageAnnotationAsCircle {
        return buildCircle(for: annotation)
      } else {
        return build(for: mode, enableClustering: enableClustering)
      }
    
    } else if let image = annotation as? TKUIImageAnnotation {
      return build(for: image)
    
    } else if let query = annotation as? TKUIRoutingQueryAnnotation {
      return build(for: query)
    }
    
    return nil
  }
  
}

// MARK: - Glyphable

private extension TKUIAnnotationViewBuilder {
  
  private func build(for glyphable: TKUIGlyphableAnnotation, enableClustering: Bool) -> MKAnnotationView {
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
        options: [.imageModifier(RenderingModeImageModifier(renderingMode: .alwaysTemplate))],
        completionHandler:
          { result in
            guard
              let imageResult = try? result.get(),
              let latest = view.annotation as? TKUIGlyphableAnnotation,
              latest.glyphImageURL == imageResult.url
            else { return }
            view.glyphImage = imageResult.image
          }
      )
    }
    
    if let modeAnnotation = glyphable as? TKUIModeAnnotation {
      view.clusteringIdentifier =
        enableClustering && modeAnnotation.priority.rawValue < 500
        ? modeAnnotation.clusterIdentifier : nil
      view.displayPriority = asTravelled ? modeAnnotation.priority : .defaultLow
    }
    
    return view
  }
  
}

// MARK: - Vehicles

fileprivate extension TKUIAnnotationViewBuilder {
  func build(for vehicle: Vehicle) -> MKAnnotationView {
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
  
  func semaphoreView(for annotation: MKAnnotation) -> TKUISemaphoreView {
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
  
  func semaphoreLabel(for bearing: CLLocationDirection?) -> SGSemaphoreLabel {
    if let bearing = bearing, let heading = heading {
      return (bearing - heading) > 180 ? .onRight : .onLeft
    } else {
      return .onLeft
    }
  }

  func buildSemaphore(for point: TKUISemaphoreDisplayable, preferredSide: SGSemaphoreLabel? = nil) -> MKAnnotationView {
    let semaphoreView = self.semaphoreView(for: point as MKAnnotation)
    
    // Set time stamp on the side opposite to direction of travel
    let side = preferredSide ?? semaphoreLabel(for: point.bearing?.doubleValue)
    
    switch point.semaphoreMode {
    case .none:
      assertionFailure("Shouldn't have used a semaphore. Will use one with head only.")
      fallthrough

    case .headOnly:
      semaphoreView.setTime(nil, isRealTime: false, in: .current, onSide: side)

    case .headWithFrequency(let frequency):
      semaphoreView.setFrequency(frequency, onSide: side)

    case .headWithTime(let date, let timeZone, isRealTime: let isRealTime):
      semaphoreView.setTime(date, isRealTime: isRealTime, in: timeZone, onSide: side)
    }

    semaphoreView.canShowCallout = annotation.title != nil
    semaphoreView.isEnabled = true
    
    return semaphoreView
  }
  
  func buildSemaphore(for segment: TKSegment) -> MKAnnotationView {
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
    
    return buildSemaphore(for: segment, preferredSide: side)
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
  
  func update(for annotation: MKAnnotation?, heading: CLLocationDirection?) {
    if let heading = heading {
      update(for: annotation, heading: heading)
    } else {
      update(for: annotation)
    }
  }

}

// MARK: - Circles

fileprivate extension TKUIAnnotationViewBuilder {
  
  func buildCircle(for annotation: MKAnnotation) -> MKAnnotationView {
    let identifier = asLarge ? "LargeCircleView" : "SmallCircleView"
    
    let circleView: TKUICircleAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUICircleAnnotationView {
      circleView = recycled
      circleView.annotation = annotation
    } else {
      circleView = TKUICircleAnnotationView(annotation: annotation, drawLarge: asLarge, reuseIdentifier: identifier)
    }
    
    circleView.isFaded = !asTravelled
    if asTravelled, let color = circleColor ?? (annotation as? TKUIModeAnnotation)?.modeInfo.color {
      circleView.circleColor = color
    } else {
      circleView.circleColor = .routeDashColorNonTravelled
    }
    circleView.alpha = alpha
    circleView.setNeedsDisplay()

    circleView.canShowCallout = annotation.title != nil
    circleView.isEnabled = true
    
    circleView.displayPriority = asLarge ? .defaultHigh : .defaultLow
    
    return circleView
  }
  
}

// MARK: - Generic annotations

fileprivate extension TKUIAnnotationViewBuilder {
  
  func build(for modeAnnotation: TKUIModeAnnotation, enableClustering: Bool) -> MKAnnotationView {

    let identifier: String
    if modeAnnotation is MKClusterAnnotation {
      identifier = "ClusteredModeAnnotationIdentifier"
    } else {
      identifier = "ModeAnnotationIdentifier"
    }

    let modeView: TKUIModeAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUIModeAnnotationView {
      modeView = recycled
      modeView.annotation = modeAnnotation
    } else {
      modeView = TKUIModeAnnotationView(annotation: modeAnnotation, reuseIdentifier: identifier)
    }
    
    modeView.alpha = 1
    modeView.leftCalloutAccessoryView = nil
    modeView.rightCalloutAccessoryView = nil
    modeView.canShowCallout = annotation.title != nil
    modeView.isEnabled = true
    
    modeView.collisionMode = .circle
    modeView.clusteringIdentifier = enableClustering && modeAnnotation.priority.rawValue < 500 ? modeAnnotation.clusterIdentifier : nil
    modeView.displayPriority = modeAnnotation.priority
    
    return modeView
  }

  func build(for image: TKUIImageAnnotation) -> MKAnnotationView {
    
    let identifier = "ImageAnnotationIdentifier"
    
    let imageView: TKUIImageAnnotationView
    if let recycled = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TKUIImageAnnotationView {
      imageView = recycled
      imageView.annotation = image
    } else {
      imageView = TKUIImageAnnotationView(annotation: image, reuseIdentifier: identifier)
    }
    
    imageView.alpha = 1
    imageView.leftCalloutAccessoryView = nil
    imageView.rightCalloutAccessoryView = nil
    imageView.canShowCallout = annotation.title != nil
    imageView.isEnabled = true
    return imageView
  }
  
  func build(for query: TKUIRoutingQueryAnnotation) -> MKAnnotationView {
    let view = MKPinAnnotationView(annotation: query, reuseIdentifier: query.isStart ? "QueryStart" : "QueryEnd")
    view.pinTintColor = query.isStart ? .green : .red
    view.canShowCallout = true
    return view
  }
  
}

fileprivate extension MKAnnotation {
  
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
  
  @objc static func update(annotationView: MKAnnotationView, forHeading heading: CLLocationDirection) {
    
    if let vehicleView = annotationView as? TKUIVehicleAnnotationView, let vehicle = vehicleView.annotation as? Vehicle {
      vehicleView.rotateVehicle(heading: heading, bearing: vehicle.bearing?.doubleValue)
      
    } else if let semaphore = annotationView as? TKUISemaphoreView {
      
      let bearing: CLLocationDirection
      if let segment = annotationView.annotation as? TKSegment {
        bearing = segment.bearing?.doubleValue ?? 0
        
      } else if let timePoint = annotationView.annotation as? TKUISemaphoreDisplayable {
        bearing = timePoint.bearing?.doubleValue ?? 0
      } else {
        bearing = 0
      }
      semaphore.updateHead(magneticHeading: heading, bearing: bearing)
      
    }
    
  }
  
}
