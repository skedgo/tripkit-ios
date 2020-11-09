//
//  NSManagedObjectContext+Fetch.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22/9/16.
//
//

import Foundation

extension NSManagedObjectContext {
  public func fetchObjects<E: NSManagedObject>(_ entity: E.Type, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, relationshipKeyPathsForPrefetching: [String]? = nil, fetchLimit: Int? = nil) -> [E] {
    
    let request = NSFetchRequest<E>(entityName: String(describing: E.self))
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    request.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
    
    if let fetchLimit = fetchLimit, fetchLimit > 0 {
      // Don't use negative value to enforce no fetch limit
      // as that is buggy and might set some random fetch
      // limit rather than returning all results!
      request.fetchLimit = fetchLimit
    }
    
    do {
      return try self.fetch(request)
    } catch {
      TKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error). Please file a bug with steps to reproduce this.")
      return []
    }
  }
  
  public func fetchObjects<E: NSManagedObject>(_ entity: E.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [E] {
    
    let request = NSFetchRequest<E>(entityName: String(describing: E.self))
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    
    do {
      return try self.fetch(request)
    } catch {
      TKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error). Please file a bug with steps to reproduce this.")
      return []
    }
  }
  
  public func fetchUniqueObject<E: NSManagedObject>(_ entity: E.Type, predicate: NSPredicate? = nil) -> E? {
    
    let request = NSFetchRequest<E>(entityName: String(describing: E.self))
    request.predicate = predicate
    request.fetchLimit = 1
    
    do {
      return try self.fetch(request).first
    } catch {
      TKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error). Please file a bug with steps to reproduce this.")
      return nil
    }
  }
  
  public func containsObject<E: NSManagedObject>(_ entity: E.Type, predicate: NSPredicate? = nil) -> Bool {
    
    let request = NSFetchRequest<E>(entityName: String(describing: E.self))
    request.predicate = predicate
    request.fetchLimit = 1
    request.resultType = .countResultType
    
    do {
      return try self.count(for: request) > 0
    } catch {
      TKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error). Please file a bug with steps to reproduce this.")
      return false
    }
  }
  
}
