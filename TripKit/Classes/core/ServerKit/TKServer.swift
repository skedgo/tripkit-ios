//
//  TKServer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKServer {
  
  public static let shared = TKServer.__sharedInstance()
  
  public static func imageURL(iconFileNamePart: String, iconType: TKStyleModeIconType? = nil) -> URL? {
    let regionsURLString = TKServer.developmentServer() ?? "https://api.tripgo.com/v1"
    
    let isPNG: Bool
    let fileNamePrefix: String
    if let iconType = iconType {
      switch iconType {
      case .mapIcon:
        fileNamePrefix = "icon-map-info-"
        isPNG = true
        
      case .listMainMode:
        fileNamePrefix = "icon-mode-"
        isPNG = true
        
      case .resolutionIndependent:
        fileNamePrefix = "icon-mode-"
        isPNG = false
        
      case .vehicle:
        fileNamePrefix = "icon-vehicle-"
        isPNG = true
        
      case .alert:
        fileNamePrefix = "icon-alert-"
        isPNG = true
        
      @unknown default:
        assertionFailure("Unknown icon type: \(iconType)")
        return nil
      }

    } else {
      fileNamePrefix = ""
      isPNG = true
    }

    
    var fileNamePart = iconFileNamePart
    let fileExtension = isPNG ? "png" : "svg"
    if isPNG {
      let scale: CGFloat
      #if os(iOS) || os(tvOS)
      scale = UIScreen.main.scale
      #elseif os(OSX)
      scale = NSScreen.main?.backingScaleFactor ?? 1
      #endif
      
      if scale >= 2.9 {
        fileNamePart.append("@3x")
      } else if scale >= 1.9 {
        fileNamePart.append("@2x")
      }
    }
    
    var urlString = regionsURLString
    urlString.append("/modeicons/")
    urlString.append(fileNamePrefix)
    urlString.append(fileNamePart)
    urlString.append(".")
    urlString.append(fileExtension)
    return URL(string: urlString)
  }
  
}

extension TKServer {

  public enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
    case DELETE = "DELETE"
    case PUT = "PUT"
  }
  
  public enum ServerError: Error {
    case noData
  }

  public enum RepeatHandler {
    case repeatIn(TimeInterval)
    case repeatWithNewParameters(TimeInterval, [String: Any])
  }

  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil,
    callbackOnMain: Bool = true,
    completion: @escaping (Int?, [String: Any], Result<Model, Error>) -> Void
  ) {
    ___hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain,
      parseJSON: false,
      success: { status, headers, _, data in
        completion(status, headers, Result {
          try JSONDecoder().decode(Model.self, from: data.orThrow(ServerError.noData))
        })
      },
      failure: { error in
        completion(nil, [:], .failure(error))
      }
    )
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil,
    callbackOnMain: Bool = true,
    completion: @escaping (Int?, [String: Any], Result<Data, Error>) -> Void
  ) {
    ___hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain,
      parseJSON: false,
      success: { status, headers, _, data in
        completion(status, headers, Result { try data.orThrow(ServerError.noData) })
      },
      failure: { error in
        completion(nil, [:], .failure(error))
      }
    )
  }
  
  public static func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    completion: @escaping (Int, [String: Any], Result<Model, Error>) -> Void
  ) {
    ___hit(url,
          method: method.rawValue,
          parameters: parameters)
    { status, headers, _, data, error in
      completion(status, headers, Result {
        if let error = error {
          throw error
        } else {
          return try JSONDecoder().decode(Model.self, from: data.orThrow(ServerError.noData))
        }
      })
    }
  }
  
  public static func hit(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    completion: @escaping (Int, [String: Any], Result<Data, Error>) -> Void
  ) {
    ___hit(url,
          method: method.rawValue,
          parameters: parameters)
    { status, headers, _, data, error in
      completion(status, headers, Result {
        if let error = error {
          throw error
        } else {
          return try data.orThrow(ServerError.noData)
        }
      })
    }
  }
  
  public static func hitSync(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    timeout: DispatchTimeInterval
  ) throws -> Data {
    
    let semaphore = DispatchSemaphore(value: 1)
    var dataResult: Result<Data, Error>? = nil
    hit(url: url, parameters: parameters) { _, _, result in
      dataResult = result
    }
    _ = semaphore.wait(timeout: .now() + .seconds(10))
    return try dataResult.orThrow(ServerError.noData).get()
  }
  
  @objc(GET:paras:completion:)
  public static func _get(url: URL, parameters: [String: Any]? = nil, completion: @escaping (Int, [String: Any], Any?, Data?, Error?) -> Void) {
    hit(.GET, url: url, parameters: parameters) { status, headers, result in
      do {
        let data = try result.get()
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        completion(status, headers, json, data, nil)
      } catch {
        completion(status, headers, nil, nil, error)
      }
    }
  }
  
  @objc(POST:paras:completion:)
  public static func _post(url: URL, parameters: [String: Any]? = nil, completion: @escaping (Int, [String: Any], Any?, Data?, Error?) -> Void) {
    hit(.POST, url: url, parameters: parameters) { status, headers, result in
      do {
        let data = try result.get()
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        completion(status, headers, json, data, nil)
      } catch {
        completion(status, headers, nil, nil, error)
      }
    }
  }

}
