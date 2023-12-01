//
//  TKServer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKServer {
  
  public static let shared = TKServer(isShared: true)
  
  init(isShared: Bool) {
    self.isShared = isShared
    
    if isShared {
      userToken = UserDefaults.shared.string(forKey: "userToken")
    }
  }
  
  @available(*, unavailable, renamed: "customBaseURL")
  public static var developmentServer: String? {
    get { customBaseURL }
    set { customBaseURL = newValue }
  }

  /// Custom base URL to use, instead of hitting SkedGo's default servers directly.
  ///
  /// - Note: This is persistently saved to `UserDefaults`
  public static var customBaseURL: String? {
    get {
      UserDefaults.shared.string(forKey: "developmentServer")
    }
    set {
      let newValue = newValue.map { value in
        value.hasSuffix("/") ? value : value.appending("/")
      }
      let oldValue = customBaseURL
      if let newValue = newValue, !newValue.isEmpty {
        UserDefaults.shared.set(newValue, forKey: "developmentServer")
      } else {
        UserDefaults.shared.removeObject(forKey: "developmentServer")
      }
      
      if newValue != oldValue {
        // User tokens are bound to servers, so we clear that, too
        TKServer.shared.userToken = nil
      }
    }
  }
  
  /// Base URL to use for server calls when `customBaseURL` is not set and the server calls
  /// do not specify a ```TKRegion```.
  public static var fallbackBaseURL: URL {
    customBaseURL.flatMap(URL.init) ?? URL(string: "https://api.tripgo.com/v1/")!
  }
  
  let isShared: Bool
  
  /// Your TripGo API key
  public var apiKey: String = ""
  
  /// Custom headers to use, passed allong with calls
  public var customHeaders: [String: String]?
  
  public var userToken: String? {
    didSet {
      guard isShared else { return }
      if let token = userToken?.nonEmpty {
        UserDefaults.shared.set(token, forKey: "userToken")
      } else {
        UserDefaults.shared.removeObject(forKey: "userToken")
      }
    }
  }
  
  func baseURLs(for region: TKRegion?) -> [URL] {
    if let dev = Self.customBaseURL.flatMap(URL.init) {
      return [dev]
    } else if let urls = region?.urls, !urls.isEmpty {
      return urls
    } else {
      return [URL(string: "https://api.tripgo.com/v1/")!]
    }
  }
  
}

extension TKServer {

  public enum HTTPMethod: String, Codable {
    case POST = "POST"
    case GET = "GET"
    case DELETE = "DELETE"
    case PUT = "PUT"
  }
  
  public enum RequestError: Error {
    case invalidURL
    case noBaseURLs
  }
  
  public enum ServerError: Error {
    case noData
  }
  
  public enum RepeatHandler {
    case repeatIn(TimeInterval)
    case repeatWithNewParameters(TimeInterval, [String: Any])
  }
}

// MARK: - Hit (Path)

extension TKServer {
  
  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil,
    callbackOnMain: Bool = true,
    completion: @escaping (Int, [String: Any], Result<Model, Error>) -> Void
  ) {
    hitSkedGo(
      method: method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain
    ) { response in
      response.map  { data in
        guard let data, !data.isEmpty else { throw ServerError.noData }
        return try JSONDecoder().decode(Model.self, from: data)
        
      }.call(completion)
    }
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil,
    callbackOnMain: Bool = true,
    completion: @escaping (Int, [String: Any], Result<Data, Error>) -> Void
  ) {
    hitSkedGo(
      method: method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: callbackOnMain
    ) { response in
      response
        .map { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return data
        }
        .call(completion)
    }
  }
  
}

// MARK: - Hit (URL)

