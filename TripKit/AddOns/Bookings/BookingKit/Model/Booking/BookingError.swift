//
//  BookingError.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 4/04/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum BookingError: Error {
  
  case missingServerResponse
  
}

public enum OAuthError: Error {
  
  case malformedServerResponse
  case unableToBuildPostForm
  case unableToBuildParameters
  case unexpectedCallback
  
}

