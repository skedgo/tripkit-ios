//
//  TKUserProfileHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 9/02/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation



public class TKUserProfileHelper: NSObject {
  
  enum DefaultsKey: String {
    case onWheelchair = "profileOnWheelchair"
    case sortedEnabled = "profileSortedModeIdentifiers"
    case minimized = "profileMinimizedModeIdentifiers"
    case hidden = "profileHiddenModeIdentifiers"
    case disliked = "profileDislikedTransitMode"
  }
  
  public typealias Identifier = String
  
  //MARK: - Simple settings
  
  @objc public static var showWheelchairInformationKey =  DefaultsKey.onWheelchair.rawValue
  
  
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
  
  
  //MARK: - Transport modes
  
  /// Overwrites user preferences for each non-nil value.
  @objc public class func updateTransportModesWithEnabledOrder(_ enabled: [Identifier]?, minimized: Set<Identifier>?, hidden: Set<Identifier>?)
  {
    let shared = UserDefaults.shared
    if let enabled = enabled {
      shared.set(enabled, forKey: DefaultsKey.sortedEnabled.rawValue)
      if enabled.contains(TKTransportModeIdentifierWheelchair) {
        showWheelchairInformation = true
      }
    }
    if let minimized = minimized {
      shared.set(Array(minimized), forKey: DefaultsKey.minimized.rawValue)
    }
    if let hidden = hidden {
      shared.set(Array(hidden), forKey: DefaultsKey.hidden.rawValue)
      if hidden.contains(TKTransportModeIdentifierWheelchair) {
        showWheelchairInformation = false
      }
    }
  }
  
  @objc public class func modeIdentifierIsMinimized(_ modeIdentifier: Identifier) -> Bool {
    return minimizedModeIdentifiers.contains(modeIdentifier)
  }
  
  @objc public class func setModeIdentifier(_ modeIdentifier: Identifier, toMinimized minimized: Bool) {
    update(minimizedModeIdentifiers, forKey: .minimized, modeIdentifier: modeIdentifier, include: minimized)
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
    let minimized = minimizedModeIdentifiers
    let ordered = available.filter { !hidden.contains($0) && !minimized.contains($0) }
    return Set(ordered)
  }
  
  
  @objc public class var minimizedModeIdentifiers: Set<Identifier> {
    if let minimized = UserDefaults.shared.object(forKey: DefaultsKey.minimized.rawValue) as? [Identifier] {
      return Set(minimized)
    } else {
      return [TKTransportModeIdentifierMotorbike, TKTransportModeIdentifierTaxi, TKTransportModeIdentifierWalking]
    }
  }
  
  @objc public class var hiddenModeIdentifiers: Set<Identifier> {
    if let hidden = UserDefaults.shared.object(forKey: DefaultsKey.hidden.rawValue) as? [Identifier] {
      return Set(hidden)
    } else {
      return [TKTransportModeIdentifierSchoolBuses]
    }
  }

  @objc public class var hiddenAndMinimizedModeIdentifiers: Set<Identifier> {
    return minimizedModeIdentifiers.union(hiddenModeIdentifiers)
  }

  
  //MARK: - Preferred transit modes
  
  @objc public class func transitModeIsPreferred(_ identifier: Identifier) -> Bool {
    return !dislikedTransitModes.contains(identifier)
  }
  
  @objc public class func setTransitMode(_ identifier: Identifier, asPreferred preferred: Bool) {
    var modes = dislikedTransitModes
    if preferred {
      if let index = modes.index(of: identifier) {
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
  
  
}
