//
//  TKLog.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.02.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import os.log

/// A `TKLogger` is used by `TKLog` to perform the outputting and processing of log statements.
///
/// A default `TKConsoleLogger` is provided.
public protocol TKLogger {
  /// The log level of the logger. Used by `TKLog` to decide whether to sent events to this logger.
  var level: TKLog.LogLevel { get }
  
  /// Called by `TKLog` when an event should be logged.
  ///
  /// - Parameters:
  ///   - level: The log level of the event.
  ///   - identifier: An identifier for who is logging this, typically a class name.
  ///   - message: The log message
  func output(_ level: TKLog.LogLevel, identifier: String, message: String)
  
  /// Called by `TKLog` with requests, typically maded by `TKServer`
  ///
  /// This is optional. By default `output` will be called if `level` is less or equal `.info`
  ///
  /// - Parameters:
  ///   - identifier: An identifier for who is logging this, typically a class name.
  ///   - request: The request that was made
  func log(identifier: String, request: TKLog.ServerRequest)
  
  /// Called by `TKLog` when server response was received, typically initiated by `TKServer`
  ///
  /// This is optional. By default `output` will be called if `level` is less or equal `.info`
  ///
  /// - Parameters:
  ///   - identifier: An identifier for who is logging this, typically a class name.
  ///   - response: The response that was received (or error information, if no response received)
  func log(identifier: String, response: TKLog.ServerResponse)
}

public extension TKLogger {
  func log(_ level: TKLog.LogLevel, identifier: String, message: String) {
    guard level.rawValue >= self.level.rawValue else { return }
    output(level, identifier: identifier, message: message)
  }

  func log(identifier: String, request: TKLog.ServerRequest) {
    guard level.rawValue <= TKLog.LogLevel.info.rawValue else { return }
    
    guard let method = request.request.httpMethod, let url = request.request.url else { return }

    let message: String
    if level.rawValue == TKLog.LogLevel.verbose.rawValue {
      message = TKLog.formatForVCCode(request: request)
    } else {
      message = "➡️ \(method) \(url.absoluteString)"
    }
    output(.info, identifier: identifier, message: message)
  }
  
  func log(identifier: String, response: TKLog.ServerResponse) {
    guard level.rawValue <= TKLog.LogLevel.info.rawValue else { return }

    guard let method = response.request.request.httpMethod, let url = response.request.request.url else { return }
    
    let message: String
    switch response.result {
    case .failure:
      message = "❌ \(method) \(url.absoluteString)"
    case let .success((urlResponse, data)):
      message = TKLog.format(response: urlResponse, data: data, for: response.request, detailed: level.rawValue == TKLog.LogLevel.verbose.rawValue)
    }
    
    output(.info, identifier: identifier, message: message)
  }
}

/// A logger that outputs to the debugging console and the device's console (via `os_log`)
public class TKConsoleLogger: TKLogger {
  
  public let level: TKLog.LogLevel
  public let subsystem: String

  public init(level: TKLog.LogLevel, subsystem: String? = nil ) {
    self.level = level
    self.subsystem = subsystem
      ?? Bundle.main.bundleIdentifier
      ?? "com.skedgo.TripKit"
  }

  public func output(_ level: TKLog.LogLevel, identifier: String, message: String) {
    let smartIdentifier: String
    if (identifier as NSString).lastPathComponent.count > 0 {
      smartIdentifier = (identifier as NSString).lastPathComponent
    } else {
      smartIdentifier = identifier
    }
    let shortIdentifier = smartIdentifier.prefix(10).padding(toLength: 10, withPad: " ", startingAt: 0)
    let message = "\(level.prefix) \(message)"
    let log = OSLog(subsystem: subsystem, category: shortIdentifier)
    os_log("%@", log: log, type: level.toOSLog, message)
  }
}

/// The main class to log something from TripKit. The actual logging is done by the `TKLogger` instances
/// set on the `.logger` property.
@objc
public class TKLog : NSObject {
  
