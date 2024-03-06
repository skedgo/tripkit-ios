//
//  TKBookingTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/12/16.
//
//

import Foundation

import CoreLocation

/// Case-less enum just to create a namespace
public enum TKBooking {
  
  public struct Detail: Codable, Hashable {
    public let title: String
    public let subtitle: String?
    public let imageURL: URL?
  }
  
  public struct Action: Codable, Hashable {
    public let title: String
    public let isDestructive: Bool
    public let internalURL: URL?
    public let externalAction: String?
    public let type: ActionType?
    @available(*, deprecated, message: "confirmationMessage property is deprecated, please use confirmation.message instead.")
    public let confirmationMessage: String?
    public let confirmation: ActionConfirmation?
    public var input: [ActionInput]?
    
    public enum ActionType: String, Codable, CaseIterable {
      public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let string = try single.decode(String.self)
        self = ActionType(rawValue: string) ?? .unknown
      }
      
      case lock = "LOCK"
      case unlock = "UNLOCK"
      case cancel = "CANCEL"

      /// Tells the app to show another trip when tapped; comes with an internal URL
      case showTrip = "SHOW_RELATED_TRIP"

      /// Tells the app to plan another trip, aka "request another"; no URL or external action provided
      case planNext = "REQUESTANOTHER"
      
      /// Tells the app to show the list of purchased tickets; no URL or external action provided
      case showTickets = "SHOW_TICKETS"
      
      /// Tells the app that the action will activate tickets; comes with an internal URL or external action
      case activateTickets = "ACTIVATE_TICKETS"
      
      case unknown
    }
    
    public struct ActionInput: Codable, Hashable {
      public let field: String
      public var value: String?
      
      private enum CodingKeys: String, CodingKey {
        case field
        case value
      }
    }
    
