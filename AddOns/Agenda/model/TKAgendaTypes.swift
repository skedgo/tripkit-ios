//
//  TKAgendaInputType.swift
//  TripGo
//
//  Created by Adrian Schoenig on 3/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import CoreLocation

@objc
protocol TKAgendaType: NSObjectProtocol {
  var startDate: NSDate { get }
  var endDate: NSDate { get }
  var items: [TKAgendaInputType] { get }
}

@objc
protocol TKAgendaInputType: NSObjectProtocol {
  var startDate: NSDate? { get }
  var endDate: NSDate? { get }
  var timeZone: NSTimeZone { get }
}

@objc
enum TKAgendaEventKind: Int {
  case CurrentLocation
  case Activity
  case Routine
  case Stay
  case Home
}

@objc
protocol TKAgendaEventInputType: TKAgendaInputType {
  
  /**
   The coordinate where this input item takes place. The agenda will try to route here. Invalid coordinates will be ignored.
   */
  var coordinate: CLLocationCoordinate2D { get }
  
  var identifier: String? { get }
  
  var title: String { get }
  
  var kind: TKAgendaEventKind { get }
  
  var includeInRoutes: Bool { get }
  
  var goHereDirectly: Bool { get }
}

@objc
protocol TKAgendaTripInputType: TKAgendaInputType {
  var origin: CLLocationCoordinate2D { get }
  var destination: CLLocationCoordinate2D { get }
  
  /**
   - returns: The trip this trip input item is for. If this is `nil`, make sure to return soemthing from `modes`.
   */
  var trip: Trip? { get }
  
  /**
   - returns: The used modes of this trip. Only needs to return something if `trip` returns nil`.
   */
  var modes: [String]? { get }
}

@objc
protocol TKAgendaOutputType: NSObjectProtocol {
}

@objc
protocol TKAgendaEventOutputType: TKAgendaOutputType {
  var input: TKAgendaEventInputType { get }
  var effectiveStart: NSDate { get }
  var effectiveEnd: NSDate? { get }
  var isContinuation: Bool { get }
}

@objc
protocol TKAgendaTripOutputType: TKAgendaOutputType {
  var input: TKAgendaTripInputType? { get }
  var trip: Trip { get }

  var fromIdentifier: String? { get set }
  var toIdentifier: String? { get set }
}
