//
//  TKShareURLProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//
//

import Foundation

#if TK_NO_MODULE
#else
  import TripKit
#endif


@objc
public protocol TKURLShareable {
  var shareURL: URL? { get }
}

@objc
public protocol TKURLSavable: class, TKURLShareable {
  var shareURL: URL? { get set }
  var saveURL: URL? { get }
}

#if os(iOS)
  
  public class TKShareURLProvider: UIActivityItemProvider {
    
    @objc(getShareURLForShareable:allowLongURL:success:failure:)
    public class func getShareURL(for shareable: TKURLShareable, allowLongURL: Bool, success: @escaping (URL) -> Void, failure: (() -> Void)?) {
      
      if let shareURL = shareable.shareURL {
        success(shareURL)
        return
      }
      
      guard
        let saveable = shareable as? TKURLSavable,
        let baseSaveURL = saveable.saveURL
      else {
        failure?()
        return
      }

      let saveURL = self.saveURL(forBase: baseSaveURL, allowLongURL: allowLongURL)
      
      SVKServer.get(saveURL, paras: nil) { _, response, _, _ in
        guard
          let dict = response as? [String: Any],
          let urlString = dict["url"] as? String,
          let shareURL = URL(string: urlString)
        else {
          failure?()
          return
        }
        
        saveable.shareURL = shareURL
        success(shareURL)
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
    @objc(getShareURLForShareable:allowLongURL:allowBlocking:)
    @discardableResult
    public class func getShareURL(for shareable: TKURLShareable, allowLongURL: Bool, allowBlocking: Bool) -> URL? {
      
      if let shareURL = shareable.shareURL {
        return shareURL
      }

      guard
        allowBlocking,
        let saveable = shareable as? TKURLSavable,
        let baseSaveURL = saveable.saveURL
      else {
        return nil
      }

      let saveURL = self.saveURL(forBase: baseSaveURL, allowLongURL: allowLongURL)
      let response = SVKServer.syncURL(saveURL, timeout: 10)
      
      if let dict = response as? [String: Any],
        let urlString = dict["url"] as? String,
        let shareURL = URL(string: urlString) {
        saveable.shareURL = shareURL
        return shareURL
      } else {
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
  //    if ([[self activityType] rangeOfString:@"kSGAction"].location != NSNotFound)
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

