//
//  TKFlexAgenda.swift
//  RioGo
//
//  Created by Adrian Schoenig on 14/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

public struct TKFlexAgendaVisit {
  var coordinate: CLLocationCoordinate2D
  var id: String
}

extension TKFlexAgendaVisit: Hashable, Equatable {
  public var hashValue: Int {
    return id.hashValue
  }
}

public func ==(lhs: TKFlexAgendaVisit, rhs: TKFlexAgendaVisit) -> Bool {
  return abs(lhs.coordinate.latitude - rhs.coordinate.latitude) < 0.0001
          && abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 0.0001
          && lhs.id == rhs.id
}

public typealias ModeIdentifier = String
public typealias DistanceUnit = Float
public typealias PriceUnit = Float

public protocol TKFlexAgendaTripOption {
  
  var modes: [ModeIdentifier] { get }
  var duration: NSTimeInterval { get }
  var distance: DistanceUnit { get }
  var price: PriceUnit { get }
  
  var earliestDeparture: NSTimeInterval? { get }
  var latestDeparture: NSTimeInterval? { get }
}

extension TKFlexAgendaTripOption {
  var earliestDeparture: NSTimeInterval? { return nil }
  var latestDeparture: NSTimeInterval? { return nil }
  
}

public enum TKFlexAgendaOutputItem {
  case Visit(TKFlexAgendaVisit)
  case TripOptions([TKFlexAgendaTripOption])
  
  /**
   Placeholder for where a trip will likely be.
   */
  case TripPlaceholder
}

public struct TKFlexAgenda {

  public static func suggestOrder(locations: Set<TKFlexAgendaVisit>) -> Observable<[TKFlexAgendaOutputItem]> {
    return insert(locations, into: [])
  }

  public static func insert(locations: Set<TKFlexAgendaVisit>, into: [TKFlexAgendaVisit]) -> Observable<[TKFlexAgendaOutputItem]> {
    return TKFlexAgendaFaker.fakeInsert(locations, into: into)
  }

  public static func udpateTrips(visits: [TKFlexAgendaVisit]) -> Observable<[TKFlexAgendaOutputItem]> {
    return insert([], into: visits)
  }

}