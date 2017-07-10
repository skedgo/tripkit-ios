//
//  STKCoordinates.swift
//  Pods
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

import Marshal

open class STKModeCoordinate: SGKNamedCoordinate, STKModeAnnotation {
  
  public required init(object: MarshaledObject) throws {
    try super.init(object: object)
    stopModeInfo = try object.value(for: "modeInfo")
    isDraggable = false
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    isDraggable = false
  }
  
  public var stopModeInfo: ModeInfo {
    get { return data["sg_modeInfo"] as! ModeInfo }
    set { data["sg_modeInfo"] = newValue }
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
  
  public required init(object: MarshaledObject) throws {
    try super.init(object: object)
    stopCode = try object.value(for: "code")
    
    address = try? object.value(for: "services")
    stopShortName = try? object.value(for: "shortName")
    stopSortScore = try? object.value(for: "popularity")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public var stopCode: String {
    get { return data["sg_stopCode"] as! String }
    set { data["sg_stopCode"] = newValue }
  }
  
  var stopShortName: String? {
    get { return data["sg_stopShortName"] as? String }
    set { data["sg_stopShortName"] = newValue }
  }
  
  var stopSortScore: Int? {
    get { return data["sg_stopSortScore"] as? Int }
    set { data["sg_stopSortScore"] = newValue }
  }
  
}
