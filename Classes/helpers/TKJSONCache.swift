//
//  TKJSONCache.swift
//  Pods
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

import Foundation

@objc
public enum TKJSONCacheDirectory: Int {
  case Cache
  case Documents
}

public class TKJSONCache: NSObject {
  public static func read(id: String, directory: TKJSONCacheDirectory) -> [String: AnyObject]? {
    let fileURL = cacheURL(directory, filename: id)
    
    if let data = NSData(contentsOfURL: fileURL) {
      return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject]
    } else {
      return nil
    }
  }
  
  public static func save(id: String, dictionary: [String: AnyObject], directory: TKJSONCacheDirectory) {
    let fileURL = cacheURL(directory, filename: id)
    let data = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
    data.writeToURL(fileURL, atomically: true)
    assert(read(id, directory: directory) != nil)
  }
  
  public static func remove(id: String, directory: TKJSONCacheDirectory) {
    let fileURL = cacheURL(directory, filename: id)
    try? NSFileManager.defaultManager().removeItemAtURL(fileURL)
  }
  
  private static func cacheURL(destination: TKJSONCacheDirectory, filename: String, subdirectory: String? = nil) -> NSURL {
    let fileMan = NSFileManager.defaultManager()
    let searchPath: NSSearchPathDirectory
    switch destination {
    case .Cache: searchPath = .CachesDirectory
    case .Documents: searchPath = .DocumentDirectory
    }
    
    guard let path = fileMan.URLsForDirectory(searchPath, inDomains: .UserDomainMask).first else {
      preconditionFailure()
    }
    
    let pathURL: NSURL
    if let subdirectory = subdirectory {
      pathURL = path.URLByAppendingPathComponent(subdirectory, isDirectory: true)
      do {
        try fileMan.createDirectoryAtURL(pathURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        SGKLog.warn("TKTTPifierCache", text: "Could not create directory \(pathURL), due to: \(error)")
      }
    } else {
      pathURL = path
    }
    
    let file = "\(filename).cache"
    return pathURL.URLByAppendingPathComponent(file)
  }
}
