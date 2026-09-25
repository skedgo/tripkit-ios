//
//  TKUIServiceMapManagerTest.swift
//  TripKitUITests
//
//  Created by Adrian Schönig on 18/9/26.
//

import XCTest
import MapKit

@testable import TripKit
@testable import TripKitUI

class TKUIServiceMapManagerTest: TKTestCase {

  /// Captured from api.tripgo.com on 2026-09-18 (Luciq #69): bus 161 is timetabled to leave
  /// Stuart St opp Cove Ave at 08:45 but runs 4 minutes late. The service card showed 08:49
  /// while the embarkation semaphore on the map kept the 08:45 it was first drawn with.
  @MainActor
  func testEmbarkationSemaphoreFollowsRealTime() throws {
    let service = Service(context: tripKitContext)
    service.code = "2146945"
    let serviceResponse = try JSONDecoder().decode(TKAPI.ServiceResponse.self, from: dataFromJSON(named: "service-late-bus"))
    XCTAssertTrue(TKBuzzInfoProvider.addContent(from: serviceResponse, to: service))

    let embarkation = try XCTUnwrap(service.visits?.first { $0.stop.stopCode == "209592" })
    XCTAssertEqual(embarkation.departure, Date(timeIntervalSince1970: 1_789_685_100))

    let viewModel = TKUIServiceViewModel(dataInput: .visits(embarkation: embarkation))
    viewModel.mapContent = TKUIServiceViewModel.buildMapContent(for: embarkation, disembarkation: nil)

    let mapView = MKMapView()
    let mapManager = TKUIServiceMapManager()
    mapManager.viewModel = viewModel
    mapManager.takeCharge(of: mapView, animated: false)

    let semaphore = try XCTUnwrap(viewModel.mapContent?.embarkation)
    let semaphoreView = try XCTUnwrap(TKUIAnnotationViewBuilder(for: semaphore, in: mapView).build() as? TKUISemaphoreView)
    XCTAssertEqual(semaphoreView.timeText, TKStyleManager.timeString(Date(timeIntervalSince1970: 1_789_685_100), for: embarkation.timeZone))

    // What the service card's real-time loop does
    let latestResponse = try JSONDecoder().decode(TKAPI.LatestResponse.self, from: dataFromJSON(named: "latest-late-bus"))
    var updateables = TKRealTimeFetcher.Updateables()
    updateables.add([:], for: service, updating: .service(service))
    TKRealTimeFetcher.update(updateables: updateables, from: latestResponse)
    viewModel.realTimeUpdate = .updated(())

    XCTAssertEqual(embarkation.departure, Date(timeIntervalSince1970: 1_789_685_357))
    XCTAssertEqual(semaphoreView.timeText, TKStyleManager.timeString(Date(timeIntervalSince1970: 1_789_685_357), for: embarkation.timeZone))
  }

}

private extension UIView {
  var timeText: String? {
    for subview in subviews {
      if let label = subview as? UILabel {
        return label.text
      } else if let text = subview.timeText {
        return text
      }
    }
    return nil
  }
}
