//
//  STKCoordinates.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation
import CoreLocation

public extension TKModeInfo {
  var glyphColor: TKColor? {
    if let color = color {
      return color
    }
    guard let identifier = identifier else {
      return nil
    }
    return TKTransportModes.color(for: identifier)
  }
}

open class TKModeCoordinate: TKNamedCoordinate {
  private enum CodingKeys: String, CodingKey {
    case modeInfo
  }
  
  public init(modeInfo: TKModeInfo, coordinate: CLLocationCoordinate2D) {
    super.init(coordinate: coordinate)
    _stopModeInfo = modeInfo
    data["sg_modeInfo"] = try? JSONEncoder().encodeJSONObject(modeInfo)
  }
  
  @objc public class override var supportsSecureCoding: Bool { return true }
  
  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
    isDraggable = false

    // Sometimes the mode info comes in the decoder rather
    // than in the "data" field
    if let values = try? decoder.container(keyedBy: CodingKeys.self), let modeInfo = try? values.decode(TKModeInfo.self, forKey: .modeInfo) {
      stopModeInfo = modeInfo
    }
    assert(!stopModeInfo.alt.isEmpty)
  }
  
  @objc public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public var priority: Float?
  
  private var _stopModeInfo: TKModeInfo? = nil
  @objc public var stopModeInfo: TKModeInfo {
    get {
      if let decoded = _stopModeInfo {
        return decoded
      } else {
        let json = data["sg_modeInfo"] as Any
        if let sanitized = TKJSONSanitizer.sanitize(json), let decoded = try? JSONDecoder().decode(TKModeInfo.self, withJSONObject: sanitized) {
          _stopModeInfo = decoded
        } else {
          _stopModeInfo = TKModeInfo.unknown
        }
        return _stopModeInfo!
      }
      
    }
    set {
      _stopModeInfo = newValue
      data["sg_modeInfo"] = try? JSONEncoder().encodeJSONObject(newValue)
    }
  }
  
}


public class TKStopCoordinate: TKModeCoordinate {
  
  private enum CodingKeys: String, CodingKey {
    case stopCode
    case services
    case shortName
    case popularity
    case availableRoutes
    case routes
    case operators
  }
  
  @objc public class override var supportsSecureCoding: Bool { return true }

  public init(_ stop: TKAPI.Stop) {
    super.init(modeInfo: stop.modeInfo, coordinate: .init(latitude: stop.lat, longitude: stop.lng))
    isDraggable = false
    stopCode = stop.code
    services = stop.services
    stopShortName = stop.shortName
    stopSortScore = stop.popularity
    availableRoutes = stop.availableRoutes
    routes = stop.routes
    operators = stop.operators
  }
  
  init(_ stop: TKAPI.ShapeStop, modeInfo: TKModeInfo) {
    super.init(modeInfo: modeInfo, coordinate: .init(latitude: stop.lat, longitude: stop.lng))
    isDraggable = false
    stopCode = stop.code
    stopShortName = stop.shortName
  }
  
  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
    isDraggable = false
    
    guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
    if data["sg_stopCode"] == nil {
      // From the API these comes in the decoder rather than in the "data" field
      stopCode = try values.decode(String.self, forKey: .stopCode)
      services = try values.decodeIfPresent(String.self, forKey: .services)
      stopShortName = try values.decodeIfPresent(String.self, forKey: .shortName)
      stopSortScore = try values.decodeIfPresent(Int.self, forKey: .popularity)
      availableRoutes = try values.decodeIfPresent(Int.self, forKey: .availableRoutes)
      routes = try values.decodeIfPresent([TKAPI.Route].self, forKey: .routes)
      operators = try values.decodeIfPresent([TKAPI.Operator].self, forKey: .operators)
    }
  }
  
  @objc public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override var subtitle: String? {
    get {
      return services // subtitle is services list rather than address
    }
    set {
      // do nothing
    }
  }

  public var services: String? {
    get { return data["sg_services"] as? String }
    set { data["sg_services"] = newValue }
  }
  
  @objc public var stopCode: String {
    get { return data["sg_stopCode"] as! String }
    set { data["sg_stopCode"] = newValue }
  }
  
  @objc var stopShortName: String? {
    get { return data["sg_stopShortName"] as? String }
    set { data["sg_stopShortName"] = newValue }
  }
  
  var stopSortScore: Int? {
    get { return data["sg_stopSortScore"] as? Int }
    set { data["sg_stopSortScore"] = newValue }
  }
  
  var availableRoutes: Int? {
    get { return data["sg_availableRoutes"] as? Int }
    set { data["sg_availableRoutes"] = newValue }
  }

  private var _routes: [TKAPI.Route]?? = nil
  public var routes: [TKAPI.Route]? {
    get {
      if let decoded = _routes {
        return decoded
      } else if let json = data["sg_routes"] as Any? {
        if let sanitized = TKJSONSanitizer.sanitize(json), let decoded = try? JSONDecoder().decode([TKAPI.Route].self, withJSONObject: sanitized) {
          _routes = decoded
          return decoded
        } else {
          _routes = nil
          return nil
        }
      } else {
        _routes = nil
        return nil
      }
    }
    
    set {
      _routes = newValue
      if let newValue {
        data["sg_routes"] = try? JSONEncoder().encodeJSONObject(newValue)
      }
    }
  }
  
  private var _operators: [TKAPI.Operator]?? = nil
  public var operators: [TKAPI.Operator]? {
    get {
      if let decoded = _operators {
        return decoded
      } else if let json = data["sg_operators"] as Any? {
        if let sanitized = TKJSONSanitizer.sanitize(json), let decoded = try? JSONDecoder().decode([TKAPI.Operator].self, withJSONObject: sanitized) {
          _operators = decoded
          return decoded
        } else {
          _operators = nil
          return nil
        }
      } else {
        _operators = nil
        return nil
      }
    }
    
    set {
      _operators = newValue
      if let newValue {
        data["sg_operators"] = try? JSONEncoder().encodeJSONObject(newValue)
      }
    }
  }

}
