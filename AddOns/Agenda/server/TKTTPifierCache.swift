//
//  TKTTPifierCache.swift
//  RioGo
//
//  Created by Adrian Schoenig on 20/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import SwiftyJSON

enum TKTTPifierCache {
  private static let problemsDir = "problems"
  private static let solutionsDir = "solutions"
  
  static func problemId(forParas paras: [String: AnyObject]) -> String? {
    let hash = inputHash(paras)
    return problemId(hash)
  }
  
  private static func problemId(_ hash: UInt) -> String? {
    let dict = TKJSONCache.read("\(hash)", directory: .cache, subdirectory: problemsDir) as? [String: String]
    return dict?["id"]
  }
  
  static func save(problemId id: String, forParas paras: [String: AnyObject]) {
    let hash = inputHash(paras)
    let dict = ["id": id]
    TKJSONCache.save("\(hash)", dictionary: dict, directory: .cache, subdirectory: problemsDir)
    assert(problemId(forParas: paras) == id)
  }
  
  static func clear(forParas paras: [String: AnyObject]) {
    let hash = inputHash(paras)
    
    if let id = problemId(hash) {
      TKJSONCache.remove(id, directory: .cache, subdirectory: solutionsDir)
    }
    TKJSONCache.remove("\(hash)", directory: .cache, subdirectory: problemsDir)
  }

  static func solutionJson(forId id: String) -> JSON? {
    if let dict = TKJSONCache.read(id, directory: .cache, subdirectory: solutionsDir) {
      return JSON(dict)
    } else {
      return nil
    }
  }
  
  static func save(solutionJson json: JSON, forId id: String) {
    guard let dict = json.dictionaryObject else {
      SGKLog.warn("TKTTPifierCache", text: "Could not turn json into dictionary. JSON: \(json)")
      return
    }
    TKJSONCache.save(id, dictionary: dict, directory: .cache, subdirectory: solutionsDir)
  }
  
  private static func inputHash(_ input: [String: AnyObject]) -> UInt {
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