extension TKServer {
  
  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    decoderConfig: @escaping (JSONDecoder) -> Void = { _ in },
    completion: @escaping (Int, [String: Any], Result<Model, Error>) -> Void
  ) {
    hit(method: method,
        url: url,
        parameters: parameters,
        headers: headers)
    { response in
      response.map { data in
        guard let data, !data.isEmpty else { throw ServerError.noData }
        let decoder = JSONDecoder()
        decoderConfig(decoder)
        return try decoder.decode(Model.self, from: data)
      }.call(completion)
    }
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    completion: @escaping (Int, [String: Any], Result<Data, Error>) -> Void
  ) {
    hit(method: method,
        url: url,
        parameters: parameters,
        headers: headers)
    { response in
      response
        .map { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return data
        }
        .call(completion)
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
    let data = try dataResult.orThrow(ServerError.noData).get()
    guard !data.isEmpty else { throw ServerError.noData }
    return data
  }

}

// MARK: - Async/await

extension TKServer {
  /// Captures server response with HTTP status code, headers and typed response
  public struct Response<T> {
    
    /// HTTP status code of response. Can be `nil` if request failed.
    public var statusCode: Int?
    
    /// HTTP response headers. Can be empty if request failed.
    public var headers: [String: Any]
    
    /// Typed response, which can encapsulate a failure if the server returned an error
    /// or if the server's data couldn't be decoded as the appropriate type.
    public var result: Result<T, Error>
    
    func call(_ callback: (Int, [String: Any], Result<T, Error>) -> Void) {
      callback(statusCode ?? 0, headers, result)
    }
    
    func map<U>(_ transform: (T) throws -> U) -> Response<U> {
      return .init(
        statusCode: statusCode,
        headers: headers,
        result: Result { try transform(result.get()) }
      )
    }
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async -> Response<Data> {
    await withCheckedContinuation { continuation in
      hit(method: method,
          url: url,
          parameters: parameters,
          headers: headers)
      { response in
        continuation.resume(returning: response.map  { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return data
        })
      }
    }
  }
  
  public func hit(
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil
  ) async -> Response<Data> {
    await withCheckedContinuation { continuation in
      hitSkedGo(
        method: method,
        path: path,
        parameters: parameters,
        headers: headers,
        region: region)
      { response in
        continuation.resume(returning: response.map { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return data
        })
      }
    }
  }

  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    path: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
    region: TKRegion? = nil
  ) async -> Response<Model> {
    await withCheckedContinuation { continuation in
      hitSkedGo(
        method: method,
        path: path,
        parameters: parameters,
        headers: headers,
        region: region,
        callbackOnMain: false
      ) { response in
        continuation.resume(returning: response.map { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return try JSONDecoder().decode(Model.self, from: data)
        })
      }
    }
  }
  
  public func hit<Input: Encodable, Output: Decodable>(
    _ type: Output.Type,
    _ method: HTTPMethod = .POST,
    path: String,
    input: Input,
    headers: [String: String]? = nil,
    region: TKRegion? = nil,
    encoderConfig: (JSONEncoder) -> Void = { _ in },
    decoderConfig: (JSONDecoder) -> Void = { _ in }
  ) async throws -> Response<Output> {
    let encoder = JSONEncoder()
    encoderConfig(encoder)
    let parameters = try encoder.encodeJSONObject(input) as? [String: Any]

    let decoder = JSONDecoder()
    decoderConfig(decoder)

    return await withCheckedContinuation { continuation in
      hitSkedGo(
        method: method,
        path: path,
        parameters: parameters,
        headers: headers,
        region: region,
        callbackOnMain: false
      ) { response in
        continuation.resume(returning: response.map  { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return try decoder.decode(Output.self, from: data)
        })
      }
    }
  }
  
  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async -> Response<Model> {
    await withCheckedContinuation { continuation in
      hit(method: method,
          url: url,
          parameters: parameters,
          headers: headers)
      { response in
        continuation.resume(returning: response.map  { data in
          guard let data, !data.isEmpty else { throw ServerError.noData }
          return try JSONDecoder().decode(Model.self, from: data)
        })
      }
    }
  }
}

// MARK: - Calling to Objective-C

extension TKServer {
  
