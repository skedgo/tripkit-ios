//
//  NSManagedObject+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

protocol DataAttachable: class {
  var data: Data? { get set }
}

extension DataAttachable {
  func decode<T>(_ type: T.Type, key: String) -> T? where T : Decodable {
    do {
      guard let data = dataDictionary[key] as? Data else { return nil }
      return try JSONDecoder().decode(type, from: data)
    } catch {
      TKLog.info(#file) { "Decoding of \(key) failed due to: \(error)." }
      return nil
    }
  }
  
  func encode<T>(_ value: T?, key: String) where T : Encodable {
    do {
      let data = dataDictionary
      if let value = value {
        let valueData = try JSONEncoder().encode(value)
        data[key] = valueData
      } else {
        data[key] = nil
      }
      self.dataDictionary = data
    } catch {
      TKLog.info(#file) { "Encoding of \(String(describing: value)) to \(key) failed due to: \(error)." }
    }
  }
  
  func decodePrimitive<T>(_ type: T.Type, key: String) -> T? where T : Decodable {
    return decode([T].self, key: key)?.first
  }
  
  func encodePrimitive<T>(_ value: T?, key: String) where T : Encodable {
    if let value = value {
      return encode([value], key: key)
    } else {
      let data = dataDictionary
      data[key] = nil
      self.dataDictionary = data
    }
  }
  
  func decodeCoding<T>(_ type: T.Type, key: String) -> T? where T : NSCoding {
    return dataDictionary[key] as? T
  }
  
  func encodeCoding<T>(_ value: T?, key: String) where T : NSCoding {
    let data = dataDictionary
    data[key] = value
    self.dataDictionary = data
  }

  private var dataDictionary: NSMutableDictionary {
    get {
      guard let data = self.data else { return NSMutableDictionary() }

      do {
        // We have to include `NSArray` here, but not sure why; the result will
        // definitely be a dictionary, but if we don't include it, this will
        // fail with an error.
        let dictionary = try NSKeyedUnarchiver.unarchivedObject(
          ofClasses: [
            NSDictionary.self,
            NSArray.self,
            NSMutableData.self,
            NSDate.self // timetable start + end date
          ],
          from: data) as? NSDictionary
        return dictionary.map(NSMutableDictionary.init(dictionary:)) ?? NSMutableDictionary()
      } catch {
        TKLog.info(#file) { "Decoding new data failed due to: \(error). Data: \(String(decoding: data, as: UTF8.self))" }
        return NSMutableDictionary()
      }
    }
    
    set {
      do {
        self.data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
      } catch {
        TKLog.info(#file) { "Encoding new data failed due to: \(error). Dict: \(newValue)" }
      }
    }
  }
}
