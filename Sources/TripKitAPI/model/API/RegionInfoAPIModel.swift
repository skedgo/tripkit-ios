//
//  RegionAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct RegionInfo: Codable, Hashable {
    public let streetBicyclePaths: Bool
    public let streetWheelchairAccessibility: Bool
    public let transitModes: [TKModeInfo]
    public let transitBicycleAccessibility: Bool
    public let transitConcessionPricing: Bool
    public let transitWheelchairAccessibility: Bool
    public let paratransit: Paratransit?
    
    /// Additional information for some of the modes in the region.
    /// Dictionary of a generic mode identifier to the details.
    ///
    /// Use `TKTransportMode.genericModeIdentifier` to get the
    /// generic part of any mode identifier.
    public let modes: [String: GenericModeDetails]
  }

  /// Informational class for paratransit information (i.e., transport for people with disabilities).
  /// Contains name of service, URL with more information and phone number.
  ///
  /// Formerly known as `TKParatransitInfo`
  /// - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
  public struct Paratransit: Codable, Hashable {
    public let name: String
    public let url: URL
    public let number: String

    private enum CodingKeys: String, CodingKey {
      case name
      case url = "URL"
      case number
    }
  }
  
  public enum Integrations: String, Codable {
    case routing
    case realTime = "real_time"
    case bookings
    case payments
  }
  
  /// Additional details about a group of modes,
  /// e.g., all bike or car share providers in a city
  public struct GenericModeDetails: Codable, Hashable {
    /// Name of the group
    public let title: String
    
    /// Additional info about the mode group
    public let modeInfo: TKModeInfo
    
    /// The specific modes of this group that are
    /// available for your API key.
    @DefaultEmptyArray public var specificModes: [SpecificModeDetails]
    
    /// Additional specific modes that are available
    /// on the platform, but not currently available
    /// for your API key.
    ///
    /// See https://developer.tripgo.com/extensions/
    /// for how to unlock them, or get in touch with
    /// someone from the TripGo API team.
    @DefaultEmptyArray public var lockedModes: [SpecificModeDetails]
  }
  
  /// Additional details about a specific mode, where the
  /// specific mode usually relates to a certain transport
  /// provider, such as a car-sharing provider, bike-sharing
  /// provider, limousine company, or TNC.
  public struct SpecificModeDetails: Codable, Hashable {
    /// Name of thise mode
    public let title: String?
    
    /// Additional info about the mode
    public let modeInfo: TKModeInfo
    
    /// Available integrations for this mode that are available
    /// through the TripGo API.
    @DefaultEmptyArray public var integrations: [Integrations]
    
    /// URL of the primary transport provider of this mode.
    public let url: URL?

    /// Minimum cost for a membership for the provider
    /// of this mode. Typically applies to car share
    /// and bike share.
    public let minimumLocalCostForMembership: Decimal?
    
    /// List of public transport operator names servicing
    /// this mode. (Public transport modes only)
    @DefaultEmptyArray public var operators: [String]
    
    /// List of image name-parts related to this operator
    @DefaultEmptyArray public var modeImageNames: [String]
    
    public var identifier: String {
      if let id = modeInfo.identifier {
        return id
      } else {
        assertionFailure("Specific mode details should always have an identifier. Missing for '\(String(describing:self))'.")
        return ""
      }
    }
  }
  
}