  private override init() {
    super.init()
  }
  
  public enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warning
    case error

    var prefix: String {
      switch self {
      case .verbose:  return "   [VER]"
      case .debug:    return "   [DEB]"
      case .info:     return "   [INF]"
      case .warning:  return "⚠️ [WAR]"
      case .error:    return "💥 [ERR]"
      }
    }
  }
  
  /// The loggers which do the actual logging work. By default this is empty, unless TripKit is compiled with
  /// a `BETA` or `DEBUG` Swift flag, then it's a `TKConsoleLogger` with a log level of "warning".
  public static var loggers: [TKLogger] = {
    #if BETA || DEBUG
    return [TKConsoleLogger(level: .warning)]
    #else
    return []
    #endif
  }()
  
  @objc(info:block:)
  public class func info(_ identifier: String, text: @autoclosure () -> String) {
    log(identifier, level: .info, block: text)
  }
  
  public class func info(identifier: String? = nil, _ message: @autoclosure () -> String, file: StaticString = #filePath) {
    log(identifier ?? file.description, level: .info, block: message)
  }
  
  @objc(debug:block:)
  public class func debug(_ identifier: String, text: @autoclosure () -> String) {
    log(identifier, level: .debug, block: text)
  }

  public class func debug(identifier: String? = nil, _ message: @autoclosure () -> String, file: StaticString = #filePath) {
    log(identifier ?? file.description, level: .debug, block: message)
  }

  @objc(verbose:block:)
  public class func verbose(_ identifier: String, text: @autoclosure () -> String) {
    log(identifier, level: .verbose, block: text)
  }

  public class func verbose(identifier: String? = nil, _ message: @autoclosure () -> String, file: StaticString = #filePath) {
    log(identifier ?? file.description, level: .verbose, block: message)
  }
  
  @objc
  public class func error(_ identifier: String, text message: String) {
    log(identifier, level: .error) { message }
  }
  
  public class func error(identifier: String? = nil, _ message: @autoclosure () -> String, file: StaticString = #filePath) {
    log(identifier ?? file.description, level: .error, block: message)
  }
  
  @objc(warn:text:)
  public class func warn(_ identifier: String, text message: String) {
    log(identifier, level: .warning) { message }
  }
  
  public class func warn(identifier: String? = nil, _ message: @autoclosure () -> String, file: StaticString = #filePath) {
    log(identifier ?? file.description, level: .warning, block: message)
  }
  
  @objc(info:text:)
  public class func _info(_ identifier: String, text message: String) {
    log(identifier, level: .info) { message }
  }
  
  @objc(debug:text:)
  public class func _debug(_ identifier: String, text message: String) {
    log(identifier, level: .debug) { message }
  }
  
  @objc(verbose:text:)
  public class func _verbose(_ identifier: String, text message: String) {
    log(identifier, level: .verbose) { message }
  }
  
  private class func log(_ identifier: String, level: LogLevel, block: () -> String) {
    #if BETA || DEBUG
    guard !loggers.isEmpty else { return }
    let message = block()
    loggers.forEach { $0.log(level, identifier: identifier, message: message) }
    #endif
  }
}

extension TKLog.LogLevel {
  
  var toOSLog: OSLogType {
    switch self {      
    case .debug, .verbose: return .debug
    case .info: return .info
    case .warning: return .default
    case .error: return .error
    }
  }
  
}

// MARK: - Server requests

extension TKLog {
  
  public typealias ServerResult = Result<(URLResponse, Data?), Error>
  
  /// The URL request along with a UUID to identify each request sent
  public struct ServerRequest: Hashable {
    public let request: URLRequest
    public let id: String

    public static func == (lhs: TKLog.ServerRequest, rhs: TKLog.ServerRequest) -> Bool {
      return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }
  