  private func hitSkedGo(method: HTTPMethod, path: String, parameters: [String: Any]?, headers: [String: String]?, region: TKRegion?, callbackOnMain: Bool = true, completion: @escaping (Response<Data?>) -> Void) {
    
    var adjustedHeaders: [String: String]? = headers
    if let region = region, region != .international {
      var headers = adjustedHeaders ?? [:]
      headers["X-TripGo-Region"] = region.code
      adjustedHeaders = headers
    }
    
    hitSkedGo(
      path: path,
      method: method,
      parameters: parameters,
      headers: adjustedHeaders,
      baseURLs: baseURLs(for: region).shuffled(),
      callbackOnMain: callbackOnMain,
      info: { uuid, info in
        switch info {
        case .request(let request):
          TKLog.log("TKServer", request: request, uuid: uuid)
        case let .response(request, response, .success(data)):
          TKLog.log("TKServer", response: response, data: data, orError: nil, for: request, uuid: uuid)
        case let .response(request, response, .failure(error)):
          TKLog.log("TKServer", response: response, data: nil, orError: error as NSError, for: request, uuid: uuid)
        }
      },
      completion: completion
    )
  }
  
  private func hit(method: HTTPMethod,
                   url: URL,
                   parameters: [String: Any]?,
                   headers: [String: String]? = nil,
                   completion: @escaping (Response<Data?>) -> Void) {
#if DEBUG
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
        return completion(.init(statusCode: 200, headers: [:], result: .success(data)))
      } catch {
        return completion(.init(statusCode: 500, headers: [:], result: .failure(error)))
      }
    }
#endif
    
    hit(
      url,
      method: method,
      parameters: parameters,
      headers: headers,
      info: { uuid, info in
        switch info {
        case .request(let request):
          TKLog.log("TKServer", request: request, uuid: uuid)
        case let .response(request, response, .success(data)):
          TKLog.log("TKServer", response: response, data: data, orError: nil, for: request, uuid: uuid)
        case let .response(request, response, .failure(error)):
          TKLog.log("TKServer", response: response, data: nil, orError: error as NSError, for: request, uuid: uuid)
        }
      },
      completion: completion
    )
  }
  
}

// MARK: - Actual requests

extension TKServer {
  
  enum Info {
    case request(URLRequest)
    case response(URLRequest, URLResponse?, Result<Data?, Error>)
  }
  
  private func hitSkedGo(
    path: String, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?,
    baseURLs: [URL],
    callbackOnMain: Bool,
    info: @escaping ((UUID, Info) -> Void),
    completion: @escaping (Response<Data?>) -> Void,
    previousResponse: Response<Data?>? = nil)
  {
    
    func callback(_ response: Response<Data?>) {
      if callbackOnMain {
        DispatchQueue.main.async {
          completion(response)
        }
      } else {
        completion(response)
      }
    }
    
    guard let baseURL = baseURLs.first else {
      // no more server to try
      if let previousResponse {
        return callback(previousResponse)
      } else {
        assertionFailure("Don't call this without any URLs!")
        return callback(.init(headers: [:], result: .failure(RequestError.noBaseURLs)))
      }
    }

    let request: URLRequest
    do {
      request = try self.request(path: path, baseURL: baseURL, method: method, parameters: parameters, headers: headers)
    } catch {
      return callback(.init(headers: [:], result: .failure(error)))
    }
    
    let onFail = { [weak self] (previously: Response<Data?>) -> Void in
      self?.hitSkedGo(
        path: path, method: method, parameters: parameters, headers: headers,
        baseURLs: Array(baseURLs.dropFirst()),
        callbackOnMain: callbackOnMain, info: info, completion: completion,
        previousResponse: previously
      )
    }
    
    Self.hit(request, info: info) { response in
      switch (response.statusCode ?? 0 >= 500, response.result) {
      case (_, .success):
        // All good, no need for failover
        callback(response)
        
      case (true, _):
        onFail(response)
        
      case (_, .failure(let error)):
        if error is TKUserError {
          callback(response) // servers can't recover from user errors
        } else {
          onFail(response)
        }
      }
    }
    
  }
  
  private func hit(_ url: URL, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?, info: @escaping ((UUID, Info) -> Void), completion: @escaping (Response<Data?>) -> Void) {
    do {
      let request = try request(for: url, method: method, parameters: parameters, headers: headers)
      Self.hit(request, info: info, completion: completion)
    } catch {
      completion(.init(headers: [:], result: .failure(error)))
    }
  }
  
