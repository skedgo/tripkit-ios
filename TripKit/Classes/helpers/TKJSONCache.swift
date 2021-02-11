//
//  TKJSONCache.swift
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

import Foundation

@objc
public enum TKFileCacheDirectory: Int {
  case cache
  case documents
}

public class TKJSONCache: TKFileCache {
  @objc public static func read(_ id: String, directory: TKFileCacheDirectory) -> [String: Any]? {
    return read(id, directory: directory, subdirectory: nil)
  }
  
  @objc public static func read(_ id: String, directory: TKFileCacheDirectory, subdirectory: String?) -> [String: Any]? {
    guard let data = TKFileCache.read(id, directory: directory, subdirectory: subdirectory) else { return nil }
    
    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [
        NSArray.self,
        NSDictionary.self,
        NSDate.self,
      ], from: data) as? [String: AnyObject]
    
    } catch {
      assertionFailure("Error while reading: \(error)")
      return nil
    }
  }

  @objc public static func save(_ id: String, dictionary: [String: Any], directory: TKFileCacheDirectory) {
    save(id, dictionary: dictionary, directory: directory, subdirectory: nil)
  }
  
  @objc public static func save(_ id: String, dictionary: [String: Any], directory: TKFileCacheDirectory, subdirectory: String?) {
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: false)
      TKFileCache.save(id, data: data, directory: directory, subdirectory: subdirectory)
    } catch {
      assertionFailure("Error while saving: \(error)")
    }
  }
}

public class TKFileCache: NSObject {
  
  public static func read(_ id: String, directory: TKFileCacheDirectory, subdirectory: String? = nil) -> Data? {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    return try? Data(contentsOf: fileURL)
  }
  
  public static func save(_ id: String, data: Data, directory: TKFileCacheDirectory, subdirectory: String? = nil) {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    do {
      try data.write(to: fileURL, options: [.atomic])
      assert(read(id, directory: directory, subdirectory: subdirectory) != nil)
    } catch {
      assertionFailure("Error while saving: \(error)")
    }
  }
  
  public static func remove(_ id: String, directory: TKFileCacheDirectory, subdirectory: String? = nil) {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    _ = try? FileManager.default.removeItem(at: fileURL)
  }
  
  public static func remove(directory: TKFileCacheDirectory, subdirectory: String) {
    let fileURL = cacheURL(directory, subdirectory: subdirectory)
    _ = try? FileManager.default.removeItem(at: fileURL)
  }
  
  
  private static func cacheURL(_ destination: TKFileCacheDirectory, filename: String? = nil, subdirectory: String? = nil) -> URL {
    let fileMan = FileManager.default
    let searchPath: FileManager.SearchPathDirectory
    switch destination {
    case .cache: searchPath = .cachesDirectory
    case .documents: searchPath = .documentDirectory
    }
    
    guard let path = fileMan.urls(for: searchPath, in: .userDomainMask).first else {
      preconditionFailure()
    }
    
    let pathURL: URL
    if let subdirectory = subdirectory {
      pathURL = path.appendingPathComponent(subdirectory, isDirectory: true)
    } else {
      pathURL = path
    }
    
    if !fileMan.fileExists(atPath: pathURL.absoluteString) {
      do {
        try fileMan.createDirectory(at: pathURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        TKLog.warn("Could not create directory \(pathURL), due to: \(error)")
      }
    }
    
    if let filename = filename {
      return pathURL.appendingPathComponent("\(filename).cache")
    } else {
      return pathURL
    }
  }
}
