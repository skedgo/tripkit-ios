//
//  NSCoder+CoreData.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension NSCoder {
  
  // MARK - NSManagedObject helpers
  
  func decodeManaged<T: NSManagedObject>(forKey key: String, in context: NSManagedObjectContext) -> T? {
    guard let id = decodeObject(forKey: key) as? String else { return nil }
    return T(fromPersistentId: id, in: context)
  }
  
  func decodeManaged<T: NSManagedObject>(forKey key: String, in context: NSManagedObjectContext) -> [T]? {
    guard let ids = decodeObject(forKey: key) as? [String] else { return nil }
    return ids.compactMap { T(fromPersistentId: $0, in: context) }
  }
  
  func encodeManaged<T: NSManagedObject>(_ object: T?, forKey key: String) {
    guard let object = object else { return }
    encode(object.persistentId(), forKey: key)
  }
  
  func encodeManaged<T: NSManagedObject>(_ objects: [T]?, forKey key: String) {
    guard let objects = objects else { return }
    encode(objects.map { $0.persistentId() }, forKey: key)
  }
  
}
