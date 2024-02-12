//
//  TKAnnotations.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

public enum TKServiceTiming: Hashable {
  case timetabled(arrival: Date?, departure: Date?)
  case frequencyBased(frequency: TimeInterval, start: Date?, end: Date?, totalTravelTime: TimeInterval?)
}

