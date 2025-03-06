//
//  TKContactsManager.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import Contacts

public class TKContactsManager: NSObject, TKPermissionManager {
  
  public enum AddressKind {
    case home
    case work
    
    public init?(label: String?) {
      switch label {
      case CNLabelHome: self = .home
      case CNLabelWork: self = .work
      default: return nil
      }
    }
  }
  
  public struct ContactAddress: Hashable {
    public let name: String
    public let image: TKImage?
    public let kind: AddressKind?
    public let address: String
    public let postalAddress: CNPostalAddress
    
    func matches(_ kind: AddressKind?) -> Bool {
      return kind == nil || self.kind == kind
    }
    
    var locationName: String {
      switch kind {
      case nil: return Loc.PersonsPlace(name: name)
      case .home?: return Loc.PersonsHome(name: name)
      case .work?: return Loc.PersonsWork(name: name)
      }
    }
  }
  
  @objc(sharedInstance)
  public static let shared = TKContactsManager()
  
  public var openSettingsHandler: (() -> Void)? = nil
  
  let queue: DispatchQueue
  
  private let store: CNContactStore
  private static let keysToFetch: [CNKeyDescriptor] = [
    CNContactGivenNameKey as CNKeyDescriptor,
    CNContactPostalAddressesKey as CNKeyDescriptor,
    CNContactThumbnailImageDataKey as CNKeyDescriptor
  ]
  
  private override init() {
    self.queue = DispatchQueue(label: "com.skedgo.tripkit.contacts", qos: .userInitiated)
    self.store = CNContactStore()
    
    super.init()
  }
  
  public func fetchContacts(searchString: String, kind: AddressKind? = nil) throws -> [ContactAddress] {
    assert(!Thread.isMainThread, "Don't call this on the main thread. It's slow.")
    
    guard isAuthorized else { return [] }
    
    let predicate = CNContact.predicateForContacts(matchingName: searchString)
    let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: TKContactsManager.keysToFetch)
    
    return contacts.flatMap { $0.toContactAddresses() }.filter { $0.matches(kind) }
  }
  
  public func fetchMyLocations(limitTo kind: AddressKind? = nil) throws -> [ContactAddress] {
    assert(!Thread.isMainThread, "Don't call this on the main thread. It's slow.")
    
    guard isAuthorized else { return [] }
    
#if os(macOS)
    let contact = try store.unifiedMeContactWithKeys(toFetch: TKContactsManager.keysToFetch)
    return contact.toContactAddresses().filter { $0.matches(kind) }
#else
    return [] // not yet supported
#endif
  }
  
  // MARK: - TKPermissionManager
  
  public func askForPermission(_ completion: @escaping (Bool) -> Void) {
    store.requestAccess(for: .contacts) { granted, _ in
      completion(granted)
    }
  }
  
  public var authorizationStatus: TKAuthorizationStatus {
    switch CNContactStore.authorizationStatus(for: .contacts) {
    case .authorized: return .authorized
#if compiler(>=6.0) // Only Xcode 16.0+ is aware of this
    case .limited: return .authorized
#endif
    case .denied: return .denied
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    @unknown default:
      assertionFailure("Unhandled status")
      return .denied
    }
  }
  
  public var authorizationAlertText: String {
    return Loc.ContactsAuthorizationAlertText
  }
}

// MARK: - Helpers

extension CNContact {
  fileprivate func toContactAddresses() -> [TKContactsManager.ContactAddress] {
    
    // WARNING: Whatever we access here, needs to match `keysToFetch` otherwise
    // exceptions fire.
    
    let image = circularThumbnail()
    return postalAddresses.map {
      let singleLine = TKAddressFormatter.singleLineAddress(for: $0.value)
      return TKContactsManager.ContactAddress(name: givenName, image: image, kind: TKContactsManager.AddressKind(label: $0.label), address: singleLine, postalAddress: $0.value)
    }
  }
  
  fileprivate func circularThumbnail() -> TKImage? {
#if canImport(UIKit)
    guard let data = thumbnailImageData, let thumbnail = TKImage(data: data) else { return nil }
    return TKImageBuilder.drawCircularImage(insideImage: thumbnail)

#else
    return nil
#endif
  }
}
