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
    
    let request = NSFetchRequest<NSManagedObject>(entityName: String(describing: E.self))
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
      let all = try self.fetch(request)
      let correctType = all.flatMap {
        $0 as? E
      }
      assert(all.count == correctType.count)
      return correctType
    } catch {
      SGKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error)")
      return []
    }
  }
  
  public func fetchObjects<E: NSManagedObject>(_ entity: E.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [E] {
    
    let request = NSFetchRequest<NSManagedObject>(entityName: String(describing: E.self))
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    
    do {
      return try self.fetch(request).flatMap { $0 as? E }
    } catch {
      SGKLog.error("NSManagedObjectContext+Fetch", text: "Failed with error: \(error)")
      return []
    }
  }
  
}
