//
//  TKReporter+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22/9/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension TKReporter: @retroactive ReactiveCompatible {}
extension Reactive where Base == TKReporter {
  public static func reportPlannedTrip(_ trip: Trip, userInfo: [String: Any] = [:], includeUserID: Bool = false) -> Single<Bool> {
    return Single.create { observer in
      let token = Token()
      TKReporter.reportPlannedTrip(trip, userInfo: userInfo, includeUserID: includeUserID) {
        token.isCurrent
      } completion: {
        observer(.success($0))
      }
      return Disposables.create {
        token.isCurrent = false
      }
    }
  }
}

fileprivate class Token {
  var isCurrent: Bool = true
}
