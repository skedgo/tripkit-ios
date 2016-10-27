//
//  TKBuzzInfoProvider.swift
//  TripGo
//
//  Created by Adrian Schoenig on 11/12/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import RxSwift
import Marshal

// MARK: - Data Models -

public class RegionInformation: NSObject, Unmarshaling {
  
  public let streetBikePaths: Bool
  public let streetWheelchairAccessibility: Bool
  public let transitModes: [ModeInfo]
  public let transitBicycleAccessibility: Bool
  public let transitConcessionPricing: Bool
  public let transitWheelchairAccessibility: Bool
  public let paratransitInformation: ParatransitInformation?
  
  public required init(object: MarshaledObject) throws {
    streetBikePaths = (try? object.value(for: "streetBikePaths")) ?? false
    streetWheelchairAccessibility = (try? object.value(for: "streetWheelchairAccessibility")) ?? false
    transitModes = (try? object.value(for: "transitModes")) ?? []
    transitBicycleAccessibility = (try? object.value(for: "transitBicycleAccessibility")) ?? false
    transitConcessionPricing = (try? object.value(for: "transitConcessionPricing")) ?? false
    transitWheelchairAccessibility = (try? object.value(for: "transitWheelchairAccessibility")) ?? false
    paratransitInformation = try? object.value(for: "paratransit")
  }
  
}

public final class TransitAlertInformation: NSObject, Unmarshaling, TKAlert {
  public let title: String
  public let text: String?
  public let infoURL: URL?
  public let iconURL: URL?
  public let severity: AlertSeverity
  public let lastUpdated: Date?
  
  public var sourceModel: AnyObject? {
    return self
  }
  
  public var icon: UIImage? {
    let iconType: STKInfoIconType
    switch severity {
    case .info, .warning:
      iconType = .warning
    case .alert:
      iconType = .alert
    }
    
    return STKInfoIcon.image(for: iconType, usage: .normal)
  }
  
  public required init(object: MarshaledObject) throws {
    title = try object.value(for: "title")
    text = try? object.value(for: "text")
    infoURL = try? object.value(for: "url")
    iconURL = try? object.value(for: "iconURL")
    severity = try AlertSeverity.value(from: "severity")
    lastUpdated = try? object.value(for: "lastUpdate")
  }
}


/**
 Informational class for paratransit information (i.e., transport for people with disabilities).
 Contains name of service, URL with more information and phone number.
 
 - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
 */
public final class ParatransitInformation: NSObject, Unmarshaling {
  public let name: String
  public let URL: String
  public let number: String
  
  public required init(object: MarshaledObject) throws {
    name   = try object.value(for: "name")
    URL    = try object.value(for: "URL")
    number = try object.value(for: "number")
  }
}

public struct CarParkInfo : Unmarshaling {
  public let identifier: String
  public let name: String
  public let availableSpaces: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?

  public init(object: MarshaledObject) throws {
    identifier = try object.value(for: "identifier")
    name = try object.value(for: "name")
    availableSpaces = try? object.value(for: "availableSpaces")
    totalSpaces = try? object.value(for: "totalSpaces")
    lastUpdate = try? object.value(for: "lastUpdate")
  }
}

public class LocationInformation : NSObject, Unmarshaling {
  public let what3word: String?
  public let what3wordInfoURL: URL?
  public let transitStop: STKStopAnnotation?
  public let carParkInfo: CarParkInfo?
  
  public required init(object: MarshaledObject) throws {
    what3word = try? object.value(for: "details.w3w")
    what3wordInfoURL = try? object.value(for: "details.w3wInfoURL")
    
    let stop: STKStopCoordinate? = try? object.value(for: "stop")
    transitStop = stop
    
    carParkInfo = try? object.value(for: "carPark")
  }
  
  public var hasRealTime: Bool {
    if let carParkInfo = carParkInfo {
      return carParkInfo.availableSpaces != nil
    } else {
      return false
    }
  }
}

// MARK: - Protocol

@objc public protocol TKAlert {
  
  var icon: UIImage? { get }
  var iconURL: URL? { get }
  var title: String { get }
  var text: String? { get }
  var infoURL: URL? { get }
  var lastUpdated: Date? { get }
  
}

// MARK: - Fetcher methods -

