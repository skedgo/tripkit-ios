//
//  TKSegment+Ticket.swift
//  TripKit
//
//  Created by Adrian Schönig on 10.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

extension TKSegment {

  /// The ticket of this segment
  ///
  /// - note: This ticket's validity might extend beyond this segment, e.g., if the trip uses multiple public transport segments and this ticket is also valid for the other segments.
  public var ticket: TKAPI.Ticket? {  reference?.ticket }
  
}

#endif
