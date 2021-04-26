//
//  STKCoordinates.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

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
  }
  
  @objc public class override var supportsSecureCoding: Bool { return true }

  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
    isDraggable = false
    
    guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
    if data["sg_services"] == nil {
      // From the API these comes in the decoder rather than in the "data" field
      stopCode = try values.decode(String.self, forKey: .stopCode)
      services = try? values.decode(String.self, forKey: .services)
      stopShortName = try? values.decode(String.self, forKey: .shortName)
      stopSortScore = try? values.decode(Int.self, forKey: .popularity)
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
  
}