extension TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches additional region information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchRegionInformation(forRegion region: SVKRegion, completion: @escaping (RegionInformation?) -> Void)
  {
    SVKServer.fetch(RegionInformation.self,
                    method: .POST, path: "regionInfo.json",
                    parameters: ["region": region.name],
                    region: region,
                    keyPath: "regions[0]",
                    completion: completion)
  }
  
  /**
   Asynchronously fetches paratransit information for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchParatransitInformation(forRegion region: SVKRegion, completion: @escaping (ParatransitInformation?) -> Void)
  {
    SVKServer.fetch(ParatransitInformation.self,
                    method: .POST, path: "regionInfo.json",
                    parameters: ["region": region.name],
                    region: region,
                    keyPath: "regions[0].transitModes",
                    completion: completion)
  }
  
  /**
   Asynchronously fetches all available individual public transport modes for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchPublicTransportModes(forRegion region: SVKRegion, completion: @escaping ([ModeInfo]) -> Void)
  {
    SVKServer.fetchArray(ModeInfo.self,
                         method: .POST, path: "regionInfo.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "regions[0].transitModes",
                         completion: completion)
  }
  
  /**
   Asynchronously fetches additional location information for a specified coordinate.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchLocationInformation(_ coordinate: CLLocationCoordinate2D, forRegion region: SVKRegion, completion: @escaping (LocationInformation?) -> Void) {
    
    let paras: [String: Any] = [
      "lat": coordinate.latitude,
      "lng": coordinate.longitude
    ]
    
    SVKServer.fetch(LocationInformation.self,
                    path: "locationInfo.json",
                    parameters: paras,
                    region: region,
                    completion: completion)
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region.
   
   - Note: Completion block is executed on the main thread.
   */
  public class func fetchTransitAlerts(forRegion region: SVKRegion, completion: @escaping ([TransitAlertInformation]) -> Void) {
    let paras = [
      "region": region.name
    ]
    
    SVKServer.fetchArray(TransitAlertInformation.self,
                         path: "alerts/transit.json",
                         parameters: ["region": region.name],
                         region: region,
                         keyPath: "alerts",
                         completion: completion)
  }
  
  /**
   Asynchronously fetches transit alerts for the provided region using Rx.
   */
  public class func rx_fetchTransitAlerts(forRegion region: SVKRegion) -> Observable<[TKAlert]> {
    let paras: [String: Any] = [
      "region": region.name as Any
    ]
    
    return SVKServer.sharedInstance().rx
      .hit(.GET, path: "alerts/transit.json", parameters: paras, region: region)
      .map { (_, response) -> [TKAlert] in
        if let json = response as? [String: Any] {
          let alerts: [TransitAlertInformation]? = try? json.value(for: "alerts")
          return alerts ?? []
        } else {
          return []
        }
    }
  }
}


// MARK: - Helper Extensions -

extension Date: ValueType {
  public static func value(from object: Any) throws -> Date {
    guard let seconds = object as? TimeInterval else {
      throw MarshalError.typeMismatch(expected: TimeInterval.self, actual: type(of: object))
    }
    return Date(timeIntervalSince1970: seconds)
  }
}

extension AlertSeverity: ValueType {
  public static func value(from object: Any) throws -> AlertSeverity {
    guard let rawValue = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    switch rawValue {
    case "alert": return .alert
    case "warning": return .warning
    default: return .info
    }
  }
  
}

extension SVKServer {
  
  fileprivate class func fetch<E: Unmarshaling>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: SVKRegion,
    keyPath: String? = nil,
    completion: @escaping (E?) -> Void
  )
  {
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      success: { _, response in
        guard let json = response as? [String: Any] else {
          preconditionFailure() // FIXME
        }
        do {
          let result: E
          if let keyPath = keyPath {
            result = try json.value(for: keyPath)
          } else {
            result = try E(object: json)
          }
          completion(result)
        } catch {
          SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
          completion(nil)
        }
    },
      failure: { error in
        SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
        completion(nil)
    })
  }
  
  fileprivate class func fetchArray<E: Unmarshaling>(
    _ type: E.Type,
    method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    region: SVKRegion,
    keyPath: String? = nil,
    completion: @escaping ([E]) -> Void
    )
  {
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      success: { _, response in
        guard let json = response as? [String: Any] else {
          preconditionFailure() // FIXME
        }
        do {
          let result: [E]
          if let keyPath = keyPath {
            result = try json.value(for: keyPath)
          } else {
            result = try Array<E>.value(from: json)
          }
          completion(result)
        } catch {
          SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
          completion([])
        }
    },
      failure: { error in
        SGKLog.debug("TKBuzzInfoProvider") { "Encountered \(error), when fetching \(path), paras: \(parameters)" }
        completion([])
    })
  }
  
}
