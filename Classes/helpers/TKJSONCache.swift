//
//  TKJSONCache.swift
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

import Foundation

@objc
public enum TKJSONCacheDirectory: Int {
  case cache
  case documents
}

public class TKJSONCache: NSObject {
  public static func read(_ id: String, directory: TKJSONCacheDirectory) -> [String: Any]? {
    return read(id, directory: directory, subdirectory: nil)
  }

  public static func read(_ id: String, directory: TKJSONCacheDirectory, subdirectory: String?) -> [String: Any]? {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    
    if let data = try? Data(contentsOf: fileURL) {
      return NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject]
    } else {
      return nil
    }
  }

  public static func save(_ id: String, dictionary: [String: Any], directory: TKJSONCacheDirectory) {
    save(id, dictionary: dictionary, directory: directory, subdirectory: nil)
  }

  public static func save(_ id: String, dictionary: [String: Any], directory: TKJSONCacheDirectory, subdirectory: String?) {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    let data = NSKeyedArchiver.archivedData(withRootObject: dictionary)
    try? data.write(to: fileURL, options: [.atomic])
    assert(read(id, directory: directory, subdirectory: subdirectory) != nil)
  }

  public static func remove(_ id: String, directory: TKJSONCacheDirectory) {
    remove(id, directory: directory, subdirectory: nil)
  }

  public static func remove(_ id: String, directory: TKJSONCacheDirectory, subdirectory: String?) {
    let fileURL = cacheURL(directory, filename: id, subdirectory: subdirectory)
    _ = try? FileManager.default.removeItem(at: fileURL)
  }
  
  private static func cacheURL(_ destination: TKJSONCacheDirectory, filename: String, subdirectory: String? = nil) -> URL {
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
      do {
        try fileMan.createDirectory(at: pathURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        SGKLog.warn("TKJSONCache", text: "Could not create directory \(pathURL), due to: \(error)")
      }
    } else {
      pathURL = path
    }
    
    let file = "\(filename).cache"
    return pathURL.appendingPathComponent(file)
  }
}
