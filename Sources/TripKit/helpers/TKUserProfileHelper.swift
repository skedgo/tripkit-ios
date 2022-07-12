//
//  TKUserProfileHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 9/02/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKUserProfileHelper: NSObject {
  
  public enum DefaultsKey: String {
    case onWheelchair = "profileOnWheelchair"
    case sortedEnabled = "profileSortedModeIdentifiers"
    case hidden = "profileHiddenModeIdentifiers"
    case disliked = "profileDislikedTransitMode"
    case disabled = "profileDisabledSharedVehicleModes"
  }
  
  public typealias Identifier = String
  
  
  // MARK: - Simple settings
    
  /// Whether to show wheelchair information and show routes as being
  /// on a wheelchair. This will set TripKit's settings
  @objc public class var showWheelchairInformation: Bool {
    get {
      return UserDefaults.shared.bool(forKey: DefaultsKey.onWheelchair.rawValue)
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.onWheelchair.rawValue)
    }
  }
  
  public class var hiddenModesPickedManually: Bool {
    return UserDefaults.shared.object(forKey: DefaultsKey.hidden.rawValue) != nil 
  }
  
  
  //MARK: - Transport modes
  
  /// Overwrites user preferences for each non-nil value.
  @objc public class func updateTransportModesWithEnabledOrder(_ enabled: [Identifier]?, hidden: Set<Identifier>?)
  {
    let shared = UserDefaults.shared
    if let enabled = enabled {
      shared.set(enabled, forKey: DefaultsKey.sortedEnabled.rawValue)
      if enabled.contains(TKTransportModeIdentifierWheelchair) {
        showWheelchairInformation = true
      } else if enabled.contains(TKTransportModeIdentifierWalking) {
        showWheelchairInformation = false
      }
    }
    if let hidden = hidden {
      shared.set(Array(hidden), forKey: DefaultsKey.hidden.rawValue)
      if hidden.contains(TKTransportModeIdentifierWheelchair) {
        showWheelchairInformation = false
      }
    }
  }
  
  @objc public class func modeIdentifierIsHidden(_ modeIdentifier: Identifier) -> Bool {
    return hiddenModeIdentifiers.contains(modeIdentifier)
  }
  
  @objc public class func setModeIdentifier(_ modeIdentifier: Identifier, toHidden hidden: Bool) {
    update(hiddenModeIdentifiers, forKey: .hidden, modeIdentifier: modeIdentifier, include: hidden)
  }
  
  private class func update(_ identifiers: Set<Identifier>, forKey key: DefaultsKey, modeIdentifier: Identifier, include: Bool) {
    var modes = identifiers
    
    if include {
      modes.insert(modeIdentifier)
    } else {
      modes.remove(modeIdentifier)
    }
    
    UserDefaults.shared.set(Array(modes), forKey: key.rawValue)
  }
  
  @objc public class func orderedEnabledModeIdentifiersForAvailableModeIdentifiers(_ available: [Identifier]) -> [Identifier] {
    let hidden = hiddenModeIdentifiers
    let ordered = available.filter { !hidden.contains($0) }
    
    // Once we let users sort them again, do something like this:
//    if let sorted = NSUserDefaults.sharedDefaults().objectForKey(DefaultsKey.SortedEnabled.rawValue) as? [Identifier] {
//      ordered.sortInPlace { sorted.indexOf($0) < sorted.indexOf($1) }
//    }
    
    return ordered
  }

  @objc public class func maximizedModeIdentifiers(_ available: [Identifier]) -> Set<Identifier> {
    let hidden = hiddenModeIdentifiers
    let ordered = available.filter { !hidden.contains($0) }
    return Set(ordered)
  }
  
  @objc public class var hiddenModeIdentifiers: Set<Identifier> {
    if let hidden = UserDefaults.shared.object(forKey: DefaultsKey.hidden.rawValue) as? [Identifier] {
      return Set(hidden)
    } else {
      return [TKTransportModeIdentifierSchoolBuses]
    }
  }

  //MARK: - Preferred transit modes
  
  @objc public class func transitModeIsPreferred(_ identifier: Identifier) -> Bool {
    return !dislikedTransitModes.contains(identifier)
  }
  
  @objc public class func setTransitMode(_ identifier: Identifier, asPreferred preferred: Bool) {
    var modes = dislikedTransitModes
    if preferred {
      if let index = modes.firstIndex(of: identifier) {
        modes.remove(at: index)
      }
    } else {
      modes.append(identifier)
    }
    UserDefaults.shared.set(modes, forKey: DefaultsKey.disliked.rawValue)
  }

  @objc public class var dislikedTransitModes: [Identifier] {
    if let disliked = UserDefaults.shared.object(forKey: DefaultsKey.disliked.rawValue) as? [Identifier] {
      return disliked
    } else {
      return []
    }
  }
  
  // MARK: - Mode by mode, Mode picker
  
  /// update picked modes provided with all reference modes to determine disabled modes
  @objc public class func update(pickedModes: Set<TKModeInfo>, allModes: Set<TKModeInfo>) {
    var modes = disabledSharedVehicleModes
    
    let pickedIds = pickedModes.compactMap { try? JSONEncoder().encode($0)  }
    let allIds = allModes.compactMap { try? JSONEncoder().encode($0)  }
    
    let toDisable = allIds.filter {
      !pickedIds.contains($0)
    }
    
    pickedIds.forEach { mode in
      if modes.contains(mode) {
        modes = modes.filter { mode != $0 }
      }
    }
    
    toDisable.forEach {
      if !modes.contains($0) {
        modes.append($0)
      }
    }
    
    UserDefaults.shared.set(modes, forKey: DefaultsKey.disabled.rawValue)
  }
    
  @objc public class var disabledSharedVehicleModes: [Data] {
    if let disabled = UserDefaults.shared.object(forKey: DefaultsKey.disabled.rawValue) as? [Data] {
      return disabled
    } else {
      return []
    }
  }
  
}
