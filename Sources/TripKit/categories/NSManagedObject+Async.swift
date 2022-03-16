//
//  NSManagedObject+Async.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/3/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import CoreData

public extension NSManagedObject {
  
  func access<T>(_ handler: @escaping () -> T) async -> T {
    await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) -> Void in
      if let context = managedObjectContext {
        context.perform {
          let result = handler()
          continuation.resume(returning: result)
        }
      } else {
        let result = handler()
        continuation.resume(returning: result)
      }
    }
  }
}