    private enum CodingKeys: String, CodingKey {
      case title
      case isDestructive
      case internalURL
      case externalAction = "externalURL"
      case type
      case confirmationMessage
      case confirmation
      case input
    }
  }
    
  public struct ActionConfirmation: Codable, Hashable {
    public let message: String
    public let abortActionTitle: String
    public let confirmActionTitle: String
  }
  
  public struct TSPBranding: Codable, Hashable {
    private let rgbColor: TKAPI.RGBColor?
    private let logoImageName: String?
    
    private enum CodingKeys: String, CodingKey {
      case rgbColor = "color"
      case logoImageName = "remoteIcon"
    }
    
    public var color: TKColor? {
      return rgbColor?.color
    }
    
    public var downloadableLogoURL: URL? {
      guard let fileNamePart = logoImageName else { return nil }
      return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
    }
  }
  
  public struct Purchase: Codable, Hashable {
    public let id: String
    private let rawPrice: Double?
    public let currency: String?
    public let budgetPoints: Int?
    public let productName: String?
    public let productType: String?
    public let waitTime: Int?
    private let explicitValidity: Bool?
    public let validFor: TimeInterval?
    public let branding: TSPBranding?
    public let attribution: TKAPI.DataAttribution?
    @OptionalISO8601OrSecondsSince1970 public var validFrom: Date?
    @OptionalISO8601OrSecondsSince1970 public var paymentDate: Date?
    
    private enum CodingKeys: String, CodingKey {
      case id
      case rawPrice = "price"
      case currency
      case budgetPoints
      case productName
      case productType
      case waitTime = "pickupWindowDuration"
      case explicitValidity = "valid"
      case validFor
      case validFrom = "validFromTimestamp"
      case branding = "brand"
      case attribution = "source"
      case paymentDate = "paymentTimestamp"
    }
    
    public var price: NSDecimalNumber? {
      guard let rawPrice = rawPrice else { return nil }
      return NSDecimalNumber(value: rawPrice)
    }
    
    public var isValid: Bool {
      if let valid = explicitValidity { return valid }
      
      // If we don't have an expiry date for the ticket, treat it as valid.
      guard let ticketExpiryDate = validTo else {
        assertionFailure("Purchase has neither valid nor validFrom + validFor")
        return true
      }
      
      // Expiring in the future
      return ticketExpiryDate.timeIntervalSinceNow > 0
    }
    
    public var validTo: Date? {
      guard let from = validFrom, let duration = validFor else { return nil }
      return from.addingTimeInterval(duration)
    }
    
  }
  
  public struct Confirmation: Codable, Hashable {
    public let status: Detail
    public let provider: Detail?
    public let vehicle: Detail?
    public let purchase: Purchase?
    public let actions: [Action]?
    public let input: [BookingInput]?
    public let notes: [BookingNote]?
    
    /// Tickets that were previously purchased, with information for which fare and their status
    @DefaultEmptyArray public var purchasedTickets: [PurchasedTicket]
  }
  
  public struct BookingInput: Codable, Hashable {
    public typealias InputOptionId = String
    
    public struct InputOption: Codable, Hashable {
      public let id: InputOptionId
      public let title: String
    }
    
    public enum InputType: String, Codable {
      case longText = "LONG_TEXT"
      case singleSelection = "SINGLE_CHOICE"
      case multipleSelections = "MULTIPLE_CHOICE"
      case requestReturnTrip = "RETURN_TRIP"
      case number = "NUMBER"
      case terms = "TERMS"
    }
    
    public enum ReturnTripDateValue: Hashable {
      case unspecified
      case date(Date)
      case oneWayTrip
    }
    
    public enum InputValue: Hashable {
      case singleSelection(InputOptionId)
      case multipleSelections([InputOptionId])
      case longText(String)
      case returnTripDate(ReturnTripDateValue)
      case number(Int, min: Int?, max: Int?)
      case terms(URL, accepted: Bool)
    }
    
    public let required: Bool
    public let id: String
    public let options: [InputOption]?
    public let title: String
    public var value: InputValue
    
    public var type: InputType {
      switch value {
      case .longText: return .longText
      case .singleSelection: return .singleSelection
      case .multipleSelections: return .multipleSelections
      case .returnTripDate: return .requestReturnTrip
      case .number: return .number
      case .terms: return .terms
      }
    }
    
    private enum CodingKeys: String, CodingKey {
      case id
      case required
      case type
      case options
      case title
      case value
      case values
      case urlValue
      case minValue
      case maxValue
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      id = try container.decode(String.self, forKey: .id)
      required = try container.decode(Bool.self, forKey: .required)
      options = try container.decodeIfPresent([InputOption].self, forKey: .options)
      title = try container.decode(String.self, forKey: .title)
      let type = try container.decode(InputType.self, forKey: .type)
      
      switch type {
      case .longText:
        let longText = try container.decode(String.self, forKey: .value)
        value = .longText(longText)
      case .singleSelection:
        let selectedOptionId = try container.decode(String.self, forKey: .value)
        value = .singleSelection(selectedOptionId)
      case .multipleSelections:
        let selectedOptionIds = try container.decode([String].self, forKey: .values)
        value = .multipleSelections(selectedOptionIds)
      case .requestReturnTrip:
        let specifiedReturnDate = try container.decode(String.self, forKey: .value)
        value = Self.convertStringReturnDateToInputValue(specifiedReturnDate)
      case .number:
        // SIC. `value` is always a string!
        let rawValue = try container.decode(String.self, forKey: .value)
        let number = Int(rawValue) ?? 0
        let minValue = try container.decodeIfPresent(Int.self, forKey: .minValue)
        let maxValue = try container.decodeIfPresent(Int.self, forKey: .maxValue)
        value = .number(number, min: minValue, max: maxValue)
      case .terms:
        // SIC. `value` is always a string!
        let rawValue = try container.decode(String.self, forKey: .value)
        let accepted = rawValue == "true"
        let url = try container.decode(URL.self, forKey: .urlValue)
        value = .terms(url, accepted: accepted)
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      
      try container.encode(id, forKey: .id)
      try container.encode(required, forKey: .required)
      try container.encode(title, forKey: .title)
      try container.encodeIfPresent(options, forKey: .options)
      
      try container.encode(type, forKey: .type)
      switch value {
      case .singleSelection(let optionId):
        try container.encode(optionId, forKey: .value)
      case .longText(let value):
        try container.encode(value, forKey: .value)
      case .multipleSelections(let optionIds):
        try container.encode(optionIds, forKey: .values)
      case .returnTripDate(let returnDate):
        try container.encode(returnDate.toString(), forKey: .value)
      case let .number(number, min, max):
        try container.encode(String(number), forKey: .value)
        try container.encode(min, forKey: .minValue)
        try container.encode(max, forKey: .maxValue)
      case let .terms(url, accepted):
        try container.encode(accepted, forKey: .value)
        try container.encode(url, forKey: .urlValue)
      }
    }
  }
  
  public struct BookingNote: Codable, Hashable {
    public let provider: String
    public let text: String
    @ISO8601OrSecondsSince1970 public var timestamp: Date
  }
  
  public struct Location: Codable, Hashable {
    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees
    
    public let name: String?
    
    public let address: String?
    
    public enum CodingKeys: String, CodingKey {
      case latitude = "lat"
      case longitude = "lng"
      case name
      case address
    }
  }
  
}

extension TKBooking {
  
