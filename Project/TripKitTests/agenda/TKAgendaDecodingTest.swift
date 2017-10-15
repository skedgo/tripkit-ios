//
//  TKAgendaDecodingTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 15.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import XCTest

@testable import TripKit

@available(iOS 10.0, *)
class TKAgendaDecodingTest: XCTestCase {
  
  func testParsing() throws {
    let result = """
{
  "hashCode":1043320156,
  "inputs":
    {
      "event":{"direct":false,"endTime":"2017-05-30T11:00:00Z","excluded":false,"id":"event","location":{"what3word":"taschen.ehrenvolle.erfinden"},"priority":5,"startTime":"2017-05-30T10:00:00Z","title":"Meeting","type":"event"},
      "event2":{"direct":false,"endTime":"2017-05-30T11:30:00Z","excluded":true,"id":"event2","location":{"what3word":"taschen.ehrenvolle.erfinden"},"priority":5,"startTime":"2017-05-30T10:30:00Z","title":"Excluded Event","type":"event"},
      "home":{"direct":false,"excluded":false,"id":"home","location":{"what3word":"schwärme.glaubt.wirkung"},"type":"home"},
      "work":{"direct":false,"endTime":"2017-05-30T14:30:00Z","excluded":false,"id":"work","location":{"what3word":"eintopf.kleid.flache"},"priority":2,"startTime":"2017-05-30T07:00:00Z","title":"Work","type":"event"}
    },
  "segmentTemplates":[{"action":"Walk<DURATION>","from":{"class":"Location","lat":49.45773,"lng":11.07573,"timezone":"Europe/Berlin"},"hashCode":245935975,"metres":2180,"mini":{"instruction":"Walk","mainValue":"2.2km"},"modeIdentifier":"wa_wal","modeInfo":{"alt":"Walk","color":{"blue":99,"green":199,"red":30},"identifier":"wa_wal","localIcon":"walk"},"notes":"2.2km","streets":[{"encodedWaypoints":"wuzlHgfrbA[RQx@?CCLBDEF?@xn@xjA?MFa@Bu@Aq@A}@E{@Ga@TgALe@?GDQTu@??VZJJN]@GBE@EFBF@?AGcC??e@iB??KY]{@kBuE??Sy@[sBMoAMaB??@?SiCk@iGMkAEg@??SeCA?Qa@Dg@??Ef@"}],"to":{"class":"Location","lat":49.45164,"lng":11.07349,"timezone":"Europe/Berlin"},"travelDirection":232,"type":"unscheduled","visibility":"in summary"},{"action":"Walk<DURATION>","from":{"class":"Location","lat":49.45164,"lng":11.07349,"timezone":"Europe/Berlin"},"hashCode":-64924088,"metres":469,"mini":{"instruction":"Walk","mainValue":"500m"},"modeIdentifier":"wa_wal","modeInfo":{"alt":"Walk","color":{"blue":99,"green":199,"red":30},"identifier":"wa_wal","localIcon":"walk"},"notes":"500m","streets":[{"encodedWaypoints":"uoylHgxqbADg@LhA??RdCDf@LjAj@hGRhCJ`B??wAO??u@Ot@Ne@i@OX"}],"to":{"class":"Location","lat":49.45166,"lng":11.06971,"timezone":"Europe/Berlin"},"travelDirection":259,"type":"unscheduled","visibility":"in summary"},{"action":"Walk<DURATION>","from":{"class":"Location","lat":49.45166,"lng":11.06971,"timezone":"Europe/Berlin"},"hashCode":-1475276416,"metres":393,"mini":{"instruction":"Walk","mainValue":"400m"},"modeIdentifier":"wa_wal","modeInfo":{"alt":"Walk","color":{"blue":99,"green":199,"red":30},"identifier":"wa_wal","localIcon":"walk"},"notes":"400m","streets":[{"encodedWaypoints":"{oylHu`qbANYd@h@`@Rf@eB??@?SiCk@iGMkAEg@??SeCA?Qa@Dg@??Ef@"}],"to":{"class":"Location","lat":49.45164,"lng":11.07349,"timezone":"Europe/Berlin"},"travelDirection":94,"type":"unscheduled","visibility":"in summary"},{"action":"Walk<DURATION>","from":{"class":"Location","lat":49.45164,"lng":11.07349,"timezone":"Europe/Berlin"},"hashCode":-1207527900,"metres":2169,"mini":{"instruction":"Walk","mainValue":"2.2km"},"modeIdentifier":"wa_wal","modeInfo":{"alt":"Walk","color":{"blue":99,"green":199,"red":30},"identifier":"wa_wal","localIcon":"walk"},"notes":"2.2km","streets":[{"encodedWaypoints":"uoylHgxqbADg@LhA??RdCDf@LjAj@hGRhCJ`B??LnA??ZrBRx@??lA|Cz@rB??JXj@nD??@~@GAGCADCDAFELUB??W[?@[dA?FSl@O~@F`@Dz@@|@@p@Ct@G`@?Lyn@yjA???ADGCEBM?BPy@ZS"}],"to":{"class":"Location","lat":49.45773,"lng":11.07573,"timezone":"Europe/Berlin"},"travelDirection":259,"type":"unscheduled","visibility":"in summary"}],
  "track":
    [
      {"class":"event","effectiveEnd":"2017-05-30T08:21:00+02","effectiveStart":"2017-05-28T00:00:00+02","id":"home"},
      {"class":"trip","fromId":"home","groups":[{"trips":[{"arrive":"2017-05-30T08:59:18+02","availability":"AVAILABLE","caloriesCost":93.0,"carbonCost":0.0,"currencySymbol":"€","depart":"2017-05-30T08:21:00+02","hassleCost":0.0,"mainSegmentHashCode":245935975,"moneyCost":0.0,"moneyUSDCost":0.0,"queryIsLeaveAfter":false,"queryTime":"2017-05-30T09:00:00+02","segments":[{"availability":"AVAILABLE","durationString":"39 mins","endTime":"2017-05-30T08:59:18+02","segmentTemplateHashCode":245935975,"startTime":"2017-05-30T08:21:00+02"}],"weightedScore":17.8}]}],"id":"c9fac378-b5af-47bf-a84f-c05dea75f456","toId":"work"},
      {"class":"event","effectiveEnd":"2017-05-30T11:54:00+02","effectiveStart":"2017-05-30T08:59:18+02","id":"work"},
      {"class":"trip","fromId":"work","groups":[{"trips":[{"arrive":"2017-05-30T11:59:51+02","availability":"AVAILABLE","caloriesCost":14.0,"carbonCost":0.0,"currencySymbol":"€","depart":"2017-05-30T11:54:00+02","hassleCost":0.0,"mainSegmentHashCode":-64924088,"moneyCost":0.0,"moneyUSDCost":0.0,"queryIsLeaveAfter":false,"queryTime":"2017-05-30T12:00:00+02","segments":[{"availability":"AVAILABLE","durationString":"6 mins","endTime":"2017-05-30T11:59:51+02","segmentTemplateHashCode":-64924088,"startTime":"2017-05-30T11:54:00+02"}],"weightedScore":2.7}]}],"id":"25639a0a-9a6e-45da-88f9-24f28c260f99","toId":"event"},
      {"class":"event","effectiveEnd":"2017-05-30T13:00:00+02","effectiveStart":"2017-05-30T11:59:51+02","id":"event"},
      {"class":"event","id":"event2"},
      {"class":"trip","fromId":"event","groups":[{"trips":[{"arrive":"2017-05-30T13:05:51+02","availability":"AVAILABLE","caloriesCost":14.0,"carbonCost":0.0,"currencySymbol":"€","depart":"2017-05-30T13:00:00+02","hassleCost":0.0,"mainSegmentHashCode":-1475276416,"moneyCost":0.0,"moneyUSDCost":0.0,"queryIsLeaveAfter":true,"queryTime":"2017-05-30T13:00:00+02","segments":[{"availability":"AVAILABLE","durationString":"6 mins","endTime":"2017-05-30T13:05:51+02","segmentTemplateHashCode":-1475276416,"startTime":"2017-05-30T13:00:00+02"}],"weightedScore":2.7}]}],"id":"ab204775-85ac-4446-b14b-a0d2c5354fe3","toId":"work"},
      {"class":"event","effectiveEnd":"2017-05-30T16:30:00+02","effectiveStart":"2017-05-30T13:05:51+02","id":"work"},
      {"class":"trip","fromId":"work","groups":[{"trips":[{"arrive":"2017-05-30T17:08:25+02","availability":"AVAILABLE","caloriesCost":93.0,"carbonCost":0.0,"currencySymbol":"€","depart":"2017-05-30T16:30:00+02","hassleCost":0.0,"mainSegmentHashCode":-1207527900,"moneyCost":0.0,"moneyUSDCost":0.0,"queryIsLeaveAfter":true,"queryTime":"2017-05-30T16:30:00+02","segments":[{"availability":"AVAILABLE","durationString":"39 mins","endTime":"2017-05-30T17:08:25+02","segmentTemplateHashCode":-1207527900,"startTime":"2017-05-30T16:30:00+02"}],"weightedScore":17.9}]}],"id":"1348b5ab-821c-47e0-beda-3dc5abd22576","toId":"home"},
      {"class":"event","effectiveEnd":"2017-06-02T00:00:00+02","effectiveStart":"2017-05-30T17:08:25+02","id":"home"}]}
"""

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let output = try decoder.decode(TKAgendaOutput.self, from: result.data(using: .utf16)!)
    
    XCTAssertEqual(output.hashCode, 1043320156)
    XCTAssertEqual(output.track.count, 10)
    XCTAssertEqual(output.inputs.count, 4)
  }
  
}
