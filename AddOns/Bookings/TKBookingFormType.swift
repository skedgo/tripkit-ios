//
//  TKBookingFormType.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKBookingFormType {
  
  case auth(BPKForm)
  case web(URL, disregardOn: URL, next: URL)
  case form(BPKForm)
  case trip(URL)
  case emptyResponse
  
}
