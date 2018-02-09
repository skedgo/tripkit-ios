//
//  TKLinkedAccountTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 11.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitBookings

class TKLinkedAccountTest: XCTestCase {
    
  func testParsingLinkedAccounts() throws {
    let json = """
      [
        {
          "action": "signin",
          "provider": "tnc1",
          "status": "Account not connected",
          "actionTitle": "Link account",
          "url": "https://api.tripgo.com/connect",
          "modeIdentifier": "ps_tnc_TNC1",
          "companyInfo": {
            "name": "TNC 1"
          }
        },
        {
          "action": "logout",
          "provider": "tnc2",
          "status": "Account connected",
          "actionTitle": "Unlink account",
          "url": "https://api.tripgo.com/connect",
          "modeIdentifier": "ps_tnc_TNC2",
          "companyInfo": {
            "name": "TNC 2"
          }
        }
      ]
    """
    
    let auth = try! JSONDecoder().decode([ProviderAuth].self, from: json.data(using: .utf8)!)
    XCTAssertEqual(auth.count, 2)
    
    if case .notConnected = auth[0].status {
      XCTAssert(!auth[0].isConnected)
    } else {
      XCTFail()
    }

    if case .connected = auth[1].status {
      XCTAssert(auth[1].isConnected)
    } else {
      XCTFail()
    }
  }
  
}