  /// A response to a `ServerRequest`
  public struct ServerResponse: Hashable {
    public let request: ServerRequest
    public let result: ServerResult
    
    public static func == (lhs: TKLog.ServerResponse, rhs: TKLog.ServerResponse) -> Bool {
      guard lhs.request == rhs.request else { return false }
      switch (lhs.result, rhs.result) {
      case (.success(let left), .success(let right)):
        return left == right
      case (.failure(let left), .failure(let right)):
        return left as NSError === right as NSError
      default:
        return false
      }
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(request)
      switch result {
      case let .success((response, data)):
        hasher.combine(response)
        hasher.combine(data)
      case let .failure(error):
        hasher.combine(error as NSError)
      }
    }
  }

  /// :nodoc: - Public for building CocoaPods-style
  @objc(log:request:UUID:)
  public class func log(_ identifier: String, request: URLRequest, uuid: UUID) {
    #if BETA || DEBUG || targetEnvironment(macCatalyst)
    guard !loggers.isEmpty else { return }

    let serverRequest = ServerRequest(request: request, id: uuid.uuidString)
    loggers.forEach { $0.log(identifier: identifier, request: serverRequest) }
    #endif
  }

  /// :nodoc: - Public for building CocoaPods-style
  @objc(log:response:data:orError:forRequest:UUID:)
  public class func log(_ identifier: String, response: URLResponse?, data: Data?, orError error: Error?, for request: URLRequest, uuid: UUID) {
    #if BETA || DEBUG || targetEnvironment(macCatalyst)
    guard !loggers.isEmpty else { return }

    let serverRequest = ServerRequest(request: request, id: uuid.uuidString)
    let serverResponse: ServerResponse
    if let response = response {
      serverResponse = ServerResponse(request: serverRequest, result: .success((response, data)))
    } else if let error = error {
      serverResponse = ServerResponse(request: serverRequest, result: .failure(error))
    } else {
      return assertionFailure()
    }
    
    loggers.forEach { $0.log(identifier: identifier, response: serverResponse) }
    #endif
  }

}

// MARK: - Formatting helpers

extension TKLog {

  public class func formatForVCCode(request: TKLog.ServerRequest) -> String {
    let urlRequest = request.request
    guard let method = urlRequest.httpMethod, let url = urlRequest.url else { return "[bad request]" }
    
    var message = "\(method) \(url.absoluteString)"
    if let headers = urlRequest.allHTTPHeaderFields {
      for header in headers {
        #if DEBUG
        message += "\n\(header.key): \(header.value)"
        #else
        if header.key.lowercased() == "x-tripgo-key" {
          message += "\n\(header.key): \(header.value.obscured)"
        } else {
          message += "\n\(header.key): \(header.value)"
        }
        #endif
      }
    }
    if let body = urlRequest.httpBody, !body.isEmpty {
      message += "\n\n\t" + String(decoding: body, as: UTF8.self)
    }
    return message
  }
  
  public class func format(response: URLResponse, data: Data?, for request: TKLog.ServerRequest, detailed: Bool) -> String {

    let urlRequest = request.request
    guard
      let httpResponse = response as? HTTPURLResponse,
      let method = urlRequest.httpMethod,
      let url = urlRequest.url else { return "[bad request]" }
    
    func emoji(status: Int) -> String {
      switch status {
      case 200..<400: return "✅"
      default:        return "❌"
      }
    }
    
    var message = "\(emoji(status: httpResponse.statusCode)) \(httpResponse.statusCode): \(method) \(url.absoluteString)"
    guard detailed else { return message }
    
    for header in httpResponse.allHeaderFields {
      message += "\n\(header.key): \(header.value)"
    }

    if let data = data, !data.isEmpty {
      message += "\n\n\t" + String(decoding: data, as: UTF8.self)
    }
    return message
  }
}

fileprivate extension String {
  var obscured: String {
    String(prefix(6)).appending("...").appending(String(suffix(2)))
  }
}
