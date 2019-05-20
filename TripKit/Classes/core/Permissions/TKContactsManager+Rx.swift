//
//  TKContactsManager+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import Contacts

import RxSwift

@available(iOS 9.0, *)
extension Reactive where Base == TKContactsManager {
  
  public func fetchContacts(searchString: String, kind: TKContactsManager.AddressKind? = nil) -> Single<[TKContactsManager.ContactAddress]> {
    
    return Single.create { [unowned base] subscriber in
      base.queue.async {
        do {
          let contacts = try base.fetchContacts(searchString: searchString, kind: kind)
          subscriber(.success(contacts))
        } catch {
          subscriber(.error(error))
        }
      }
      return Disposables.create()
    }
  }
  
}
