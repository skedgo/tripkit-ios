//
//  TKSegment+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SegmentReference {
  func decode<T>(_ type: T.Type, key: String) -> T? where T : Decodable {
    do {
      guard let data = dataDictionary[key] as? Data else { return nil }
      return try JSONDecoder().decode(type, from: data)
    } catch {
      TKLog.info(#file) { "Decoding of \(key) failed due to: \(error)." }
      return nil
    }
  }
  
  func encode<T>(_ value: T, key: String) where T : Encodable {
    do {
      let data = dataDictionary
      let ticketData = try JSONEncoder().encode(value)
      data[key] = ticketData
      self.dataDictionary = data
    } catch {
      TKLog.info(#file) { "Encoding of \(value) to \(key) failed due to: \(error)." }
    }
  }

  private var dataDictionary: NSMutableDictionary {
    get {
      guard let data = self.data as? Data else { return NSMutableDictionary() }

      let dictionary: NSDictionary?
      if #available(iOS 11.0, *) {
        do {
          // We have to include `NSArray` here, but not sure why; the result will
          // definitely be a dictionary, but if we don't include it, this will
          // fail with an error.
          dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses:
            [
              NSDictionary.self,
              NSArray.self,
              NSDate.self // timetable start + end date
            ]
            , from: data) as? NSDictionary
        } catch {
          TKLog.info(#file) { "Decoding new data failed due to: \(error). Data: \(String(decoding: data, as: UTF8.self))" }
          return NSMutableDictionary()
        }
      } else {
        dictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSDictionary
      }
      
      return dictionary.map(NSMutableDictionary.init(dictionary:)) ?? NSMutableDictionary()
    }
    
    set {
      if #available(iOS 11.0, *) {
        do {
          self.data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
        } catch {
          TKLog.info(#file) { "Encoding new data failed due to: \(error). Dict: \(newValue)" }
        }
        
      } else {
        self.data = NSKeyedArchiver.archivedData(withRootObject: newValue)
      }
    }
  }
}
