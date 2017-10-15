//
//  STKCoordinates.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

open class STKModeCoordinate: SGKNamedCoordinate, STKModeAnnotation {
  
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
        let decoded = try! JSONDecoder().decode(ModeInfo.self, withJSONObject: json)
        _stopModeInfo = decoded
        return decoded
      }
      
    }
    set {
      _stopModeInfo = newValue
      data["sg_modeInfo"] = try! JSONEncoder().encodeJSONObject(newValue)
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
