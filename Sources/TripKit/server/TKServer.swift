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
    let regionsURLString = TKServer.developmentServer ?? "https://api.tripgo.com/v1"
    
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
  
  public static var developmentServer: String? {
    get {
      UserDefaults.shared.string(forKey: "developmentServer")
    }
    set {
      let oldValue = developmentServer
      if var newValue = newValue, !newValue.isEmpty {
        if !newValue.hasSuffix("/") {
          newValue.append("/")
        }
        UserDefaults.shared.set(newValue, forKey: "developmentServer")
      } else {
        UserDefaults.shared.removeObject(forKey: "developmentServer")
      }
      
      if newValue != oldValue {
        // User tokens are bound to servers, so we clear that, too
        TKServer.updateUserToken(nil)
      }
    }
  }
  
  public static var fallbackBaseURL: URL {
    developmentServer.flatMap(URL.init) ?? URL(string: "https://api.tripgo.com/v1/")!
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
  
  @objc // so that subclasses can override
  func baseURLs(for region: TKRegion?) -> [URL] {
    if let dev = Self.developmentServer.flatMap(URL.init) {
      return [dev]
    } else if let urls = region?.urls, !urls.isEmpty {
      return urls
    } else {
      return [URL(string: "https://api.tripgo.com/v1/")!]
    }
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
    hitSkedGo(
      method: method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain
    ) { status, header, result in
      completion(status, header, Result {
        try JSONDecoder().decode(Model.self, from: try result.get().orThrow(ServerError.noData))
      })
    }
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
    hitSkedGo(
      method: method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain
    ) { status, header, result in
      completion(status, header, Result {
        try result.get().orThrow(ServerError.noData)
      })
    }
  }
  
  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    decoderConfig: @escaping (JSONDecoder) -> Void = { _ in },
    completion: @escaping (Int, [String: Any], Result<Model, Error>) -> Void
  ) {
    hit(method: method,
        url: url,
        parameters: parameters)
    { status, headers, result in
      completion(status, headers, Result {
        let decoder = JSONDecoder()
        decoderConfig(decoder)
        return try decoder.decode(Model.self, from: try result.get().orThrow(ServerError.noData))
      })
    }
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    completion: @escaping (Int, [String: Any], Result<Data, Error>) -> Void
  ) {
    hit(method: method,
        url: url,
        parameters: parameters)
    { status, headers, result in
      completion(status, headers, Result {
        try result.get().orThrow(ServerError.noData)
      })
    }
  }
  
  public func hitSync(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    timeout: DispatchTimeInterval
  ) throws -> Data {
    
    let semaphore = DispatchSemaphore(value: 0)
    var dataResult: Result<Data, Error>? = nil
    hit(url: url, parameters: parameters) { _, _, result in
      dataResult = result
      semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + .seconds(10))
    return try dataResult.orThrow(ServerError.noData).get()
  }
  
  @objc(GET:paras:completion:)
  public func _get(url: URL, parameters: [String: Any]? = nil, completion: @escaping (Int, [String: Any], Any?, Data?, Error?) -> Void) {
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
  public func _post(url: URL, parameters: [String: Any]? = nil, completion: @escaping (Int, [String: Any], Any?, Data?, Error?) -> Void) {
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

// MARK: - Calling to Objective-C

extension TKServer {
  
  private func hitSkedGo(method: HTTPMethod, path: String, parameters: [String: Any]?, headers: [String: String]?, region: TKRegion?, callbackOnMain: Bool = true, completion: @escaping (Int?, [String: Any], Result<Data?, Error>) -> Void) {
    ___hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      headers: headers,
      baseURLs: NSMutableArray(array: baseURLs(for: region).shuffled()),
      callbackOnMain: callbackOnMain,
      info: { uuid, request, response, data, error in
        if let response = response {
          TKLog.log("TKServer", response: response, data: data, orError: error as NSError?, for: request, uuid: uuid)
        } else {
          TKLog.log("TKServer", request: request, uuid: uuid)
        }
      },
      success: { status, headers, data in
        if let error = TKError.error(from: data, statusCode: status) {
          completion(status, headers, .failure(error))
        } else {
          completion(status, headers, .success(data))
        }
        
      },
      failure: { error in
        completion(nil, [:], .failure(error))
      }
    )
  }
  
  private func hit(method: HTTPMethod, url: URL, parameters: [String: Any]?, completion: @escaping (Int, [String: Any], Result<Data?, Error>) -> Void) {
    
    if url.scheme == "file" {
      do {
        let filename = (url.lastPathComponent as NSString).deletingPathExtension
        let type = url.pathExtension
        let fileURLs = Bundle.allBundles.compactMap { bundle in
          return bundle.url(forResource: filename, withExtension: type)
        }
        guard let fileURL = fileURLs.first else {
          throw NSError(code: 14351, message: "Does not exit.")
        }
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data)
        let dict = json as? [String: Any] ?? [:]
        return completion(200, dict, .success(data))
      } catch {
        return completion(500, [:], .failure(error))
      }
    }
    
    ___hit(
      url,
      method: method.rawValue,
      parameters: parameters,
      info: { uuid, request, response, data, error in
        if let response = response {
          TKLog.log("TKServer", response: response, data: data, orError: error as NSError?, for: request, uuid: uuid)
        } else {
          TKLog.log("TKServer", request: request, uuid: uuid)
        }
      },
      completion: { status, headers, data, error in
        completion(status, headers, Result {
          if let error = error ?? TKError.error(from: data, statusCode: status) {
            throw error
          } else {
            return data
          }
        })
      }
    )
  }
  
}
