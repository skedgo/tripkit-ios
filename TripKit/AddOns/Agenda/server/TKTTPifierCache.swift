//
//  TKTTPifierCache.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

enum TKTTPifierCache {
  fileprivate static let problemsDir = "problems"
  fileprivate static let solutionsDir = "solutions"
  
  static func problemId(forParas paras: [String: Any]) -> String? {
    let hash = inputHash(paras)
    return problemId(hash)
  }
  
  fileprivate static func problemId(_ hash: UInt) -> String? {
    let dict = TKJSONCache.read("\(hash)", directory: .cache, subdirectory: problemsDir) as? [String: String]
    return dict?["id"]
  }
  
  static func save(problemId id: String, forParas paras: [String: Any]) {
    let hash = inputHash(paras)
    let dict = ["id": id]
    TKJSONCache.save("\(hash)", dictionary: dict, directory: .cache, subdirectory: problemsDir)
    assert(problemId(forParas: paras) == id)
  }
  
  static func clear(forParas paras: [String: Any]) {
    let hash = inputHash(paras)
    
    if let id = problemId(hash) {
      TKJSONCache.remove(id, directory: .cache, subdirectory: solutionsDir)
    }
    TKJSONCache.remove("\(hash)", directory: .cache, subdirectory: problemsDir)
  }

  static func marshaledSolution(forId id: String) -> [String: Any]? {
    return TKJSONCache.read(id, directory: .cache, subdirectory: solutionsDir)
  }
  
  static func save(marshaledSolution dict: [String: Any], forId id: String) {
    TKJSONCache.save(id, dictionary: dict, directory: .cache, subdirectory: solutionsDir)
  }
  
  fileprivate static func inputHash(_ input: [String: Any]) -> UInt {
    var hash = 5381
    for key in input.keys.sorted() {
      let value = input[key]
      if let string = value as? String {
        hash = ((hash << 5) &+ hash) &+ string.hash
        
      } else if let number = value as? Double {
        hash = ((hash << 5) &+ hash) &+ number.hashValue
        
      } else if let stringArray = value as? [String] {
        for string in stringArray {
          hash = ((hash << 5) &+ hash) &+ string.hash
        }
        
      } else if let dict = value as? [String: AnyObject] {
        hash = ((hash << 5) &+ hash) &+ Int(inputHash(dict))

      } else if let dictArray = value as? [[String: AnyObject]] {
        for dict in dictArray {
          hash = ((hash << 5) &+ hash) &+ Int(inputHash(dict))
        }

      } else {
        preconditionFailure()
      }
    }
    
    return UInt(abs(hash))
  }
}
