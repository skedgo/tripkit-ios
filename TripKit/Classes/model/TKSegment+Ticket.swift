//
//  TKSegment+Ticket.swift
//  TripKit
//
//  Created by Adrian Schönig on 10.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKSegment {
  
  /// Ticket information, for public transport segments
  public struct Ticket: Codable {
    /// User-friendly name of the ticket
    public let name: String
    
    /// ID of the ticket, where available this is the same as defined in GTFS
    public let fareID: String?
    
    /// Cost of the ticket, in the currency of the trip
    public let cost: Decimal
  }

  /// The ticket of this segment
  ///
  /// - note: This ticket's validity might extend beyond this segment, e.g., if the trip uses multiple public transport segments and this ticket is also valid for the other segments.
  public var ticket: Ticket? {  reference?.ticket }
  
}

extension SegmentReference {
  private var dataDictionary: NSMutableDictionary {
    get {
      guard let data = self.data as? Data else { return NSMutableDictionary() }

      let dictionary: NSDictionary?
      if #available(iOS 11.0, *) {
        do {
          // We have to include `NSArray` here, but not sure why; the result will
          // definitely be a dictionary, but if we don't include it, this will
          // fail with an error.
          dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSArray.self], from: data) as? NSDictionary
        } catch {
          TKLog.info("TKSegment+Ticket") { "Decoding new data failed due to: \(error)" }
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
          TKLog.info("TKSegment+Ticket") { "Encoding new data failed due to: \(error)" }
        }
        
      } else {
        self.data = NSKeyedArchiver.archivedData(withRootObject: newValue)
      }
    }
  }
  
  var ticket: TKSegment.Ticket? {
    get {
      guard let ticketData = dataDictionary["ticket"] as? Data else { return nil }
      return try? JSONDecoder().decode(TKSegment.Ticket.self, from: ticketData)
    }
    set {
      let data = dataDictionary
      if let ticketData = try? JSONEncoder().encode(newValue) {
        data["ticket"] = ticketData
      } else {
        data["ticket"] = nil
      }
      self.dataDictionary = data
    }
  }
   
  /// :nodoc:
  @objc
  public func _updateTicket(dictionary: [String: AnyHashable]?) {
    guard let dictionary = dictionary else { return }
    ticket = try? JSONDecoder().decode(TKSegment.Ticket.self, withJSONObject: dictionary)
  }
}
