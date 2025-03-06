//
//  TKAPI+Icons.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import Foundation

extension TKAPI.CompanyInfo {
  
  public var remoteIconURL: URL? {
    guard let fileNamePart = remoteIcon else {
      return nil
    }
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
  }
  
  public var remoteDarkIconURL: URL? {
    guard let fileNamePart = remoteDarkIcon else {
      return nil
    }
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
  }
  
}

extension TKBooking.TSPBranding {
  public var downloadableLogoURL: URL? {
    guard let fileNamePart = logoImageName else { return nil }
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
  }
}
