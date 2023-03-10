//
//  NSManagedObjectContext+Async.swift
//  TripKit
//
//  Created by Adrian Schönig on 1/3/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
  
  func tk_perform<R>(_ handler: @escaping () -> R) async -> R {
    if #available(iOS 15.0, macOS 12.0, *) {
      return await self.perform(handler)
    } else {
      var result: R! = nil
      self.performAndWait {
        result = handler()
      }
      return result
    }
  }
  
  
  func tk_performThrowing<R>(_ handler: @escaping () throws -> R) async throws -> R {
    if #available(iOS 15.0, macOS 12.0, *) {
      return try await self.perform(handler)
    } else {
      var result: R! = nil
      var anError: Error? = nil
      self.performAndWait {
        do {
          result = try handler()
        } catch {
          anError = error
        }
      }
      if let anError {
        throw anError
      } else {
        return result
      }
    }
  }
  
}
