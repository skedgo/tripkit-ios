//
//  TKGeoJSON+NamedCoordinate.swift
//  TripKit
//
//  Created by Adrian Schoenig on 03.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import Contacts

extension TKGeoJSON {
  
  func toNamedCoordinates() -> [TKNamedCoordinate] {
    switch self {
    case .collection(let features):
      return features.compactMap(TKNamedCoordinate.init(from:))
    case .feature(let feature):
      if let coordinate = TKNamedCoordinate(from: feature) {
        return [coordinate]
      } else {
        return []
      }
    }
  }
  
}

extension TKPeliasProperties {
  fileprivate var title: String {
    return name
  }
  
  fileprivate var subtitle: String? {
    guard #available(iOS 9.0, macOS 10.11, *) else { return label }
    
    let address = CNMutablePostalAddress()
    address.isoCountryCode = country_a ?? ""
    address.country = country ?? ""
    address.state = region ?? ""
    address.city = locality ?? neighbourhood ?? ""
    address.postalCode = postalcode ?? ""
    
    // https://en.wikipedia.org/wiki/Address_(geography)#Address_format
    //  > Conventions on the placing of house numbers differ: either before or after the street name. Similarly, there are differences in the placement of postal codes: in the UK, they are written on a separate line at the end of the address; in Australia, Canada and the United States, they usually appear immediately after the state or province, on the same line; in Austria, Belgium, France, Germany and The Netherlands they appear before the city, on the same line.
    if let street = street, let number = housenumber {
      switch country_a {
      case "AUS", "CAN", "USA":
        address.street = "\(number) \(street)"
      default:
        address.street = "\(street) \(number)"
      }
    } else {
      address.street = street ?? ""
    }
    
    // Don't duplicate the title in the subtitle
    if title.contains(address.street) {
      address.street = ""
    }
    let formatted = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
    
    return formatted.isEmpty ? label : formatted
  }
}

extension TKNamedCoordinate {
  
  fileprivate convenience init?(from geojson: TKGeoJSON.Feature) {
    switch geojson.geometry {
    case .point(let position):
      let pelias = geojson.properties as? TKPeliasProperties
      self.init(latitude: position.latitude, longitude: position.longitude, name: pelias?.title, address: pelias?.subtitle)
      
      clusterIdentifier = pelias?.layer
      dataSources = pelias?.dataSources ?? []
      
    default:
      return nil
    }
  }

}

extension TKPeliasProperties {
  
  private static let mapZenAttribution = API.DataAttribution(provider: API.CompanyInfo(name: "MapZen", website: URL(string: "https://mapzen.com")))
  
  private var specificSource: API.DataAttribution? {
    guard let source = source else { return nil }
    switch source {
    case "openaddresses", "oa":
      return API.DataAttribution(provider: API.CompanyInfo(name: "OpenAddresses", website: URL(string: "http://openaddresses.io/")))
      
    case "whosonfirst", "wof":
      return API.DataAttribution(provider: API.CompanyInfo(name: "Who's on First", website: URL(string: "https://whosonfirst.mapzen.com/")), disclaimer: "License available at http://whosonfirst.mapzen.com#License")

    case "openstreetmap", "osm":
      return API.DataAttribution(provider: API.CompanyInfo(name: "OpenStreetMap", website: URL(string: "https://openstreetmap.org")))

    case "geonames", "gn":
      return API.DataAttribution(provider: API.CompanyInfo(name: "GeoNames", website: URL(string: "http://www.geonames.org/")))
      
    default:
      assertionFailure("Attribution not handled: \(source)")
      return nil
    }
  }
  
  var dataSources: [API.DataAttribution] {
    var attributions = [TKPeliasProperties.mapZenAttribution]
    if let specificSource = self.specificSource {
      attributions.append(specificSource)
    }
    return attributions
  }
  
}
