//
//  NSManagedObject+Safely.swift
//  TripKit
//
//  Created by Adrian Schönig on 31/3/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import CoreData

func tk_safeRead<S, V>(_ keyPath: KeyPath<S, V>, from target: S) -> V {
  var value: V!
  if let context = (target as? NSManagedObject)?.managedObjectContext {
    context.performAndWait {
      value = target[keyPath: keyPath]
    }
  } else {
    value = target[keyPath: keyPath]
  }
  return value
}

func tk_safeWrite<S, V>(_ keyPath: WritableKeyPath<S, V>, value: V, to target: inout S) {
  if let context = (target as? NSManagedObject)?.managedObjectContext {
    context.performAndWait {
      target[keyPath: keyPath] = value
    }
  } else {
    target[keyPath: keyPath] = value
  }
}

#endif