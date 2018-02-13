//
//  STKCoordinates.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

public extension ModeInfo {
  var glyphColor: SGKColor? {
    if let color = color {
      return color
    }
    
    switch identifier {
    case "pt_pub_airport"?:       return #colorLiteral(red: 0.2317194939, green: 0.6177652478, blue: 0.553303957, alpha: 1)
    case "pt_pub_bus"?:           return #colorLiteral(red: 0.002927262336, green: 0.7073513269, blue: 0.3884637356, alpha: 1)
    case "pt_pub_cablecar"?:      return #colorLiteral(red: 0.8554401994, green: 0.353838861, blue: 0.2938257158, alpha: 1)
    case "pt_pub_ferry"?:         return #colorLiteral(red: 0.3107161224, green: 0.6154219508, blue: 0.8482584953, alpha: 1)
    case "pt_pub_funiculur"?:     return #colorLiteral(red: 0.4495800138, green: 0.6648783088, blue: 0.9513805509, alpha: 1)
    case "pt_pub_monorail"?:      return #colorLiteral(red: 0.8942372203, green: 0.7542654276, blue: 0.08317423612, alpha: 1)
    case "pt_pub_subway"?:        return #colorLiteral(red: 0.6042864919, green: 0.3401404023, blue: 0.6175028682, alpha: 1)
    case "pt_pub_train"?:         return #colorLiteral(red: 0.3985300958, green: 0.3960455656, blue: 0.6988547444, alpha: 1)
    case "pt_pub_tram"?:          return #colorLiteral(red: 0.9164136648, green: 0.6101632714, blue: 0.2767356038, alpha: 1)

//    case "bicycle-share"?: return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "car-share"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "parking"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "taxi"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)

    default:
      print("Default colour missing for: \(String(describing: identifier))")
      return nil
    }
  }
}

open class STKModeCoordinate: SGKNamedCoordinate, STKModeAnnotation, TKGlyphableAnnotation {
  
  private enum CodingKeys: String, CodingKey {
    case modeInfo
  }
  
  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
    isDraggable = false

    // Sometimes the mode info comes in the decoder rather
    // than in the "data" field
    if let values = try? decoder.container(keyedBy: CodingKeys.self), let modeInfo = try? values.decode(ModeInfo.self, forKey: .modeInfo) {
      stopModeInfo = modeInfo
    }
    assert(!stopModeInfo.alt.isEmpty)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  private var _stopModeInfo: ModeInfo? = nil
  public var stopModeInfo: ModeInfo {
    get {
      if let decoded = _stopModeInfo {
        return decoded
      } else {
        let json = data["sg_modeInfo"] as Any
        if let sanitized = TKJSONSanitizer.sanitize(json), let decoded = try? JSONDecoder().decode(ModeInfo.self, withJSONObject: sanitized) {
          _stopModeInfo = decoded
        } else {
          _stopModeInfo = ModeInfo.unknown
        }
        return _stopModeInfo!
      }
      
    }
    set {
      _stopModeInfo = newValue
      data["sg_modeInfo"] = try? JSONEncoder().encodeJSONObject(newValue)
    }
  }
  
  public var pointClusterIdentifier: String? {
    return stopModeInfo.identifier ?? "STKModeCoordinate"
  }
  
  public var pointDisplaysImage: Bool { return stopModeInfo.localImageName != nil }
  
  public var pointImage: SGKImage? {
    guard let imageName = stopModeInfo.localImageName else { return nil }
    return SGStyleManager.image(forModeImageName: imageName, isRealTime: false, of: .mapIcon)
  }
  
  public var pointImageURL: URL? {
    guard let imageName = stopModeInfo.remoteImageName else { return nil }
    return SVKServer.imageURL(forIconFileNamePart: imageName, of: .mapIcon)
  }
  
  public var glyphColor: SGKColor? {
    return stopModeInfo.glyphColor
  }
  
  public var glyphImage: SGKImage? {
    guard let imageName = stopModeInfo.localImageName else { return nil }
    let image = SGStyleManager.image(forModeImageName: imageName, isRealTime: false, of: .listMainMode)
    #if os(iOS) || os(tvOS)
      return image?.withRenderingMode(.alwaysTemplate)
    #else
      return image
    #endif

  }
  
  public var glyphImageURL: URL? {
    // TODO: When the new images on the backend are prepared for this, adopt them here, too.
    return nil
  }
  
}


public class STKStopCoordinate: STKModeCoordinate, STKStopAnnotation {
  
  private enum CodingKeys: String, CodingKey {
    case stopCode
    case services
    case shortName
    case popularity
  }
  
  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
    isDraggable = false
    
    // From the API these comes in the decoder rather than in the "data" field
    guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
    stopCode = try values.decode(String.self, forKey: .stopCode)
    services = try? values.decode(String.self, forKey: .services)
    stopShortName = try? values.decode(String.self, forKey: .shortName)
    stopSortScore = try? values.decode(Int.self, forKey: .popularity)
  }
  
  public required init?(coder aDecoder: NSCoder) {
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
  
  public var stopCode: String {
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
