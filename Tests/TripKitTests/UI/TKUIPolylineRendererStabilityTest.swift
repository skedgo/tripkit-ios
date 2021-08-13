//
//  TKUIPolylineRendererStabilityTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 21.06.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

class TKUIPolylineRendererStabilityTest: XCTestCase {

  var threads = 12
  var renderers = 10
  var polyline: MKPolyline!
  
  func testSimpleMultiThreading() throws {
    let group = DispatchGroup()
    
    (1...threads).forEach { round in
      group.enter()

      DispatchQueue(label: "com.skedgo.tripkit.polyline-test.\(round)", qos: .default).async {
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let _ = imageRenderer.image { context in

          (1...self.renderers).forEach { _ in
            let renderer = TKUIPolylineRenderer(polyline: self.polyline)
            renderer.draw(.world, zoomScale: 1, in: context.cgContext)
          }
        
        }
//        print("Finished image in \(round)...")
        group.leave()
      }
    }
    
    group.wait()
    XCTAssert(true)
  }
  
  func testMultipleDrawingsInMultiThreading() throws {
    let group = DispatchGroup()
    
    (1...threads).forEach { round in
      group.enter()
      
      DispatchQueue(label: "com.skedgo.tripkit.polyline-test.\(round)", qos: .default).async {
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let _ = imageRenderer.image { context in
          
          (1...self.renderers).forEach { _ in
            let renderer = TKUIPolylineRenderer(polyline: self.polyline)
            renderer.draw(.world, zoomScale: 1, in: context.cgContext)
            renderer.draw(.world, zoomScale: 1, in: context.cgContext)
            renderer.draw(.world, zoomScale: 1, in: context.cgContext)
          }
          
        }
        //        print("Finished image in \(round)...")
        group.leave()
      }
    }
    
    group.wait()
    XCTAssert(true)
  }

  func testSelectionMultiThreading() throws {
    let group = DispatchGroup()
    
    (1...threads).forEach { round in
      group.enter()
      
      DispatchQueue(label: "com.skedgo.tripkit.polyline-test.\(round)", qos: .default).async {
        let renderers = (1...self.renderers).map { _ -> TKUIPolylineRenderer in
          let renderer = TKUIPolylineRenderer(polyline: self.polyline)
          renderer.selectionIdentifier = "\(round)"
          renderer.selectionHandler = { Int($0) == 2 }
          return renderer
        }

        // draw initial selection...
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let _ = imageRenderer.image { context in
          renderers.forEach { $0.draw(.world, zoomScale: 1, in: context.cgContext) }
        }
        
        // ... then update
        let imageRenderer2 = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let _ = imageRenderer2.image { context in
          renderers.forEach { $0.selectionHandler = { Int($0)?.isMultiple(of: 2) == true } }
          renderers.forEach { $0.draw(.world, zoomScale: 1, in: context.cgContext) }

        }

        group.leave()
      }
    }
    
    group.wait()
    XCTAssert(true)
  }

  
  override func setUp() {
    super.setUp()
    
    let ferryPath = "~ppmEwd`z[Le@r@c@vEmEn@}@t@o@nAw@??AJ??x@n@n@V|@FfCIf@Mf@Wd@]rBeB^UZOpCiArCcAdBg@N@nAZTJn@l@Zp@R`ABx@Eh@Mn@cAlBmA|A{@z@o@d@Mh@??GK??Sd@Qt@Er@DjA\\~AfArCnBdDxCnEvBvCrGvHtEhGjCrEj@|AP~@VjCn@d]V`D`@nBf@~Ah@r@lA~@bAb@fCj@tCZ`W|A"
    let ferryCoordinates = CLLocationCoordinate2D.decodePolyline(ferryPath)
    
    polyline = MKPolyline(coordinates: ferryCoordinates, count: ferryCoordinates.count)
  }
  
}