  private static func hit(_ request: URLRequest, info: @escaping ((UUID, Info) -> Void), completion: @escaping (Response<Data?>) -> Void) {
    let uuid = UUID()
    info(uuid, .request(request))
    
    URLSession.shared.dataTask(with: request) { data, response, error in
      let status = (response as? HTTPURLResponse)?.statusCode
      let result: Result<Data?, Error>
      if let error {
        result = .failure(error)
      } else if let status, let parsedError = TKError.error(from: data, statusCode: status) {
        result = .failure(parsedError)
      } else  {
        result = .success(data)
      }
      info(uuid, .response(request, response, result))

      completion(.init(
        statusCode: status,
        headers: ((response as? HTTPURLResponse)?.allHeaderFields as? [String: Any]) ?? [:],
        result: result)
      )
      
    }.resume()
  }
  
}

// MARK: - Building requests

extension TKServer {
  
  private func request(path: String, baseURL: URL, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?) throws -> URLRequest {
    
    switch method {
    case .GET:
      let fullURL = baseURL.appendingPathComponent(path)
      return try request(for: fullURL, method: method, parameters: parameters, headers: headers)
      
    default:
      let fullURL: URL
      if path.contains("?") {
        // Using the diversion over string rather than just calling
        // `URLByAppendingPathComponent` to handle `POST`-paths that
        // include a query-string components
        let urlString = (baseURL.absoluteString as NSString).appendingPathComponent(path)
        fullURL = try URL(string: urlString).orThrow(RequestError.invalidURL)
      } else {
        fullURL = baseURL.appendingPathComponent(path)
      }
      return try request(for: fullURL, method: method, parameters: parameters, headers: headers)
    }
    
  }
  
  private func request(for url: URL, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?) throws -> URLRequest {
    
    var request: URLRequest
    
    if case .GET = method, let parameters, !parameters.isEmpty {
      var components = try URLComponents(url: url, resolvingAgainstBaseURL: false).orThrow(RequestError.invalidURL)
      var queryItems = components.queryItems ?? []
      for parameter in parameters {
        queryItems.add(parameter: parameter.value, key: parameter.key)
      }
      components.queryItems = queryItems
      let merged = try components.url.orThrow(RequestError.invalidURL)
      request = URLRequest(url: merged)
    } else {
      request = URLRequest(url: url)
    }
    
    request.httpMethod = method.rawValue
    
    for defaultHeader in buildSkedGoHeaders() {
      request.addValue(defaultHeader.value, forHTTPHeaderField: defaultHeader.key)
    }
    
    if let provided = headers {
      for header in provided {
        request.addValue(header.value, forHTTPHeaderField: header.key)
      }
    }
    
    if case .GET = method {
      return request
    }
    
    if let parameters {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      
      request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    }
    return request

  }
  
  static func xTripGoVersion() -> String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"].map { "i\($0)" }
  }
  
  private func buildSkedGoHeaders() -> [String: String] {
    guard !apiKey.isEmpty else {
      assertionFailure("API key not specified!")
      return [:]
    }
    
    var headers: [String: String] = [
      "X-TripGo-Key": apiKey,
      "Accept": "application/json" // Force JSON as server otherwise might return XML
    ]
    
    // Optional
    headers["X-TripGo-Version"] = Self.xTripGoVersion()
    headers["userToken"] = userToken
    
    if let customHeaders {
      for header in customHeaders {
        headers[header.key] = header.value
      }
    }
    return headers
  }
  
  func GETRequestWithSkedGoHTTPHeaders(for url: URL, paras: [String: Any]?) throws -> URLRequest {
    try request(for: url, method: .GET, parameters: paras, headers: nil)
  }
  
}

fileprivate extension Array where Element == URLQueryItem {
  mutating func add(parameter: Any, key: String) {
    switch parameter {
    case let array as [Any]:
      for item in array {
        add(parameter: item, key: key)
      }
    default:
      append(.init(name: key, value: "\(parameter)"))
    }
  }
}
