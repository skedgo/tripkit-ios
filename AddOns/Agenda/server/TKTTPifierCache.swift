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
  
  static func problemId(forParas paras: [String: AnyObject]) -> String? {
    
    let hash = inputHash(paras)
    let filePath = cacheURL("problems", filename: "\(hash)")
    
    guard let data = NSData(contentsOfURL: filePath),
    let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: String] else {
      return nil
    }

    return dict["id"]
  }
  
  static func save(problemId id: String, forParas paras: [String: AnyObject]) {
    let hash = inputHash(paras)
    let filePath = cacheURL("problems", filename: "\(hash)")
    
    let dict = ["id": id]
    let data = NSKeyedArchiver.archivedDataWithRootObject(dict)
    data.writeToURL(filePath, atomically: true)
    assert(problemId(forParas: paras) == id)
  }

  static func solutionJson(forId id: String) -> JSON? {
    let filePath = cacheURL("solutions", filename: id)
    guard let data = NSData(contentsOfURL: filePath),
          let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject] else {
      return nil
    }
    return JSON(dict)
  }
  
  static func save(solutionJson json: JSON, forId id: String) {
    let filePath = cacheURL("solutions", filename: id)
    
    guard let dict = json.dictionaryObject else {
      SGKLog.warn("TKTTPifierCache", text: "Could not turn json into dictionary. JSON: \(json)")
      return
    }
    
    let data = NSKeyedArchiver.archivedDataWithRootObject(dict)
    data.writeToURL(filePath, atomically: true)
  }
  
  private static func inputHash(input: [String: AnyObject]) -> UInt {
    var hash = 1
    for key in input.keys.sort() {
      let value = input[key]
      if let string = value as? String {
        hash = hash &+ 31 &* string.hash
        
      } else if let number = value as? Double {
        hash = hash &+ 31 &* number.hashValue
        
      } else if let stringArray = value as? [String] {
        for string in stringArray {
          hash = hash &+ 31 &* string.hash
        }
        
      } else if let dict = value as? [String: AnyObject] {
        hash = hash &+ 31 &* Int(inputHash(dict))

      } else if let dictArray = value as? [[String: AnyObject]] {
        for dict in dictArray {
          hash = hash &+ 31 &* Int(inputHash(dict))
        }

      } else {
        preconditionFailure()
      }
    }
    
    return UInt(hash)
  }
  
  private static func cacheURL(directory: String, filename: String) -> NSURL {
    let fileMan = NSFileManager.defaultManager()
    guard let path = fileMan.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first else {
      preconditionFailure()
    }
    
    let fullPath = path.URLByAppendingPathComponent(directory, isDirectory: true)
    do {
      try fileMan.createDirectoryAtURL(fullPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
      SGKLog.warn("TKTTPifierCache", text: "Could not create directory \(fullPath), due to: \(error)")
    }

    
    let file = "\(filename).cache"
    return fullPath.URLByAppendingPathComponent(file)
  }
}