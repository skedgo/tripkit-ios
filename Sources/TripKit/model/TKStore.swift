//
//  TKStore.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(CoreData)
import CoreData

extension Notification.Name {
  
  public static let TKTripKitDidReset = Notification.Name("TKTripKitDidResetNotification")
  
}

public class TKStore {
  
  static let shared = TKStore()
  
  private init() {}
  
  private var localStoreFilename = "TripCache.sqlite"
  
  lazy var model: NSManagedObjectModel = {
    let modelURL = Bundle.tripKit.url(forResource: "TripKitModel", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()
  
  private lazy var container: (NSPersistentContainer, Date) = {
    reloadContainer(reset: !didResetToday)
  }()
  
  public var tripKitContext: NSManagedObjectContext {
    viewContext
  }
  
  public var viewContext: NSManagedObjectContext {
    container.0.viewContext
  }
  
  /// The date TripKit was last reset when the context and coordinator were initialised.
  /// If you have multiple TripKit instances in different processes accessing the same underlying store, you
  /// can use this to determine if they are still in sync. If they aren't you'll likely want to call `reload` on
  /// the TripKit instance which wasn't reloaded since the other one was reset.
  var resetDateFromInitialization: Date {
    container.1
  }
  
  var inMemoryCache = NSCache<AnyObject, AnyObject>()
  
  private func reloadContainer(reset: Bool) ->  (NSPersistentContainer, Date) {
    let resetDate: Date
    if reset, let newlyReset = removeLocalFiles() {
      resetDate = newlyReset
    } else if let previously = UserDefaults.shared.object(forKey: "TripKitLastResetDate") as? Date {
      resetDate = previously
    } else {
      resetDate = Date() // vanilla
    }
    
    let container = NSPersistentContainer(name: "TripCache", managedObjectModel: model)
    
    // Need to specify this as we migrated to this specific URL before
    let storeURL = Self.localDirectory.appendingPathComponent(localStoreFilename)
    container.persistentStoreDescriptions.first?.url = storeURL
    
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
    // This makes the view context automatically get changes from background
    // contexts, e.g., when refreshing the library.
    container.viewContext.automaticallyMergesChangesFromParent = true
    
    // TODO: Do we need to request light-weight migration, i.e., somewhere set `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption`?
    
    container.loadPersistentStores { [weak self] _, error in
      guard let error else { return }
      
      if !reset {
        // if it failed, delete the file
        self?.reset()
      } else {
        // we fail
        assertionFailure("Unresolved migration error: \(error). File: \(storeURL)")
      }
    }
    
    return (container, resetDate)
  }
  
}

// MARK: - File store

extension TKStore {
  
  private static var localDirectory: URL {
    if let appGroupName = TKConfig.shared.appGroupName {
      if let groupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) {
        return groupDirectory
      } else {
        assertionFailure("Can't load container directory for app group (\(appGroupName)! Check your settings.")
      }
    }
    
    do {
      return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    } catch {
      assertionFailure("Can't find local directory for TripKit! Error: \(error)")
      return FileManager.default.temporaryDirectory
    }
  }
  
}

// MARK: - Resetting

extension TKStore {
  
  /// Wipes TripKit and effectively clears the cache. Following calls to the context and coordinator will return
  /// new instances, so make sure you clear local references to those.
  public func reset() {
    self.container = reloadContainer(reset: true)
  }
  
  private var didResetToday: Bool {
    let currentReset = resetStringForToday
    if let lastReset = UserDefaults.standard.string(forKey: "TripKitLastReset") {
      return lastReset == currentReset
    } else {
      // Never reset yet, remember today so that we'll reset tomorrow, but
      // pretent we already reset today to not reset right at the start.
      UserDefaults.standard.set(currentReset, forKey: "TripKitLastReset")
      return true
    }
  }
  
  private var resetStringForToday: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    let dateString = formatter.string(from: Date())
    
    let versionString = TKServer.xTripGoVersion() ?? "unknown"
    return "\(versionString)-\(dateString)-\(localStoreFilename)"
  }
  
  private func removeLocalFiles() -> Date? {
    do {
      for fileURL in try FileManager.default.contentsOfDirectory(at: Self.localDirectory, includingPropertiesForKeys: []) {
        if fileURL.lastPathComponent.starts(with: localStoreFilename) {
          try FileManager.default.removeItem(at: fileURL)
        }
      }

      inMemoryCache = .init()
      
      // Remember last reset
      let resetDate = Date()
      UserDefaults.standard.set(resetStringForToday, forKey: "TripKitLastReset")
      UserDefaults.shared.set(resetDate, forKey: "TripKitLastResetDate")
      NotificationCenter.default.post(name: .TKTripKitDidReset, object: self)
      return resetDate
      
    } catch {
      assertionFailure("Could not reset: \(error)")
      return nil
    }
  }
  
}

#endif
