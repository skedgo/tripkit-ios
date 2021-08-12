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
  public struct Ticket: Codable, Hashable {
    /// User-friendly name of the ticket
    public let name: String
    
    /// ID of the ticket, where available this is the same as defined in GTFS
    public let fareID: String?
    
    /// Cost of the ticket, in the currency of the trip
    /// `nil` for re-used tickets
    public let cost: Decimal?
  }

  /// The ticket of this segment
  ///
  /// - note: This ticket's validity might extend beyond this segment, e.g., if the trip uses multiple public transport segments and this ticket is also valid for the other segments.
  public var ticket: Ticket? {  reference?.ticket }
  
}
