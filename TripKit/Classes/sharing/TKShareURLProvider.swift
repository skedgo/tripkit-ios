//
//  TKShareURLProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//
//

import Foundation

public protocol TKURLShareable {
  var shareURL: URL? { get }
}

public protocol TKURLSavable: TKURLShareable {
  var shareURL: URL? { get set }
  var saveURL: URL? { get }
}

extension TKAPI {
  struct SaveTripResponse: Codable {
    let url: URL
  }
}

#if os(iOS)

public class TKShareURLProvider: UIActivityItemProvider {
  
  public enum ShareError: Error {
    case missingSaveURL
  }
  
  public class func getShareURL(for shareable: TKURLShareable, allowLongURL: Bool, completion: @escaping (Result<URL, Error>) -> Void) {
    
    if let shareURL = shareable.shareURL {
      return completion(.success(shareURL))
    }
    
    guard
      var saveable = shareable as? TKURLSavable,
      let baseSaveURL = saveable.saveURL
    else {
      return completion(.failure(ShareError.missingSaveURL))
    }

    let saveURL = self.saveURL(forBase: baseSaveURL, allowLongURL: allowLongURL)
    
    TKServer.hit(TKAPI.SaveTripResponse.self, url: saveURL) { _, _, response in
      do {
        let url = try response.get().url
        saveable.shareURL = url
        completion(.success(url))
      } catch {
        completion(.failure(error))
      }
    }
    
  }
  
  /// Gets and optionally fetches the share URL for the provided object.
  ///
  /// If the object didn't yet have a share URL, it is fetched and the object
  /// conforms to `TKURLSavable`, the URL is also persisted in the object's `shareURL`.
  ///
  /// - Parameters:
  ///   - shareable: Object for which to get a URL for sharing
  ///   - allowLongURL: If long URL is allowed (e.g., long UUID rather than a short identifier)
  ///   - allowBlocking: If method call is allowed to block and fetch the URL from a server
  /// - Returns: The URL for sharing. Is discardable as for `TKURLSavable` you can get it from the object's `shareURL`
  @discardableResult
  public class func getShareURL(for shareable: TKURLShareable, allowLongURL: Bool, allowBlocking: Bool) -> URL? {
    
    if let shareURL = shareable.shareURL {
      return shareURL
    }

    guard
      allowBlocking,
      var saveable = shareable as? TKURLSavable,
      let baseSaveURL = saveable.saveURL
    else {
      return nil
    }

    let saveURL = self.saveURL(forBase: baseSaveURL, allowLongURL: allowLongURL)
    do {
      let data = try TKServer.hitSync(url: saveURL, timeout: .seconds(10))
      let url = try JSONDecoder().decode(TKAPI.SaveTripResponse.self, from: data).url
      saveable.shareURL = url
      return url
    } catch {
      return nil
    }
  }
  
  private class func saveURL(forBase url: URL, allowLongURL: Bool) -> URL {
    guard allowLongURL else { return url }
    
    var absolute = url.absoluteString
    if absolute.contains("?") {
      absolute.append("&long=1")
    } else {
      absolute.append("?long=1")
    }
    return URL(string: absolute)!
  }
  
  
  // MARK: - UIActivityItemProvider
  
  public override var item: Any {
//    if ([[self activityType] rangeOfString:@"kTKAction"].location != NSNotFound)
//    return nil; // don't do this for app action activities

    if let shareable = placeholderItem as? TKURLShareable, let url = TKShareURLProvider.getShareURL(for: shareable, allowLongURL: false, allowBlocking: true) {
      return url
    } else {
      return URL(string: "https://tripgo.com")!
    }
    
  }
  
  public override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    return URL(string: "https://tripgo.com")!
  }
}

#endif
