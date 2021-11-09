//
//  TKBookingTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/12/16.
//
//

import Foundation

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
    public let confirmationMessage: String?
    public var input: [ActionInput]?
    
    public enum ActionType: String, Codable, CaseIterable {
      public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let string = try single.decode(String.self)
        self = ActionType(rawValue: string.lowercased()) ?? .unknown
      }
      
      case lock
      case unlock
      case cancel
      case returntrip
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
      case input
      case confirmationMessage
    }
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
    }
    
    public enum ReturnTripDateValue: Hashable {
      case unspecified
      case date(Date)
      case declined
    }
    
    public enum InputValue: Hashable {
      case singleSelection(InputOptionId)
      case multipleSelections([InputOptionId])
      case longText(String)
      case returnTripDate(ReturnTripDateValue)
    }
    
    public let type: InputType
    public let required: Bool
    public let id: String
    public let options: [InputOption]?
    public let title: String
    public var value: InputValue
    
    private enum CodingKeys: String, CodingKey {
      case id
      case required
      case type
      case options
      case title
      case value
      case values
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      id = try container.decode(String.self, forKey: .id)
      required = try container.decode(Bool.self, forKey: .required)
      options = try container.decodeIfPresent([InputOption].self, forKey: .options)
      title = try container.decode(String.self, forKey: .title)
      type = try container.decode(InputType.self, forKey: .type)
      
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
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      
      try container.encode(id, forKey: .id)
      try container.encode(required, forKey: .required)
      try container.encode(title, forKey: .title)
      try container.encode(type, forKey: .type)
      try container.encodeIfPresent(options, forKey: .options)
      
      switch value {
      case .singleSelection(let optionId):
        try container.encode(optionId, forKey: .value)
      case .longText(let value):
        try container.encode(value, forKey: .value)
      case .multipleSelections(let optionIds):
        try container.encode(optionIds, forKey: .values)
      case .returnTripDate(let returnDate):
        try container.encode(returnDate.toString(), forKey: .value)
      }
    }
  }
  
  public struct BookingNote: Codable, Hashable {
    public let provider: String
    public let text: String
    @ISO8601OrSecondsSince1970 public var timestamp: Date
  }
  
}

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
    } else if returnDateString == ReturnTripDateValue.declinedAsString {
      return .returnTripDate(.declined)
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
  
  static let declinedAsString = Loc.Declined
  
  public func toString(forJSONEncoding: Bool = true, timeZone: TimeZone = .autoupdatingCurrent) -> String {
    switch self {
    case .unspecified: return ""
    case .declined: return Self.declinedAsString
    case .date(let date):
      if forJSONEncoding {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
      } else {
        return TKStyleManager.string(for: date, for: timeZone, showDate: true, showTime: true)
      }
    }
  }
  
}