  public struct Fare: Codable, Hashable {
    public enum Status: String, Codable {
      case inactive = "UNACTIVATED"
      case activated = "ACTIVE"
      case stale = "STALE_TICKET"
      case activeOnAnotherDevice = "ACTIVE_ON_ANOTHER_DEVICE"
      case expired = "EXPIRED"
      case unused = "UNUSED"
      case refunded = "REFUNDED"
      case invalid = "INVALID"
      case fareCapped = "FARE_CAPPED"
    }
    
    public enum RideType: String, Codable {
      case single = "single_ride"
      case multiple = "multiple_rides"
    }
    
    public typealias Identifier = String
    
    public let id: Identifier
    public let name: String
    public let details: String
    
    /// Price in cents
    public let price: Int?

    public let currencyCode: String?

    /// Number of tickets to pre-select, can also be used to define how many tickets to purchase for this fare
    public var amount: Int?

    /// Maximum number of tickets that can be purchased of this fare
    public var max: Int?
    
    /// list of riders under the fare for filtering purposes
    @DefaultEmptyArray public var riders: [TKBooking.Rider]
    
    /// Selected rider to filter
    public var rider: TKBooking.Rider?
    
    public let status: Status?
    
    public let type: RideType?

    public enum CodingKeys: String, CodingKey {
      case id
      case name
      case details = "description"
      case price
      case currencyCode = "currency"
      case amount = "value"
      case max
      case riders
      case status
      case type
    }
    
    public enum InputValue: Hashable {
      case selection(Fare.Identifier)
      case amount(Int)
    }

  }
  
  public struct Rider: Codable, Hashable {
    public typealias Identifier = String
    
    public var id: Identifier
    public var name: String
    public var description: String?

    public enum CodingKeys: String, CodingKey {
      case id
      case name
      case description
    }
  }
  
  public struct PurchasedTicket: Codable, Hashable {
    public typealias Status = Fare.Status
    
    public typealias Identifier = String
    
    public let id: Identifier
    
    public let status: Status?

    /// URL to fetch ticket details, provided if `status == .activated`
    public let ticketURL: URL?
    
    public let qrCode: String?

    @DefaultEmptyArray public var actions: [Action]

    /// Timestamp when an activated ticket expires, might be provided if `status == .activated`
    @OptionalISO8601 public var ticketExpiration: Date?
    
    @OptionalISO8601 public var purchased: Date?
    @OptionalISO8601 public var validFrom: Date?
    @OptionalISO8601 public var validUntil: Date?
    
    public let fare: Fare
    
    public enum CodingKeys: String, CodingKey {
      case id
      case fare
      case status
      case ticketURL
      case actions
      case qrCode

      case ticketExpiration = "ticketExpirationTimestamp"
      case purchased = "purchasedTimestamp"
      case validFrom = "validFromTimestamp"
      case validUntil = "validUntilTimestamp"
    }

  }
   
}

// MARK: - Helpers

extension TKBooking.BookingInput {
  
  public var longText: String? {
    switch value {
    case .longText(let value): return value
    default: return nil
    }
  }
  
  public var singleSelection: String? {
    switch value {
    case .singleSelection(let value): return value
    default: return nil
    }
  }
  
  public var multipleSelections: [String]? {
    switch value {
    case .multipleSelections(let values): return values
    default: return nil
    }
  }
  
  public func displayTitle(for optionId: InputOptionId) -> String? {
    return options?.first(where: { $0.id == optionId })?.title
  }
  
  private static func convertStringReturnDateToInputValue(_ returnDateString: String) -> InputValue {
    if returnDateString.isEmpty {
      return .returnTripDate(.unspecified)
    } else if returnDateString == Loc.OneWayOnly {
      return .returnTripDate(.oneWayTrip)
    } else {
      let formatter = ISO8601DateFormatter()
      if let date = formatter.date(from: returnDateString) {
        return .returnTripDate(.date(date))
      } else {
        assertionFailure()
        return .returnTripDate(.unspecified)
      }
    }
  }
  
}

extension TKBooking.BookingInput.ReturnTripDateValue {
  
  public func toString(forJSONEncoding: Bool = true, timeZone: TimeZone = .autoupdatingCurrent) -> String {
    switch self {
    case .unspecified: return ""
    case .oneWayTrip: return Loc.OneWayOnly
    case .date(let date):
      if forJSONEncoding {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
      } else {
        return TKStyleManager.format(date, for: timeZone, showDate: true, showTime: true)
      }
    }
  }
  
}

extension TKBooking.Fare {
  
  public func priceValue(locale: Locale = .current) -> String? {
    guard let price, let currencyCode else { return nil }
    return NSNumber(value: Float(price) / 100).toMoneyString(currencyCode: currencyCode, locale: locale)
  }

  public func noAmount() -> Bool {
    return amount ?? 0 == 0
  }
  
}
