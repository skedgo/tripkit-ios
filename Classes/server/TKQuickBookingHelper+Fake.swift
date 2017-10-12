//
//  TKQuickBookingHelper+Fake.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/12/16.
//
//

import Foundation

extension TKBooking.Confirmation {
  static func fakeTNC() -> TKBooking.Confirmation {
    let fake = """
    {
      "actions": [
        {
          "externalURL": "tel:(555)555-5555",
          "isDestructive": false,
          "title": "Call driver"
        },
        {
          "internalURL": "http://deep-thought:8080/satapp-debug/booking/v1/1204f411-eacb-406c-8fd2-3775c8242b02/cancel?bsb=1",
          "isDestructive": true,
          "title": "Cancel ride"
        }
      ],
      "provider": {
        "imageURL": "https://d1a3f4spazzrp4.cloudfront.net/uberex-sandbox/images/driver.jpg",
        "subtitle": "4.9",
        "title": "John"
      },
      "status": {
        "title": "Approaching",
        "subtitle": "Your driver is approaching"
      },
      "vehicle": {
        "imageURL": "https://d1a3f4spazzrp4.cloudfront.net/uberex-sandbox/images/prius.jpg",
        "subtitle": "UBER-PLATE",
        "title": "Prius Toyota"
      },
      "purchase": {
        "price": 15.80,
        "currency": "AUD",
        "productName": "uberX",
        "productType": "ps_tnc",
        "id": "1204f411-eacb-406c-8fd2-3775c8242b02",
      }
    }
    """
    return try! JSONDecoder().decode(TKBooking.Confirmation.self, from: fake.data(using: .utf8)!)
  }
  
  static func fakePublic() -> TKBooking.Confirmation {
    let fake = """
    {
      "actions": [
        {
          "externalURL": "qrcode:http://www.skedgo.com",
          "isDestructive": false,
          "title": "View ticket"
        },
      ],
      "status": {
        "title": "30 Minute Ticket",
        "subtitle": "Valid until 15:30",
      },
    }
    """
    return try! JSONDecoder().decode(TKBooking.Confirmation.self, from: fake.data(using: .utf8)!)
  }
}
